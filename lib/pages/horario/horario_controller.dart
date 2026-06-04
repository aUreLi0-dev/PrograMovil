import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/enrollment_service.dart';

class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;

  DaySchedule(this.dayName, this.dateText, this.weekText);
}

class HorarioController extends GetxController {
  final currentDayIndex = 0.obs;
  final daysList = <DaySchedule>[].obs;

  List<Map<String, dynamic>> _todasLasSecciones = [];
  Set<String> _enrolledSectionIds = {};

  @override
  void onInit() {
    super.onInit();
    _loadDays();
    _loadSecciones();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    final user = AuthService.to.currentUser;
    if (user == null) return;
    final enrollments = await EnrollmentService().fetchByStudentCode(user.code);
    _enrolledSectionIds = enrollments.map((e) => e.idSeccion).toSet();
    update();
  }

  Future<void> _loadDays() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/schedule_days.json',
      );
      final List<dynamic> decoded = jsonDecode(jsonString);
      daysList.assignAll(
        decoded
            .map(
              (d) => DaySchedule(
                d['dayName'] as String,
                d['dateText'] as String,
                d['weekText'] as String,
              ),
            )
            .toList(),
      );
      final idx = daysList.indexWhere((d) => d.dayName == 'Viernes');
      currentDayIndex.value = idx != -1 ? idx : 0;
    } catch (e) {
      print('Error al cargar días: $e');
    }
  }

  // Carga el archivo secciones.json que contiene el horario detallado
  Future<void> _loadSecciones() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/secciones.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      _todasLasSecciones = List<Map<String, dynamic>>.from(data['secciones']);
      update(); // Notifica a la UI que los datos están listos
    } catch (e) {
      print('Error al cargar secciones: $e');
    }
  }

  DaySchedule? get currentDay =>
      daysList.isEmpty ? null : daysList[currentDayIndex.value];

  List<Map<String, dynamic>> get currentDayCourses {
    final activeDay = currentDay;
    if (activeDay == null || _todasLasSecciones.isEmpty) return const [];

    final currentDayName = activeDay.dayName.toLowerCase();

    return _todasLasSecciones.where((s) {
      final courseDay = (s['dia'] as String? ?? '').toLowerCase();
      final esMismoDia = courseDay == currentDayName;
      final estaInscrito = _enrolledSectionIds.contains(s['idSeccion']);

      return esMismoDia && estaInscrito;
    }).toList();
  }
  
  void previousDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value > 0) {
      currentDayIndex.value--;
    } else {
      currentDayIndex.value = daysList.length - 1;
    }
  }

  void nextDay() {
    if (daysList.isEmpty) return;
    if (currentDayIndex.value < daysList.length - 1) {
      currentDayIndex.value++;
    } else {
      currentDayIndex.value = 0;
    }
  }

  
}
