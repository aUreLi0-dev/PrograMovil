class EvaluationComponent {
  final String id;
  final String nombre;
  final String sigla;
  final double peso;
  final String tipo; 

  EvaluationComponent({
    required this.id,
    required this.nombre,
    required this.sigla,
    required this.peso,
    required this.tipo,
  });

  /// Convertir desde JSON
  factory EvaluationComponent.fromJson(Map<String, dynamic> json) {
    return EvaluationComponent(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      sigla: json['sigla'] ?? '',
      peso: (json['peso'] as num).toDouble(),
      tipo: json['tipo'] ?? '',
    );
  }
}


