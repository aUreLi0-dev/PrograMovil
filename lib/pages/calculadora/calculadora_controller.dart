import 'dart:developer' as developer;
import 'package:get/get.dart';
import '../../models/evaluation_model.dart';
import '../../models/course_syllabus_model.dart';
import '../../models/curso_seccion_model.dart';
import '../../services/evaluations_service.dart';
import '../../services/notas_service.dart';
import '../../services/auth_service.dart';
import '../../services/enrollment_service.dart';
import '../../services/seccion_service.dart';
import '../../constants/calculadora_constants.dart';

class CalculadoraController extends GetxController {
  // lista reactiva de cursos con sus notas, la ui se actualiza sola
  final cursos = <CursoSeccion>[].obs;

  late EvaluationSyllabusService _syllabusService;
  late NotasService _notasService;
  late SeccionService _seccionService;

  // mapa de silabos por id de curso, para sacar las evaluaciones de cada uno
  final syllabusData = <String, CourseSyllabus>{}.obs;

  @override
  void onInit() {
    super.onInit();
    // creamos los servicios y arrancamos la carga
    _syllabusService = EvaluationSyllabusService();
    _notasService = NotasService();
    _seccionService = SeccionService();
    _init();
  }

  Future<void> _init() async {
    // primero el silabo, luego los cursos (necesita el silabo ya cargado)
    await _cargarDatosSyllabus();
    await _inicializarCursos();
  }

  // lo llama home_controller al cambiar a la pestana de calculadora
  Future<void> reload() async {
    cursos.clear();
    syllabusData.clear();
    await _init();
  }

  Future<void> _cargarDatosSyllabus() async {
    try {
      await _syllabusService.loadEvaluationData();
      for (final syllabus in _syllabusService.allSyllabuses) {
        syllabusData[syllabus.cursoId] = syllabus;
      }
      developer.log('âœ“ Datos del sÃ­labo cargados en el controlador');
    } catch (e) {
      developer.log('âœ— Error al cargar datos del sÃ­labo: $e');
    }
  }

  Future<void> _inicializarCursos() async {
    try {
      final user = AuthService.to.currentUser;

      // obtenemos las inscripciones del alumno logeado desde el servicio
      final enrollments = await EnrollmentService().fetchByStudentCode(
        user?.code ?? '',
      );
      final secciones = await _seccionService.fetchSecciones();
      final seccionesById = {
        for (final seccion in secciones) seccion.idSeccion: seccion,
      };
      final idEstudiante =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      final notasGuardadas = await _notasService.cargarNotas(idEstudiante);

      final cursosExpandidos = <CursoSeccion>[];

      for (final enrollment in enrollments) {
        final seccion = seccionesById[enrollment.idSeccion];
        if (seccion == null) continue;

        // recuperamos notas guardadas anteriormente (si hay)
        final notasRx = <Map<String, dynamic>>[].obs;

        final cursoBuscado = notasGuardadas.firstWhereOrNull(
          (n) => n['id'] == seccion.idSeccion,
        );

        if (cursoBuscado != null && cursoBuscado['notas'] != null) {
          notasRx.addAll(
            List<Map<String, dynamic>>.from(cursoBuscado['notas']),
          );
        }

        cursosExpandidos.add(
          CursoSeccion(
            id: seccion.idSeccion,
            nombre: seccion.curso.isNotEmpty
                ? seccion.curso
                : CalculadoraConstantes.cursoSinNombre,
            ciclo: user?.currentCycle ?? CalculadoraConstantes.cicloDefault,
            codigoSeccion: seccion.codigoSeccion.isNotEmpty
                ? seccion.codigoSeccion
                : CalculadoraConstantes.sinSeccion,
            notas: notasRx,
          ),
        );
      }

      // actualizamos la lista reactiva de golpe
      cursos.assignAll(cursosExpandidos);
      developer.log(
        'âœ“ Cursos y secciones cargados correctamente: ${cursos.length} secciones.',
      );
    } catch (e) {
      developer.log('âœ— Error al inicializar cursos: $e');
    }
  }

  // promedio ponderado: (nota * peso) / peso total del silabo
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

    // dividimos contra el peso total del silabo (ej. 100%), no contra lo registrado
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

  // suma simple de pesos de las notas registradas
  double sumaPesos(List<Map<String, dynamic>> notas) {
    return notas.fold(0, (sum, item) => sum + (item['peso'] as num));
  }

  // agrega nota al curso y guarda local
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

  // elimina nota y guarda local
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

  // persiste todas las notas en sharedpreferences
  void _guardarNotasLocal() async {
    try {
      final idEstudiante =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      final cursosMap = cursos
          .map(
            (c) => {
              'id': c.id,
              'nombre': c.nombre,
              'ciclo': c.ciclo,
              'codigoSeccion': c.codigoSeccion,
              'notas': c.notas.toList(),
            },
          )
          .toList();
      await _notasService.guardarNotas(idEstudiante, cursosMap);
    } catch (e) {
      developer.log('âœ— Error al guardar notas localmente: $e');
    }
  }

  // busca el silabo de un curso por su id
  CourseSyllabus? getSyllabusForCourse(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      final cursoId = cursos[cursoIndex].id;
      if (syllabusData.containsKey(cursoId)) {
        return syllabusData[cursoId];
      }
    }
    return null;
  }

  // todas las evaluaciones que tiene un curso segun su silabo
  List<EvaluationComponent> getEvaluationsForCourse(int cursoIndex) {
    final syllabus = getSyllabusForCourse(cursoIndex);
    return syllabus?.evaluaciones ?? [];
  }

  // ids de evaluaciones que ya se registraron (para no mostrarlas de nuevo)
  List<String> getRegisteredEvaluationIds(int cursoIndex) {
    if (cursoIndex >= 0 && cursoIndex < cursos.length) {
      return cursos[cursoIndex].notas
          .map((nota) => nota['evaluacionId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    return [];
  }

  // evaluaciones del silabo menos las que ya se agregaron
  List<EvaluationComponent> getAvailableEvaluations(int cursoIndex) {
    final allEvaluations = getEvaluationsForCourse(cursoIndex);
    final registeredIds = getRegisteredEvaluationIds(cursoIndex);
    return allEvaluations
        .where((eval) => !registeredIds.contains(eval.id))
        .toList();
  }
}
