// alumno matriculado en una seccion
class Enrollment{
  final String id;
  final String studentCode;
  final String idCurso;
  final String idSeccion;

  Enrollment({
    required this.id,
    required this.studentCode,
    required this.idCurso,
    required this.idSeccion,
  });

  // construye desde el json de enrollments
  factory Enrollment.fromJson(Map<String,dynamic> json){
    return Enrollment(
      id:json['id'].toString(),
      studentCode:json['studentCode'].toString(),
      idCurso:json['idCurso'].toString(),
      idSeccion:json['idSeccion'].toString(),
    );
  }
}
