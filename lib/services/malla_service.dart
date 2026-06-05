// lib/services/malla_service.dart
// Catálogo de la malla + cálculo de estados por alumno.

import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../models/malla_models.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'enrollment_service.dart';

class MallaService extends GetxService {
  static MallaService get to => Get.find();

  /// Retrocompatibilidad con nombres legacy almacenados en users.json antes
  /// del Plan 2026. Los nombres nuevos (valores) coinciden exactamente con
  /// los diplomas oficiales y con el campo `specialties` del JSON de la malla.
  static const Map<String, String> _especialidadAliases = {
    'Desarrollo de Software': 'Ingeniería de Software',
    'Ciberseguridad': 'Tecnologías de la Información',
    'Ciencia de Datos': 'Sistemas de Información',
    'TI': 'Tecnologías de la Información',
    // Nombres actuales incluidos como identidad para no romper normalizeSpecialty.
    'Ingeniería de Software': 'Ingeniería de Software',
    'Sistemas de Información': 'Sistemas de Información',
    'Tecnologías de la Información': 'Tecnologías de la Información',
    'Desarrollo de Videojuegos': 'Desarrollo de Videojuegos',
  };

  final RxList<CourseNode> _courses = <CourseNode>[].obs;
  Set<String> _currentCourseIds = {};

  List<CourseNode> get courses => _courses;

