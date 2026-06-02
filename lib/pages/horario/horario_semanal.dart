import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

/// Horario semanal estático (mismo para todos, por mientras).
/// Réplica fiel de la imagen de referencia: la grilla se construye normal
/// (días en columnas, horas en filas) y se rota 90° para quedar horizontal,
/// con los días a la derecha, las horas arriba y el texto de lado.
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

  // Colores de los cursos (tomados de la imagen de referencia).
  static const Color _yellow = Color(0xFFF2B705);
  static const Color _blue = Color(0xFF4A90D9);
  static const Color _green = Color(0xFF52C25A);
  static const Color _red = Color(0xFFE9573F);
  static const Color _orange = Color(0xFFF26B3A);
  static const Color _pink = Color(0xFFE5469A);
  static const Color _purple = Color(0xFFB44FD0);

  static const Color _stripOrange = Color(0xFFF26522);
  static const Color _stripDark = Color(0xFF2E2E2E);

  // Cursos por día: nombre, salón, hora inicio, hora fin (24h) y color.
  static const Map<String, List<_Clase>> _week = {
    'Lunes': [
      _Clase('ESTRUCTURA DATOS II', 'L3-301', 8, 10, _yellow),
    ],
    'Martes': [
      _Clase('PROG. MÓVIL', 'I1-205', 8, 10, _blue),
      _Clase('PROP. INVESTIGACIÓN', 'H-402', 11, 13, _green),
      _Clase('PARADIG. PROGRAMACIÓN', 'L3-401', 14, 17, _red),
    ],
    'Miércoles': [
      _Clase('ESTRUCTURA DATOS II', 'A1-502', 8, 10, _yellow),
      _Clase('ING. PROCE. NEGOCIO', 'O2-801', 15, 17, _pink),
    ],
    'Jueves': [
      _Clase('PROP. INVESTIGACIÓN', 'Virtual 6', 12, 14, _green),
      _Clase('PARADIG. PROGRAMACIÓN', 'Sala Virtual 14', 15, 17, _orange),
      _Clase('COMP. NUBE/CLOUD COM.', 'Virtual 11', 20, 22, _purple),
    ],
    'Viernes': [
      _Clase('PROG. MÓVIL', 'I1-205', 8, 11, _blue),
      _Clase('ING. PROCE. NEGOCIO', 'A1-605', 15, 17, _pink),
    ],
    'Sábado': [
      _Clase('COMP. NUBE/CLOUD COM.', 'N-406', 11, 13, _purple),
    ],
  };

  String _hourLabel(int h) {
    final isPm = h >= 12;
    final display = h > 12 ? h - 12 : h;
    return '$display ${isPm ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Horario'),
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

            const double headerThickness = 26; // franja de días
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
                        Container(
                          width: dayColW,
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(color: _stripOrange),
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
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
                            clases: _week[day] ?? const [],
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
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.clases,
    required this.totalHours,
    required this.hourH,
    required this.lineColor,
  });

  final List<_Clase> clases;
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
          for (final c in clases)
            Positioned(
              top: (c.start - HorarioSemanalPage.startHour) * hourH + 1,
              left: 2,
              right: 2,
              height: (c.end - c.start) * hourH - 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                decoration: BoxDecoration(
                  color: c.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        c.nombre,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                    ),
                    Text(
                      c.salon,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Clase {
  final String nombre;
  final String salon;
  final int start;
  final int end;
  final Color color;

  const _Clase(this.nombre, this.salon, this.start, this.end, this.color);
}
