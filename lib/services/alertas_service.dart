import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ulima_plus/models/alerta_model.dart';
import 'package:ulima_plus/models/malla_models.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/malla_service.dart';
import 'package:ulima_plus/services/notas_service.dart';
import 'package:ulima_plus/services/storage_service.dart';

class AlertasService extends GetxController {
  static AlertasService get to => Get.find();

  final RxList<AlertaModel> alertas = <AlertaModel>[].obs;
  final RxBool cargando = false.obs;

  // Clave de persistencia del estado de lectura, namespaced por alumno para
  // que el estado "leído" no se filtre entre cuentas.
  String get _readKey => 'alertas_leidas_${AuthService.to.currentUser?.code ?? 'anon'}';

  // IDs que el usuario ya marcó como leídos. Se persisten en disco para
  // sobrevivir a la destrucción del servicio al salir de la pantalla y a
  // reinicios de la app.
  final Set<String> _readIds = {};
  // Código del alumno cuyos IDs leídos están en memoria. Como el servicio es
  // permanente, sirve para recargar el set al cambiar de cuenta.
  String? _readIdsOwner;

  final NotasService _notasService = NotasService();

  int get sinLeer => alertas.where((a) => !a.leido).length;

  Future<void> _cargarReadIds() async {
    final code = AuthService.to.currentUser?.code ?? 'anon';
    if (_readIdsOwner == code) return;
    _readIds.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      _readIds.addAll(prefs.getStringList(_readKey) ?? const []);
    } catch (e) {
      debugPrint('[AlertasService] Error cargando leídos: $e');
    }
    _readIdsOwner = code;
  }

  Future<void> _guardarReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_readKey, _readIds.toList());
    } catch (e) {
      debugPrint('[AlertasService] Error guardando leídos: $e');
    }
  }

  /// Normaliza un nombre de curso para comparar entre la malla y evaluaciones:
  /// mayúsculas, sin tildes y descartando el alias en inglés tras "/".
  String _normNombre(String s) {
    var t = s.toUpperCase().trim();
    final slash = t.indexOf('/');
    if (slash != -1) t = t.substring(0, slash);
    const acentos = {
      'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
    };
    acentos.forEach((k, v) => t = t.replaceAll(k, v));
    return t.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  AlertaModel _cargaAlerta(String cursoId, String nombre, int nEvals) {
    final mensaje = nEvals > 0
        ? 'Se acerca una etapa de alta carga en $nombre: $nEvals evaluaciones '
            'programadas este semestre. Organiza tu tiempo con anticipación.'
        : 'Estás cursando $nombre. Prepárate para sus evaluaciones y organiza '
            'tu carga académica con anticipación.';
    return AlertaModel(
      id: 'alta_carga_$cursoId',
      tipo: 'alta_carga',
      titulo: 'SEMANAS DE ALTA CARGA',
      mensaje: mensaje,
    );
  }

  Future<void> generarAlertas() async {
    final user = AuthService.to.currentUser;
    if (user == null) return;

    cargando.value = true;

    try {
      await _cargarReadIds();

      // Notas REGISTRADAS por el alumno en la calculadora (no datos estáticos).
      // La calculadora guarda bajo este mismo id, por eso se reutiliza.
      final idEstudiante =
          await _notasService.obtenerIdEstudianteActual() ?? 'default';
      final notasGuardadas = await _notasService.cargarNotas(idEstudiante);

      final rawEvals =
          await rootBundle.loadString('assets/data/evaluaciones.json');
      final evalsData = (jsonDecode(rawEvals)['cursos'] as List)
          .cast<Map<String, dynamic>>();

      final rawSecciones =
          await rootBundle.loadString('assets/data/secciones.json');
      final seccionesData = (jsonDecode(rawSecciones)['secciones'] as List)
          .cast<Map<String, dynamic>>();

      final currentCourses = user.courseProgress?.currentCourses ?? [];

      final List<AlertaModel> riesgoAlertas = [];
      // Carga académica deduplicada por curso (enrollment + malla).
      final Map<String, AlertaModel> cargaPorCurso = {};
      final List<AlertaModel> generalAlertas = [];
      final List<AlertaModel> cursoAlertas = [];

      double sumaPromedios = 0;
      int cursosConNotas = 0;

      for (final enrollment in currentCourses) {
        final sectionId = enrollment['idSeccion']?.toString() ?? '';

        final seccion = seccionesData.firstWhereOrNull(
          (s) => s['idSeccion']?.toString() == sectionId,
        );
        final courseName = seccion?['curso'] as String? ?? sectionId;

        final evalEntry = evalsData.firstWhereOrNull(
          (e) => e['cursoId']?.toString() == sectionId,
        );
        final evalsList =
            (evalEntry?['evaluaciones'] as List?)?.cast<Map<String, dynamic>>() ??
                [];

        // Notas que el alumno registró para esta sección.
        final cursoRegistrado = notasGuardadas.firstWhereOrNull(
          (n) => n['id']?.toString() == sectionId,
        );
        final notasList =
            (cursoRegistrado?['notas'] as List?)?.cast<Map<String, dynamic>>() ??
                [];

        // SEMANAS DE ALTA CARGA: para los cursos matriculados con evaluaciones.
        if (evalsList.isNotEmpty) {
          cargaPorCurso.putIfAbsent(
            sectionId,
            () => _cargaAlerta(sectionId, courseName, evalsList.length),
          );
        }

        // Promedio ponderado con las notas REGISTRADAS.
        double weightedSum = 0;
        double weightSum = 0;
        for (final nota in notasList) {
          final valor = (nota['valor'] as num).toDouble();
          final peso = (nota['peso'] as num).toDouble();
          weightedSum += valor * peso;
          weightSum += peso;
        }

        if (weightSum > 0) {
          final avg = weightedSum / weightSum;
          sumaPromedios += avg;
          cursosConNotas++;

          // RIESGO ACADÉMICO: promedio actual por debajo del mínimo aprobatorio.
          if (avg < 10.5) {
            riesgoAlertas.add(AlertaModel(
              id: 'riesgo_$sectionId',
              tipo: 'riesgo_academico',
              titulo: 'RIESGO ACADÉMICO',
              mensaje:
                  'Tu promedio actual en $courseName (${avg.toStringAsFixed(2)}) '
                  'es menor al mínimo aprobatorio (10.5). Aún estás a tiempo de '
                  'nivelarte para las próximas evaluaciones.',
            ));
          }

          // PROMEDIO PONDERADO por curso (recordatorio tras registrar notas).
          final String consejo;
          if (avg >= 15) {
            consejo = 'Excelente rendimiento, sigue así.';
          } else if (avg >= 12) {
            consejo = 'Buen rendimiento, mantén el esfuerzo.';
          } else {
            consejo = 'Necesitas mejorar tu rendimiento académico.';
          }

          cursoAlertas.add(AlertaModel(
            id: 'promedio_curso_$sectionId',
            tipo: 'promedio_curso',
            titulo: 'PROMEDIO PONDERADO - $courseName',
            mensaje:
                'Tu promedio ponderado actual en este curso es '
                '${avg.toStringAsFixed(2)}. $consejo',
          ));
        }
      }

      // SEMANAS DE ALTA CARGA para los cursos que el alumno marcó como
      // "Cursando" en la malla. La malla guarda el estado por id de nodo en
      // StorageService; se mapea a evaluaciones por nombre de curso.
      final statuses = Get.isRegistered<StorageService>()
          ? StorageService.to.savedStatuses
          : null;
      if (statuses != null && Get.isRegistered<MallaService>()) {
        for (final node in MallaService.to.courses) {
          if (statuses[node.id] != CourseStatus.current) continue;

          final evalEntry = evalsData.firstWhereOrNull(
            (e) =>
                _normNombre(e['cursoNombre']?.toString() ?? '') ==
                _normNombre(node.name),
          );
          final evalsList =
              (evalEntry?['evaluaciones'] as List?)?.cast<Map<String, dynamic>>() ??
                  const [];

          final cursoId = evalEntry?['cursoId']?.toString() ?? node.id;
          cargaPorCurso.putIfAbsent(
            cursoId,
            () => _cargaAlerta(cursoId, node.name, evalsList.length),
          );
        }
      }

      // PROMEDIO GENERAL (solo si registró notas en al menos un curso).
      if (cursosConNotas > 0) {
        final avg = sumaPromedios / cursosConNotas;
        generalAlertas.add(AlertaModel(
          id: 'promedio_general',
          tipo: 'promedio_general',
          titulo: 'PROMEDIO GENERAL DEL ALUMNO',
          mensaje:
              'Tu promedio ponderado general es ${avg.toStringAsFixed(2)}. '
              'Mantén tu rendimiento académico para alcanzar tus objetivos.',
        ));
      }

      final nuevas = [
        ...riesgoAlertas,
        ...cargaPorCurso.values,
        ...generalAlertas,
        ...cursoAlertas,
      ];

      // Restaurar estado de lectura para que no se reinicie al regenerar.
      for (final alerta in nuevas) {
        if (_readIds.contains(alerta.id)) {
          alerta.leido = true;
        }
      }

      // Las no leídas (nuevas) van primero; se conserva el orden por categoría
      // dentro de cada grupo.
      final ordenadas = [
        ...nuevas.where((a) => !a.leido),
        ...nuevas.where((a) => a.leido),
      ];

      alertas.assignAll(ordenadas);
    } catch (e, st) {
      debugPrint('[AlertasService] Error generando alertas: $e\n$st');
    } finally {
      cargando.value = false;
    }
  }

  void marcarComoLeido(String id) {
    _readIds.add(id);
    _guardarReadIds();
    final index = alertas.indexWhere((a) => a.id == id);
    if (index != -1) {
      alertas[index].leido = true;
      alertas.refresh();
    }
  }

  void marcarTodasComoLeidas() {
    for (final a in alertas) {
      _readIds.add(a.id);
      a.leido = true;
    }
    _guardarReadIds();
    alertas.refresh();
  }
}
