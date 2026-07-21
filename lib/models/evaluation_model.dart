class EvaluationComponent {
  final String id;
  final String nombre;
  final String sigla;
  final double peso;
  final String? tipo;
  final int? assessmentId;

  EvaluationComponent({
    required this.id,
    required this.nombre,
    required this.sigla,
    required this.peso,
    this.tipo,
    this.assessmentId,
  });

  factory EvaluationComponent.fromJson(Map<String, dynamic> json) {
    return EvaluationComponent(
      id: json['id']?.toString() ?? json['assessment_id']?.toString() ?? '',
      nombre: json['nombre'] ?? json['assessment_name'] ?? '',
      sigla: json['sigla'] ?? json['assessment_code'] ?? '',
      peso: (json['peso'] as num?)?.toDouble() ?? (json['weight'] as num?)?.toDouble() ?? 0.0,
      tipo: json['tipo'] as String? ?? json['assessment_type'] as String?,
      assessmentId: json['assessment_id'] is int
          ? json['assessment_id'] as int
          : int.tryParse(json['assessment_id']?.toString() ?? ''),
    );
  }
}
