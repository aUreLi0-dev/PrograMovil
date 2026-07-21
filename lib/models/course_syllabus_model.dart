import 'evaluation_model.dart';

class CourseSyllabus {
  final String cursoId;
  final String cursoNombre;
  final List<EvaluationComponent> evaluaciones;

  CourseSyllabus({
    required this.cursoId,
    required this.cursoNombre,
    required this.evaluaciones,
  });

  factory CourseSyllabus.fromJson(Map<String, dynamic> json) {
    final source = json['evaluaciones'] ?? json['assesments'];
    final evaluacionesList = (source as List<dynamic>? ?? [])
        .map((eval) => EvaluationComponent.fromJson(eval as Map<String, dynamic>))
        .toList();

    final courseId = json['cursoId']?.toString()
        ?? json['course']?['id']?.toString()
        ?? '';
    final courseName = json['cursoNombre'] as String?
        ?? json['course']?['name'] as String?
        ?? '';

    return CourseSyllabus(
      cursoId: courseId,
      cursoNombre: courseName,
      evaluaciones: evaluacionesList,
    );
  }
}
