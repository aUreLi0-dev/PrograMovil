import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../../models/evaluation_model.dart';
import '../../models/course_syllabus_model.dart';
import '../../models/curso_seccion_model.dart';
import '../../services/evaluations_service.dart';
import '../../services/courses_service.dart';
import '../../services/notas_service.dart';
import '../../services/auth_service.dart';
import '../../services/enrollment_service.dart';
import '../../constants/calculadora_constants.dart';

class CalculadoraController extends GetxController {
  final cursos = <CursoSeccion>[].obs;

  late EvaluationSyllabusService _syllabusService;
  late CoursesService _coursesService;
  late NotasService _notasService;

  final syllabusData = <String, CourseSyllabus>{}.obs;

  @override
  void onInit() {
    super.onInit();
    _syllabusService = EvaluationSyllabusService();
    _coursesService = CoursesService();
    _notasService = NotasService();
    _init();
  }

  Future<void> _init() async {
    await _cargarDatosSyllabus();
    await _inicializarCursos();
  }

  Future<void> reload() async {
    cursos.clear();
    syllabusData.clear();
    await _init();
  }

  Future<void> _cargarDatosSyllabus() async {
    try {
      await _syllabusService.loadEvaluationData();
      for (var syllabus in _syllabusService.allSyllabuses) {
        syllabusData[syllabus.cursoId] = syllabus;
      }
      developer.log('✓ Datos del sílabo cargados en el controlador');
    } catch (e) {
      developer.log('✗ Error al cargar datos del sílabo: $e');
    }
  }

  Future<void> _inicializarCursos() async {
    try {
      final user = AuthService.to.currentUser;

      final enrollments = await EnrollmentService().fetchByStudentCode(user?.code ?? '');
      final seccionesInscritas = enrollments
          .map((e) => {'idSeccion': e.idSeccion, 'idCurso': e.idCurso})
          .toList();
      final idEstudiante =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      final cursosData = _coursesService.allCourses;
      final notasGuardadas = await _notasService.cargarNotas(idEstudiante);

      final cursosExpandidos = <CursoSeccion>[];

      for (var curso in cursosData) {
        List<dynamic> seccionesDelCurso = curso['secciones'] ?? [];

        for (var seccion in seccionesDelCurso) {
          bool estaInscrito = seccionesInscritas.any(
            (inscrito) => inscrito['idSeccion'] == seccion['idSeccion'],
          );

          if (!estaInscrito) continue;

          var notasRx = <Map<String, dynamic>>[].obs;

          Map<String, dynamic>? cursoBuscado = notasGuardadas.firstWhereOrNull(
            (n) => n['id'] == seccion['idSeccion'],
          );

          if (cursoBuscado != null && cursoBuscado['notas'] != null) {
            notasRx.addAll(
              List<Map<String, dynamic>>.from(cursoBuscado['notas']),
            );
          }

          cursosExpandidos.add(CursoSeccion(
            id: seccion['idSeccion'],
            nombre: curso['nombre']?.toString() ?? CalculadoraConstantes.cursoSinNombre,
            ciclo: curso['ciclo']?.toString() ?? CalculadoraConstantes.cicloDefault,
            codigoSeccion:
                seccion['codigoSeccion']?.toString() ?? CalculadoraConstantes.sinSeccion,
            notas: notasRx,
          ));
        }
      }

      cursos.assignAll(cursosExpandidos);
      developer.log(
        '✓ Cursos y secciones cargados correctamente: ${cursos.length} secciones.',
      );
    } catch (e) {
      developer.log('✗ Error al inicializar cursos: $e');
    }
  }


  double calcularPromedio(int cursoIndex) {
    if (cursoIndex < 0 || cursoIndex >= cursos.length) return 0.0;
    final notas = cursos[cursoIndex].notas;
    if (notas.isEmpty) return 0.0;

    double weightedSum = 0;
    double weightSum = 0;
    for (var n in notas) {
      final valor = (n['valor'] as num).toDouble();
      final peso = (n['peso'] as num).toDouble();
      weightedSum += valor * peso;
      weightSum += peso;
    }

    final syllabus = getSyllabusForCourse(cursoIndex);
    if (syllabus != null) {
      final totalWeight = syllabus.evaluaciones.fold<double>(
        0.0, (sum, e) => sum + e.peso,
      );
      if (totalWeight > 0) return weightedSum / totalWeight;
    }

    return weightSum > 0 ? weightedSum / weightSum : 0.0;
  }

  double sumaPesos(List<Map<String, dynamic>> notas) {
    return notas.fold(0, (sum, item) => sum + (item['peso'] as num));
  }

  void agregarNota(
    int cursoIndex,
    String titulo,
    int peso,
    double valor,
    String evaluacionId,
  ) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      cursos[cursoIndex].notas.add({
        'titulo': titulo,
        'peso': peso,
        'valor': valor,
        'evaluacionId': evaluacionId,
      });
      cursos.refresh();
      _guardarNotasLocal();
    }
  }

  void eliminarNota(int cursoIndex, int notaIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final notas = cursos[cursoIndex].notas;
      if (notaIndex >= 0 && notaIndex < notas.length) {
        notas.removeAt(notaIndex);
        cursos.refresh();
        _guardarNotasLocal();
      }
    }
  }

  void _guardarNotasLocal() async {
    try {
      final idEstudiante =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      final cursosMap = cursos.map((c) => {
        'id': c.id,
        'nombre': c.nombre,
        'ciclo': c.ciclo,
        'codigoSeccion': c.codigoSeccion,
        'notas': c.notas.toList(),
      }).toList();
      await _notasService.guardarNotas(idEstudiante, cursosMap);
    } catch (e) {
      developer.log('✗ Error al guardar notas localmente: $e');
    }
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
