class AlertaModel {
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  bool leido;

  AlertaModel({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    this.leido = false,
  });
}
