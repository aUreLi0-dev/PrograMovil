import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import '../../services/enrollment_service.dart';

class DaySchedule {
  final String dayName;
  final String dateText;
  final String weekText;
  final DateTime date;

  DaySchedule(this.dayName, this.dateText, this.weekText, this.date);
}

class HorarioController extends GetxController {
  final currentDayIndex = 0.obs;
  final daysList = <DaySchedule>[].obs;
  final assessmentsList = <Map<String, dynamic>>[].obs;
  final weeklyLoad = <Map<String, dynamic>>[].obs;
  final currentLimaTime = _nowInLima().obs;

  final _todasLasSecciones = <Map<String, dynamic>>[].obs;
  final _enrolledSectionIds = <String>{}.obs;
  Timer? _clockTimer;

  static const List<String> _months = [
    "Enero",
    "Febrero",
    "Marzo",
    "Abril",
    "Mayo",
    "Junio",
    "Julio",
    "Agosto",
    "Septiembre",
    "Octubre",
    "Noviembre",
    "Diciembre",
  ];

  static DateTime _nowInLima() =>
      DateTime.now().toUtc().subtract(const Duration(hours: 5));

  static String _dateTextFor(DateTime date) =>
      "${date.day} de ${_months[date.month - 1]}";

  @override
  void onInit() {
    super.onInit();
    _startClock();
    _loadDays();
    _loadSecciones();
    _loadAssessments();
    _loadWeeklyLoad();
    _loadEnrollments();
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  void _startClock() {
    currentLimaTime.value = _nowInLima();
    _clockTimer?.cancel();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final oldDay = _dateTextFor(currentLimaTime.value);
      currentLimaTime.value = _nowInLima();
      final newDay = _dateTextFor(currentLimaTime.value);
      if (oldDay != newDay) {
        _generateDaysList();
      }
    });
  }

  Future<void> _loadEnrollments() async {
    final user = AuthService.to.currentUser;
    if (user == null) return;
    try {
      final enrollments = await EnrollmentService().fetchByStudentCode(user.code);
      _enrolledSectionIds.assignAll(enrollments.map((e) => e.idSeccion));
      update();
    } catch (e) {
      debugPrint('Error al cargar matriculas: $e');
    }
  }

  static int _getDisplayWeek(DateTime date) {
    final startOfSemester = DateTime(2026, 4, 6);
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final normalizedStart = DateTime(startOfSemester.year, startOfSemester.month, startOfSemester.day);
    
    final mondayOfDateWeek = normalizedDate.subtract(Duration(days: normalizedDate.weekday - 1));
    
    final daysDiff = mondayOfDateWeek.difference(normalizedStart).inDays;
    final weeksElapsed = (daysDiff / 7).floor();
    final weekNumber = weeksElapsed + 1;
    
    int displayWeek = ((weekNumber - 1) % 16) + 1;
    if (displayWeek <= 0) {
      displayWeek += 16;
    }
    return displayWeek;
  }

  void _generateDaysList() {
    final now = currentLimaTime.value;
    final normalizedNow = DateTime(now.year, now.month, now.day);
    
    final startOfSemester = DateTime(2026, 4, 6);
    
    final List<DaySchedule> generated = [];
    final List<String> daysNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    
    // Generate 16 weeks (112 days)
    for (int w = 0; w < 16; w++) {
      final weekStartMonday = startOfSemester.add(Duration(days: w * 7));
      final weekText = "Semana ${w + 1} del ciclo";
      
      for (int d = 0; d < 7; d++) {
        final dayDate = weekStartMonday.add(Duration(days: d));
        final dateText = _dateTextFor(dayDate);
        generated.add(DaySchedule(daysNames[d], dateText, weekText, dayDate));
      }
    }
    
    daysList.assignAll(generated);
    
    // Search current day index matching today's date
    int idx = daysList.indexWhere((d) =>
        d.date.year == normalizedNow.year &&
        d.date.month == normalizedNow.month &&
        d.date.day == normalizedNow.day);
        
    if (idx == -1) {
      // Fallback: If today is outside the 16 weeks, find today's weekday in Week 1
      final weekdayIndex = now.weekday - 1; // 0 for Mon, 6 for Sun
      idx = weekdayIndex >= 0 && weekdayIndex < 7 ? weekdayIndex : 0;
    }
    
    currentDayIndex.value = idx >= 0 && idx < daysList.length ? idx : 0;
  }

  Future<void> _loadDays() async {
    _generateDaysList();
  }

  Future<void> _loadSecciones() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/secciones.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      _todasLasSecciones.assignAll(
        (data['secciones'] as List? ?? [])
            .map((item) => Map<String, dynamic>.from(item))
            .toList(),
      );
      update();
    } catch (e) {
      debugPrint('Error al cargar secciones: $e');
    }
  }

  Future<void> _loadAssessments() async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/evaluaciones.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);
      
      final flattened = <Map<String, dynamic>>[];
      final List<dynamic> cursosList = data['cursos'] as List<dynamic>? ?? [];
      
      for (final curso in cursosList) {
        if (curso is! Map) continue;
        final cursoId = curso['cursoId'] as String? ?? '';
        final cursoNombre = curso['cursoNombre'] as String? ?? '';
        final evaluaciones = curso['evaluaciones'] as List<dynamic>? ?? [];
        
        for (final eval in evaluaciones) {
          if (eval is! Map) continue;
          final weekNumber = eval['weekNumber'];
          if (weekNumber != null) {
            flattened.add({
              'weekNumber': weekNumber,
              'cursoId': cursoId,
              'courseName': cursoNombre,
              'code': eval['sigla'] ?? '',
              'name': eval['nombre'] ?? '',
            });
          }
        }
      }
      
      assessmentsList.assignAll(flattened);
      update();
    } catch (e) {
      debugPrint('Error al cargar evaluaciones: $e');
    }
  }

  Future<void> _loadWeeklyLoad() async {
    try {
      // Cargamos una estructura vacía directamente en el código para evitar lecturas de archivos innecesarios
      weeklyLoad.assignAll([]);
      update();
    } catch (e) {
      debugPrint('Error al cargar carga semanal: $e');
    }
  }

  DaySchedule? get currentDay =>
      daysList.isEmpty ? null : daysList[currentDayIndex.value];

  bool isCurrentLimaDay(DaySchedule day) =>
      day.dateText.toLowerCase() ==
      _dateTextFor(currentLimaTime.value).toLowerCase();

  double get currentLimaHourDecimal {
    final now = currentLimaTime.value;
    return now.hour + (now.minute / 60.0) + (now.second / 3600.0);
  }

  List<Map<String, dynamic>> getCoursesForDay(DaySchedule day) {
    if (_todasLasSecciones.isEmpty) return const [];

    final currentDayName = day.dayName.toLowerCase();
    final courses = <Map<String, dynamic>>[];

    // 1. Agregar las clases regulares
    for (final section in _todasLasSecciones) {
      final sectionIdStr = section['idSeccion']?.toString() ?? '';
      final estaInscrito = _enrolledSectionIds.contains(sectionIdStr);
      if (!estaInscrito) continue;

      final horarios = section['horarios'];
      if (horarios is List && horarios.isNotEmpty) {
        for (final rawHorario in horarios) {
          if (rawHorario is! Map) continue;
          final horario = Map<String, dynamic>.from(rawHorario);
          final courseDay = (horario['dia'] as String? ?? '').toLowerCase();
          if (courseDay != currentDayName) continue;

          courses.add({...section, ...horario, 'isEvaluation': false});
        }
        continue;
      }

      final courseDay = (section['dia'] as String? ?? '').toLowerCase();
      if (courseDay == currentDayName) {
        courses.add({...section, 'isEvaluation': false});
      }
    }

    // 2. Buscar evaluaciones para este dia y asociarlas a las clases regulares
    final dayDisplayWeek = _getDisplayWeek(day.date);

    for (var course in courses) {
      final courseName = course['curso']?.toString().toLowerCase().trim() ?? '';

      for (final assessment in assessmentsList) {
        final evalWeekNumber = (assessment['weekNumber'] as num?)?.toInt();
        if (evalWeekNumber == null) continue;

        final weekMatches = evalWeekNumber == dayDisplayWeek;
        
        final evalCursoId = assessment['cursoId']?.toString().trim() ?? '';
        final evalCourseName = assessment['courseName']?.toString().toLowerCase().trim() ?? '';
        
        final matchesCourse = (evalCursoId.isNotEmpty && evalCursoId == course['idSeccion']) ||
                              (evalCourseName.isNotEmpty && evalCourseName == courseName);

        if (weekMatches && matchesCourse) {
          final nameStr = assessment['name'] as String? ?? '';
          course['isEvaluation'] = true;
          course['evalSigla'] = _getInitialsFromName(nameStr);
          course['evalNombre'] = nameStr;
          debugPrint("--> MERGED! Set isEvaluation = true for course: ${course['curso']} (${course['evalSigla']}) on Week $dayDisplayWeek");
          break; // Encontrado para esta clase
        }
      }
    }

    return courses;
  }

  List<Map<String, dynamic>> get currentDayCourses {
    final activeDay = currentDay;
    if (activeDay == null) return const [];
    return getCoursesForDay(activeDay);
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

  String _getInitialsFromName(String name) {
    if (name.isEmpty) return '';
    final prepositions = {
      'de', 'del', 'la', 'el', 'y', 'con', 'en', 'para', 'o', 'a', 'por', 'los', 'las'
    };
    
    final words = name.trim().split(RegExp(r'\s+'));
    final initials = StringBuffer();
    
    for (final word in words) {
      if (word.isEmpty) continue;
      final cleanWord = word.replaceAll(RegExp(r'[^\w\dáéíóúÁÉÍÓÚñÑ]'), '');
      if (cleanWord.isEmpty) continue;
      
      if (RegExp(r'^\d+$').hasMatch(cleanWord)) {
        initials.write(cleanWord);
      } else {
        final lowerWord = cleanWord.toLowerCase();
        if (!prepositions.contains(lowerWord)) {
          initials.write(cleanWord[0].toUpperCase());
        }
      }
    }
    return initials.toString();
  }
}
