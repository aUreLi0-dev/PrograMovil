import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/estadisticas_seccion_model.dart';
import 'package:ulima_plus/services/anuncio_service.dart';
import 'package:ulima_plus/services/auth_service.dart';

class DelegadoAnunciosController extends GetxController {
  final TextEditingController titulo = TextEditingController();
  final TextEditingController mensaje = TextEditingController();

  String nombreCurso = 'Curso no especificado';
  String idSeccion = '';
  String codigoSeccion = '';
  String rol = 'Delegado';
  int alumnosMatriculados = 0;

  // Reactivo para las estadísticas del salón
  final Rxn<EstadisticasSeccion> estadisticas = Rxn<EstadisticasSeccion>();

  void cargarCurso(Map<String, dynamic> args) {
    // 1. Extraer los datos enviados desde la pantalla anterior mediante la navegación
    nombreCurso = args['curso']?.toString() ?? nombreCurso;
    idSeccion = args['idSeccion']?.toString() ?? idSeccion;
    codigoSeccion = args['codigoSeccion']?.toString() ?? idSeccion;
    rol = args['rol']?.toString() ?? rol;
    alumnosMatriculados = (args['alumnos'] as num?)?.toInt() ?? 0;
    
    // Limpiar los campos de entrada de anuncios previos
    titulo.clear();
    mensaje.clear();

    // 2. Cargar estadísticas estáticas simuladas del salón según la sección para la gráfica de barras
    if (codigoSeccion.contains('854') || nombreCurso.toLowerCase().contains('móvil') || nombreCurso.toLowerCase().contains('movil')) {
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 14.5,
        porcentajeAprobados: 74,
        rango0_10: 2,
        rango11_13: 5,
        rango14_16: 12,
        rango17_20: 8,
      );
    } else if (codigoSeccion.contains('856') || nombreCurso.toLowerCase().contains('software')) {
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 15.8,
        porcentajeAprobados: 85,
        rango0_10: 1,
        rango11_13: 3,
        rango14_16: 15,
        rango17_20: 9,
      );
    } else {
      // Valores por defecto si se entra a otra sección
      estadisticas.value = EstadisticasSeccion(
        promedioGeneral: 15.0,
        porcentajeAprobados: 80,
        rango0_10: 2,
        rango11_13: 4,
        rango14_16: 14,
        rango17_20: 7,
      );
    }
  }

  void publicarAnuncio() async {
    // Paso 1: Validar que los campos de texto no estén vacíos
    if (titulo.text.trim().isEmpty || mensaje.text.trim().isEmpty) {
      Get.snackbar(
        'Campos vacíos',
        'Por favor, ingrese un título y mensaje para el anuncio.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Paso 2: Obtener los datos del usuario logueado en la aplicación
    final user = AuthService.to.currentUser;
    if (user == null) {
      Get.snackbar(
        'Error',
        'No se pudo identificar la sesión del usuario.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    // Paso 3: Formatear la fecha actual del sistema
    final ahora = DateTime.now();
    final fechaFormateada = '${ahora.day}/${ahora.month}/${ahora.year}';

    // Paso 4: Crear el objeto Anuncio usando el modelo, asignándole un ID único basado en el tiempo
    final nuevoAnuncio = Anuncio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idSeccion: idSeccion,
      titulo: titulo.text.trim(),
      mensaje: mensaje.text.trim(),
      fecha: fechaFormateada,
      autorCode: user.code,
      autorName: user.fullName,
      autorRole: rol,
    );

    // Paso 5: Llamar al servicio asíncrono para guardar el anuncio localmente
    final response = await AnuncioService().addAnuncio(nuevoAnuncio);

    // Paso 6: Si se guardó correctamente, notificar al usuario, limpiar formulario y regresar
    if (response.success) {
      ScaffoldMessenger.of(Get.context!).showSnackBar(
        const SnackBar(
          content: Text('Anuncio publicado correctamente.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
      
      // Limpiar inputs del formulario
      titulo.clear();
      mensaje.clear();

      // Regresar a la pantalla anterior del listado de cursos
      Get.back();
    } else {
      // Notificar si hubo un error al guardar
      Get.snackbar(
        'Error',
        'No se pudo publicar el anuncio: ${response.message}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  void onClose() {
    titulo.dispose();
    mensaje.dispose();
    super.onClose();
  }
}


