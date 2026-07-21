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

  String get rolTexto {
    if (rol == 'subdelegado') return 'Subdelegado';
    return 'Delegado';
  }

  /// Construye el modelo a partir del JSON que devuelve el backend
  /// (GET /api/v1/delegate/sections). Las claves coinciden 1 a 1.
  factory CursoDelegado.fromJson(Map<String, dynamic> json) {
    return CursoDelegado(
      idCurso: json['idCurso'].toString(),
      nombreCurso: json['nombreCurso'].toString(),
      idSeccion: json['idSeccion'].toString(),
      codigoSeccion: json['codigoSeccion'].toString(),
      rol: json['rol'].toString(),
      alumnosMatriculados: (json['alumnosMatriculados'] as num?)?.toInt() ?? 0,
    );
  }
}
