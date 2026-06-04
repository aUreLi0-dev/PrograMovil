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
}
