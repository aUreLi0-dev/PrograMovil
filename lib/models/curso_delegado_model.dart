class CursoDelegado {
  final String idCurso;
  final String nombreCurso;
  final String idSeccion;
  final String codigoSeccion;
  final String rol;
  final int alumnosMatriculados;

  CursoDelegado({
    required this.idCurso,
    required this.nombreCurso,
    required this.idSeccion,
    required this.codigoSeccion,
    required this.rol,
    required this.alumnosMatriculados,
  });

  factory CursoDelegado.fromJson(Map<String, dynamic> json) {
    return CursoDelegado(
      idCurso: json['idCurso']?.toString() ?? '',
      nombreCurso: json['nombreCurso']?.toString() ?? '',
      idSeccion: json['idSeccion']?.toString() ?? '',
      codigoSeccion: json['codigoSeccion']?.toString() ?? '',
      rol: json['rol']?.toString() ?? 'estudiante',
      alumnosMatriculados:
          (json['alumnosMatriculados'] as num?)?.toInt() ?? 0,
    );
  }

  String get rolTexto {
    if (rol == 'subdelegado') return 'Subdelegado';
    return 'Delegado';
  }
}
