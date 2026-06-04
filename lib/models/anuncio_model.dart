class Anuncio {
  final String id;
  final String idSeccion;
  final String titulo;
  final String mensaje;
  final String fecha;
  final String autorCode;
  final String autorName;
  final String autorRole;

  Anuncio({
    required this.id,
    required this.idSeccion,
    required this.titulo,
    required this.mensaje,
    required this.fecha,
    required this.autorCode,
    this.autorName = '',
    this.autorRole = 'estudiante',
  });

  factory Anuncio.fromJson(
    Map<String, dynamic> json, {
    String? autorName,
    String? autorRole,
  }) {
    return Anuncio(
      id: json['id'].toString(),
      idSeccion: json['idSeccion'].toString(),
      titulo: json['titulo'].toString(),
      mensaje: json['mensaje'].toString(),
      fecha: json['fecha'].toString(),
      autorCode: json['autorCode'].toString(),
      autorName: autorName ?? '',
      autorRole: autorRole ?? 'estudiante',
    );
  }
}
