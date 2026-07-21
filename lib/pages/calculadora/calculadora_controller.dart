import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../../models/evaluation_model.dart';
import '../../models/course_syllabus_model.dart';
import '../../models/curso_seccion_model.dart';
import '../../services/auth_service.dart';
import '../../services/api_client.dart';
import '../../constants/calculadora_constants.dart';

class CalculadoraController extends GetxController {
  final cursos = <CursoSeccion>[].obs;
  final syllabusData = <String, CourseSyllabus>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    await _inicializarCursos();
  }

  Future<void> reload() async {
    cursos.clear();
    syllabusData.clear();
    await _init();
  }

  Future<void> _inicializarCursos() async {
    try {
      final user = AuthService.to.currentUser;
      final api = ApiClient();

      List<Map<String, dynamic>> cursosApi = [];
      if (user?.id != null) {
        try {
          final response = await api.getJson(
            '/api/v1/calculator/student/${user!.id}/courses',
          );
          final data = response['data'] as Map<String, dynamic>?;
          if (data != null) {
            cursosApi = (data['courses'] as List<dynamic>?)
                    ?.cast<Map<String, dynamic>>() ??
                [];
          }
        } catch (e) {
          developer.log('Error al cargar cursos desde API: $e');
        }
      }

      if (cursosApi.isNotEmpty) {
        final cursosExpandidos = <CursoSeccion>[];
        for (final c in cursosApi) {
          final enrollmentId = c['enrollment_id'] as int? ?? 0;
          final courseData = c['course'] as Map<String, dynamic>? ?? {};
          final courseId = courseData['id']?.toString() ?? '';

          List<Map<String, dynamic>> notas = [];
          CourseSyllabus? syllabus;

          try {
            final detailResponse = await api.getJson(
              '/api/v1/calculator/enrollment/$enrollmentId',
            );
            final detail = detailResponse['data'] as Map<String, dynamic>?;
            if (detail != null) {
              final assesments =
                  detail['assesments'] as List<dynamic>? ?? [];
              for (final a in assesments) {
                final aMap = a as Map<String, dynamic>;
                final value = aMap['value'];
                if (value != null) {
                  notas.add({
                    'titulo': aMap['assessment_name'] as String? ?? '',
                    'peso': (aMap['weight'] as num?)?.toInt() ?? 0,
                    'valor': (value as num).toDouble(),
                    'evaluacionId': aMap['assessment_id']?.toString() ?? '',
                    'simulated_grade_id': aMap['simulated_grade_id'],
                    'assessment_id': aMap['assessment_id'],
                    'enrollment_id': enrollmentId,
                  });
                }
              }

              syllabus = CourseSyllabus.fromJson(detail);
              if (courseId.isNotEmpty) {
                syllabusData[syllabus.cursoId] = syllabus;
              }
            }
          } catch (e) {
            developer.log('Error al cargar detalle matrícula $enrollmentId: $e');
          }

          cursosExpandidos.add(
            CursoSeccion(
              id: courseId,
              nombre: courseData['name'] as String? ??
                  CalculadoraConstantes.cursoSinNombre,
              ciclo: c['academic_period_code'] as String? ??
                  user?.currentCycle ??
                  CalculadoraConstantes.cicloDefault,
              codigoSeccion: c['section_code'] as String? ??
                  CalculadoraConstantes.sinSeccion,
              enrollmentId: enrollmentId,
              notas: notas.obs,
            ),
          );
        }
        cursos.assignAll(cursosExpandidos);
        developer.log(
          'Cursos cargados desde API: ${cursos.length}',
        );
      }
    } catch (e) {
      developer.log('Error al inicializar cursos: $e');
    }
  }

  double calcularPromedio(int cursoIndex) {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return 0.0;
    final notas = cursos[cursoIndex].notas;
    if (notas.isEmpty) return 0.0;

    double weightedSum = 0;
    double weightSum = 0;
    for (final n in notas) {
      final valor = (n['valor'] as num).toDouble();
      final peso = (n['peso'] as num).toDouble();
      weightedSum += valor * peso;
      weightSum += peso;
    }

    final syllabus = getSyllabusForCourse(cursoIndex);
    if (syllabus != null) {
      final totalWeight = syllabus.evaluaciones.fold<double>(
        0.0,
        (sum, e) => sum + e.peso,
      );
      if (totalWeight > 0) return weightedSum / totalWeight;
    }

    return weightSum > 0 ? weightedSum / weightSum : 0.0;
  }

  double sumaPesos(List<Map<String, dynamic>> notas) {
    return notas.fold(0, (sum, item) => sum + (item['peso'] as num));
  }

  Future<void> agregarNota(
    int cursoIndex,
    String titulo,
    int peso,
    double valor,
    String evaluacionId,
    int assessmentId,
  ) async {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return;

    final enrollmentId = _getEnrollmentId(cursoIndex);
    if (enrollmentId > 0 && assessmentId > 0) {
      try {
        final api = ApiClient();
        await api.postJson(
          '/api/v1/calculator/simulated-grades',
          body: {
            'enrollment_id': enrollmentId,
            'assessment_id': assessmentId,
            'value': valor,
          },
        );
      } catch (e) {
        developer.log('Error al guardar nota en API: $e');
      }
    }

    cursos[cursoIndex].notas.add({
      'titulo': titulo,
      'peso': peso,
      'valor': valor,
      'evaluacionId': evaluacionId,
      'assessment_id': assessmentId,
    });
    cursos.refresh();
  }

  Future<void> eliminarNota(int cursoIndex, int notaIndex) async {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return;
    final notas = cursos[cursoIndex].notas;
    if (notaIndex < 0 || notaIndex >= notas.length) return;

    final nota = notas[notaIndex];
    final assessmentId = nota['assessment_id'] as int? ?? 0;
    final enrollmentId = _getEnrollmentId(cursoIndex);

    if (enrollmentId > 0 && assessmentId > 0) {
      try {
        final api = ApiClient();
        await api.postJson(
          '/api/v1/calculator/simulated-grades',
          body: {
            'enrollment_id': enrollmentId,
            'assessment_id': assessmentId,
            'value': null,
          },
        );
      } catch (e) {
        developer.log('Error al eliminar nota en API: $e');
      }
    }

    notas.removeAt(notaIndex);
    cursos.refresh();
  }

  int _getEnrollmentId(int cursoIndex) {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return 0;
    return cursos[cursoIndex].enrollmentId;
  }

  CourseSyllabus? getSyllabusForCourse(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final cursoId = cursos[cursoIndex].id;
      if (syllabusData.containsKey(cursoId)) {
        return syllabusData[cursoId];
      }
    }
    return null;
  }

  List<EvaluationComponent> getEvaluationsForCourse(int cursoIndex) {
    final syllabus = getSyllabusForCourse(cursoIndex);
    return syllabus?.evaluaciones ?? [];
  }

  List<String> getRegisteredEvaluationIds(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      return cursos[cursoIndex].notas
          .map((nota) => nota['evaluacionId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
    final allEvaluations = getEvaluationsForCourse(cursoIndex);
    final registeredIds = getRegisteredEvaluationIds(cursoIndex);
    return allEvaluations
        .where((eval) => !registeredIds.contains(eval.id))
        .toList();
  }
}
