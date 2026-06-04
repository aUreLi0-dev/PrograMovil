import 'package:get/get.dart';

class CursoSeccion {
  final String id;
  final String nombre;
  final String ciclo;
  final String codigoSeccion;
  final RxList<Map<String, dynamic>> notas;

  CursoSeccion({
    required this.id,
    required this.nombre,
    required this.ciclo,
    required this.codigoSeccion,
    required this.notas,
  });
}
