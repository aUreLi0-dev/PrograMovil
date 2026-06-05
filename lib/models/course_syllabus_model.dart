import 'evaluation_model.dart';

// silabo completo de un curso con su lista de evaluaciones
class CourseSyllabus {
  final String cursoId;
  final String cursoNombre;
  final List<EvaluationComponent> evaluaciones;

  CourseSyllabus({
    required this.cursoId,
    required this.cursoNombre,
    required this.evaluaciones,
  });

  // construye desde el json de evaluaciones
  factory CourseSyllabus.fromJson(Map<String, dynamic> json) {
    final evaluacionesList = (json['evaluaciones'] as List<dynamic>? ?? [])
        .map((eval) => EvaluationComponent.fromJson(eval as Map<String, dynamic>))
        .toList();

    return CourseSyllabus(
      cursoId: json['cursoId'] ?? '',
      cursoNombre: json['cursoNombre'] ?? '',
      evaluaciones: evaluacionesList,
    );
  }
}