  /// Carga el catálogo desde assets/data/malla_sistemas.json (idempotente).
  Future<void> load() async {
    if (_courses.isNotEmpty) return;

    final coursesData =
        (jsonDecode(await rootBundle.loadString('assets/data/courses.json'))
                as List)
            .cast<Map<String, dynamic>>();
    final curriculumCoursesData =
        (jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/curriculum_courses.json',
                  ),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final prerequisitesData =
        (jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/course_prerequisites.json',
                  ),
                )
                as List)
            .cast<Map<String, dynamic>>();
    final specialtiesData =
        (jsonDecode(await rootBundle.loadString('assets/data/specialties.json'))
                as List)
            .cast<Map<String, dynamic>>();
    final curriculumCourseSpecialtiesData =
        (jsonDecode(
                  await rootBundle.loadString(
                    'assets/data/curriculum_course_specialties.json',
                  ),
                )
                as List)
            .cast<Map<String, dynamic>>();

    final courseById = <int, Map<String, dynamic>>{
      for (final course in coursesData) (course['id'] as num).toInt(): course,
    };
    final specialtyById = <int, Map<String, dynamic>>{
      for (final specialty in specialtiesData)
        (specialty['id'] as num).toInt(): specialty,
    };

    final prerequisitesByCurriculumCourseId = <int, List<String>>{};
    for (final prerequisite in prerequisitesData) {
      final curriculumCourseId = (prerequisite['curriculum_course_id'] as num)
          .toInt();
      final type = prerequisite['prerequisite_type']?.toString();
      String? value;

      if (type == 'completed_cycle') {
        final requiredCycle = (prerequisite['required_cycle'] as num).toInt();
        value = requiredCycle == 5
            ? prereqVCiclo
            : requiredCycle == 6
            ? prereqVICiclo
            : '_${requiredCycle}_CICLO_';
      } else {
        final prerequisiteCurriculumCourseId =
            (prerequisite['prerequisite_curriculum_course_id'] as num).toInt();
        value = prerequisiteCurriculumCourseId.toString();
      }

      if (value.isEmpty) continue;
      prerequisitesByCurriculumCourseId
          .putIfAbsent(curriculumCourseId, () => <String>[])
          .add(value);
    }

    final specialtiesByCurriculumCourseId = <int, List<String>>{};
    for (final relation in curriculumCourseSpecialtiesData) {
      final curriculumCourseId = (relation['curriculum_course_id'] as num)
          .toInt();
      final specialtyId = (relation['specialty_id'] as num).toInt();
      final specialtyName = specialtyById[specialtyId]?['name']?.toString();
      if (specialtyName == null || specialtyName.isEmpty) continue;
      specialtiesByCurriculumCourseId
          .putIfAbsent(curriculumCourseId, () => <String>[])
          .add(specialtyName);
    }

    final list = <CourseNode>[];
    for (final curriculumCourse in curriculumCoursesData) {
      final curriculumCourseId = (curriculumCourse['id'] as num).toInt();
      final courseId = (curriculumCourse['course_id'] as num).toInt();
      final course = courseById[courseId];
      if (course == null) continue;

      final node = CourseNode.fromDbJson(
        course: course,
        curriculumCourse: curriculumCourse,
        prerequisites:
            prerequisitesByCurriculumCourseId[curriculumCourseId] ??
            const <String>[],
        specialties:
            specialtiesByCurriculumCourseId[curriculumCourseId] ??
            const <String>[],
      );
      list.add(node);
    }

    _courses.assignAll(list);
    final user = AuthService.to.currentUser;
    if (user != null) {
      final enrollments = await EnrollmentService().fetchByStudentCode(
        user.code,
      );
      _currentCourseIds = await _resolveCurrentCourseIds(enrollments);
    }
  }

  String _normalizeName(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<Set<String>> _resolveCurrentCourseIds(
    List<dynamic> enrollments,
  ) async {
    final sectionRaw = await rootBundle.loadString(
      'assets/data/secciones.json',
    );
    final sectionData = jsonDecode(sectionRaw) as Map<String, dynamic>;
    final sections = ((sectionData['secciones'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final sectionsById = <String, Map<String, dynamic>>{
      for (final section in sections) section['idSeccion'].toString(): section,
    };
    final coursesByName = <String, CourseNode>{
      for (final course in _courses) _normalizeName(course.name): course,
    };

    final current = <String>{};
    for (final enrollment in enrollments) {
      final section = sectionsById[enrollment.idSeccion];
      if (section == null) continue;

      final rawName = section['curso']?.toString();
      if (rawName == null || rawName.isEmpty) continue;

      final normalizedSectionName = _normalizeName(rawName);
      final exact = coursesByName[normalizedSectionName];
      if (exact != null) {
        current.add(exact.id);
        continue;
      }

      final partial = _courses.firstWhereOrNull((course) {
        final normalizedCourseName = _normalizeName(course.name);
        return normalizedSectionName.contains(normalizedCourseName) ||
            normalizedCourseName.contains(normalizedSectionName);
      });
      if (partial != null) current.add(partial.id);
    }
    return current;
  }

  /// Normaliza la especialidad del usuario al nombre oficial del diploma.
  String normalizeSpecialty(String esp) => _especialidadAliases[esp] ?? esp;

  /// Calcula el mapa { courseId: status } para un usuario.
  Map<String, CourseStatus> computeStatuses(UserModel user) {
    final progress = user.courseProgress ?? CourseProgress.empty();

    // Lookup por id.
    final byId = <String, CourseNode>{for (final c in _courses) c.id: c};

    // Set de cursos aprobados: los niveles aprobados solo incorporan cursos
    // obligatorios; los electivos aprobados no completan ciclos académicos.
    final approved = approvedCourseIdsFor(progress);

    final result = <String, CourseStatus>{};
    for (final c in _courses) {
      if (_currentCourseIds.contains(c.id)) {
        result[c.id] = CourseStatus.current;
        continue;
      }
      // Si está aprobado → approved.
      if (approved.contains(c.id)) {
        result[c.id] = CourseStatus.approved;
        continue;
      }

      // Verificar marcadores de ciclo (electivos).
      final reqLvl = c.requiredCompletedLevel;
      if (reqLvl != null &&
          !hasCompletedMandatoryCyclesFromApprovedIds(approved, reqLvl)) {
        result[c.id] = CourseStatus.locked;
        continue;
      }

      // Verificar prerrequisitos concretos.
      final allPrereqsOk = c.coursePrerequisites.every((p) {
        if (!byId.containsKey(p)) return false;
        return approved.contains(p);
      });

      result[c.id] = allPrereqsOk ? CourseStatus.unlocked : CourseStatus.locked;
    }
    return result;
  }

  /// Recalcula sólo los estados derivados (`locked` / `unlocked`) usando los
  /// cursos aprobados manualmente en la pantalla. Los estados explícitos
  /// (`current` / `approved`) se conservan porque son decisión del alumno.
  Map<String, CourseStatus> recomputeDerivedAvailability({
    required Iterable<CourseNode> visibleCourses,
    required Map<String, CourseStatus> currentStatuses,
  }) {
    final byId = <String, CourseNode>{for (final c in _courses) c.id: c};
    final approved = currentStatuses.entries
        .where((entry) => entry.value == CourseStatus.approved)
        .map((entry) => entry.key)
        .toSet();

    final result = <String, CourseStatus>{};
    for (final c in visibleCourses) {
      final existing = currentStatuses[c.id];
      if (existing == CourseStatus.approved ||
          existing == CourseStatus.current) {
        result[c.id] = existing!;
        continue;
      }

      final reqLvl = c.requiredCompletedLevel;
      if (reqLvl != null &&
          !hasCompletedMandatoryCyclesFromApprovedIds(approved, reqLvl)) {
        result[c.id] = CourseStatus.locked;
        continue;
      }

      final allPrereqsOk = c.coursePrerequisites.every((p) {
        if (!byId.containsKey(p)) return false;
        return approved.contains(p);
      });

      result[c.id] = allPrereqsOk ? CourseStatus.unlocked : CourseStatus.locked;
    }

    return result;
  }

  /// IDs aprobados derivados del progreso persistido.
  ///
  /// `approvedLevels` representa ciclos completos, pero cada ciclo completo
  /// solo aporta cursos obligatorios. Los electivos aprobados se agregan como
  /// cursos individuales y no sirven para completar un ciclo académico.
  Set<String> approvedCourseIdsFor(CourseProgress progress) {
    final approved = <String>{};
    for (final c in _courses) {
      if (!c.isElective && progress.approvedLevels.contains(c.level)) {
        approved.add(c.id);
      }
    }
    approved.addAll(progress.approvedElectives);
    return approved;
  }

  /// True si todos los cursos obligatorios hasta `throughLevel` están aprobados.
  ///
  /// Los electivos se excluyen siempre, incluso si pertenecen visualmente a un
  /// nivel anterior o ya fueron aprobados.
  bool hasCompletedMandatoryCyclesFromApprovedIds(
    Set<String> approvedCourseIds,
    int throughLevel,
  ) {
    return _courses
        .where((c) => !c.isElective && c.level <= throughLevel)
        .every((c) => approvedCourseIds.contains(c.id));
  }

  bool hasCompletedMandatoryCyclesFromStatuses(
    Map<String, CourseStatus> statuses,
    int throughLevel,
  ) {
    final approvedCourseIds = statuses.entries
        .where((entry) => entry.value == CourseStatus.approved)
        .map((entry) => entry.key)
        .toSet();
    return hasCompletedMandatoryCyclesFromApprovedIds(
      approvedCourseIds,
      throughLevel,
    );
  }

  /// Decide si un electivo debe mostrarse según la(s) especialidad(es)
  /// elegidas por el alumno. Si el electivo no tiene especialidad asociada
  /// (caso 520074), siempre se muestra.
  bool electiveMatchesUserSpecialties(
    CourseNode elective,
    List<int> userEspecialidades,
  ) {
    if (!elective.isElective) return true;
    if (userEspecialidades.isEmpty) return false;
    if (elective.specialties.isEmpty) return true;
    final authService = AuthService.to;
    final userEspNames = userEspecialidades
        .map((id) => authService.getEspecialidadName(id))
        .where((name) => name.isNotEmpty)
        .map(normalizeSpecialty)
        .toSet();
    return elective.specialties.any(userEspNames.contains);
  }

  List<CourseNode> visibleCoursesFor(UserModel user) {
    final progress = user.courseProgress ?? CourseProgress.empty();
    final approved = approvedCourseIdsFor(progress);

    return _courses.where((c) {
      if (!c.isElective) return true;
      if (user.especialidades.isEmpty) return false;
      if (approved.contains(c.id) || _currentCourseIds.contains(c.id)) {
        return true;
      }
      return electiveMatchesUserSpecialties(c, user.especialidades);
    }).toList();
  }
}
