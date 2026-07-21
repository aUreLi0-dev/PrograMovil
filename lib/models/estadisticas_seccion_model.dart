class EstadisticasSeccion {
  final double promedioGeneral;
  final int porcentajeAprobados;
  final int rango0_10;
  final int rango11_13;
  final int rango14_16;
  final int rango17_20;

  EstadisticasSeccion({
    required this.promedioGeneral,
    required this.porcentajeAprobados,
    required this.rango0_10,
    required this.rango11_13,
    required this.rango14_16,
    required this.rango17_20,
  });

  /// Construye el modelo a partir del JSON del backend
  /// (GET /api/v1/sections/{id}/statistics). Las claves coinciden 1 a 1.
  factory EstadisticasSeccion.fromJson(Map<String, dynamic> json) {
    return EstadisticasSeccion(
      promedioGeneral: (json['promedioGeneral'] as num?)?.toDouble() ?? 0,
      porcentajeAprobados: (json['porcentajeAprobados'] as num?)?.toInt() ?? 0,
      rango0_10: (json['rango0_10'] as num?)?.toInt() ?? 0,
      rango11_13: (json['rango11_13'] as num?)?.toInt() ?? 0,
      rango14_16: (json['rango14_16'] as num?)?.toInt() ?? 0,
      rango17_20: (json['rango17_20'] as num?)?.toInt() ?? 0,
    );
  }
}
