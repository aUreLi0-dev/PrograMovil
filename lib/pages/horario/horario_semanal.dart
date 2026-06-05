import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/auth_service.dart';
import 'horario_controller.dart';

/// Horario semanal dinámico.
/// Obtiene los datos del HorarioController y dibuja las columnas correspondientes
/// a la semana activa del alumno.
class HorarioSemanalPage extends StatelessWidget {
  const HorarioSemanalPage({super.key});

  static const double startHour = 7.0;
  static const double endHour = 22.0;

  static const List<String> _days = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
  ];

  static const Color _stripOrange = Color(0xFFF26522);
  static const Color _stripDark = Color(0xFF2E2E2E);

  String _hourLabel(int h) {
    final isPm = h >= 12;
    final display = h > 12 ? h - 12 : h;
    return '$display ${isPm ? 'PM' : 'AM'}';
  }

  List<Map<String, dynamic>> _getClasesForDay(HorarioController controller, String day) {
    if (controller.daysList.isEmpty) return const [];
    final activeDayIdx = controller.currentDayIndex.value;
    final startOfWeekIdx = (activeDayIdx ~/ 7) * 7;
    final endOfWeekIdx = (startOfWeekIdx + 7).clamp(0, controller.daysList.length);
    final activeWeekDays = controller.daysList.sublist(startOfWeekIdx, endOfWeekIdx);
    
    final daySchedule = activeWeekDays.firstWhereOrNull((d) => d.dayName == day);
    if (daySchedule == null) return const [];
    return controller.getCoursesForDay(daySchedule);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(HorarioController());

    return Obx(() {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final bg = isDark ? const Color(0xFF1E1E26) : Colors.white;
      final lineColor =
          isDark ? const Color(0xFF2C2C38) : const Color(0xFFE6E6E6);
      final totalHours = (endHour - startHour).toInt();

      // Datos del alumno logueado para la franja de identidad.
      final user = AuthService.to.currentUser;
      final studentCode = user?.code ?? '';
      final studentName =
          user == null ? '' : '${user.lastName} ${user.firstName}'.toUpperCase();
      final cycle = user?.currentCycle ?? '';

      return Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          title: Text(
            controller.currentDay?.weekText ?? 'Horario',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          backgroundColor: _stripOrange,
          foregroundColor: Colors.white,
        ),
        body: RotatedBox(
          quarterTurns: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Tras rotar, el ancho disponible es la altura de la pantalla.
              final innerW = constraints.maxWidth;
              final innerH = constraints.maxHeight;

              const double headerThickness = 32; // franja de días
              const double identityThickness = 26; // franja del alumno
              const double gutter = 34; // columna de horas

              final bodyH = innerH - headerThickness - identityThickness;
              final hourH = bodyH / totalHours;
              final dayColW = (innerW - gutter) / _days.length;

              return Column(
                children: [
                  // Franja de días (queda a la derecha tras rotar).
                  SizedBox(
                    height: headerThickness,
                    child: Row(
                      children: [
                        const SizedBox(width: gutter),
                        for (final day in _days)
                          (() {
                            final activeDayIdx = controller.currentDayIndex.value;
                            final startOfWeekIdx = (activeDayIdx ~/ 7) * 7;
                            final endOfWeekIdx = (startOfWeekIdx + 7).clamp(0, controller.daysList.length);
                            final activeWeekDays = controller.daysList.sublist(startOfWeekIdx, endOfWeekIdx);
                            final daySchedule = activeWeekDays.firstWhereOrNull((d) => d.dayName == day);
                            final dateText = daySchedule?.dateText ?? '';

                            return Container(
                              width: dayColW,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(color: _stripOrange),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (dateText.isNotEmpty) ...[
                                    const SizedBox(height: 1),
                                    Text(
                                      dateText.toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 7.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          })(),
                      ],
                    ),
                  ),
                  // Cuerpo: horas + columnas de días.
                  SizedBox(
                    height: bodyH,
                    child: Row(
                      children: [
                        // Columna de horas (queda arriba tras rotar).
                        SizedBox(
                          width: gutter,
                          child: Stack(
                            children: [
                              for (int i = 0; i <= totalHours; i++)
                                Positioned(
                                  top: i * hourH - 6,
                                  left: 0,
                                  right: 2,
                                  child: Text(
                                    _hourLabel(startHour.toInt() + i),
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? const Color(0xFF9090A0)
                                          : const Color(0xFF9E9E9E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Una columna por día con sus clases.
                        for (final day in _days)
                          SizedBox(
                            width: dayColW,
                            child: _DayColumn(
                              clases: _getClasesForDay(controller, day),
                              totalHours: totalHours,
                              hourH: hourH,
                              lineColor: lineColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Franja del alumno (queda a la izquierda tras rotar).
                  SizedBox(
                    height: identityThickness,
                    child: Container(
                      color: _stripDark,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            studentCode,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              studentName,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Text(
                            cycle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    });
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.clases,
    required this.totalHours,
    required this.hourH,
    required this.lineColor,
  });

  final List<Map<String, dynamic>> clases;
  final int totalHours;
  final double hourH;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: lineColor, width: 1)),
      ),
      child: Stack(
        children: [
          // Líneas por hora.
          for (int i = 0; i <= totalHours; i++)
            Positioned(
              top: i * hourH,
              left: 0,
              right: 0,
              child: Container(height: 1, color: lineColor),
            ),
          // Bloques de clases.
          ...clases.map((c) {
            final start = _timeToHours(c['hora_inicio'] as String? ?? '07:00 am');
            final end = _timeToHours(c['hora_fin'] as String? ?? '09:00 am');
            final nombre = (c['curso'] as String? ?? '').toUpperCase();
            final salon = c['salon'] as String? ?? '';
            final color = _resolveScheduleColor(c['color'] as String? ?? 'blue');
            final bool isEvaluation = c['isEvaluation'] == true;
            final String evalSigla = c['evalSigla'] as String? ?? '';

            return Positioned(
              top: (start - HorarioSemanalPage.startHour) * hourH + 1,
              left: 2,
              right: 2,
              height: (end - start) * hourH - 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        isEvaluation ? '📝 EVAL: $evalSigla - $nombre' : nombre,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Text(
                      salon,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// Helpers globales privados para parsing de horas y colores
double _timeToHours(String timeStr) {
  try {
    final cleanStr = timeStr.trim().toLowerCase();
    
    // If it contains am/pm, use the 12-hour parser
    if (cleanStr.contains('am') || cleanStr.contains('pm')) {
      final parts = cleanStr.split(' ');
      if (parts.length >= 2) {
        final isPm = parts[1] == 'pm';
        final hms = parts[0].split(':');
        int hour = int.tryParse(hms[0]) ?? 12;
        int minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;

        if (isPm && hour != 12) hour += 12;
        if (!isPm && hour == 12) hour = 0;

        return hour + (minute / 60.0);
      }
    }

    // Try 24-hour parser (e.g., "14:00:00", "14:00")
    final hms = cleanStr.split(':');
    if (hms.isNotEmpty) {
      final hour = int.tryParse(hms[0]);
      if (hour != null) {
        final minute = hms.length > 1 ? (int.tryParse(hms[1]) ?? 0) : 0;
        return hour + (minute / 60.0);
      }
    }

    return 7.0;
  } catch (_) {
    return 7.0;
  }
}

Color _resolveScheduleColor(String colorStr) {
  final cleanColor = colorStr.trim();
  final hexColor = cleanColor.startsWith('#')
      ? cleanColor.substring(1)
      : cleanColor;

  if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hexColor)) {
    return Color(int.parse('FF$hexColor', radix: 16));
  }
  if (RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(hexColor)) {
    return Color(int.parse(hexColor, radix: 16));
  }

  return {
        'yellow': const Color(0xFFF2B705),
        'blue': const Color(0xFF4A90D9),
        'green': const Color(0xFF52C25A),
        'red': const Color(0xFFE9573F),
        'orange': const Color(0xFFF26B3A),
        'pink': const Color(0xFFE5469A),
        'purple': const Color(0xFFB44FD0),
        'teal': const Color(0xFF009688),
      }[cleanColor.toLowerCase()] ??
      Colors.grey;
}
