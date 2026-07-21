import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/asesoria_model.dart';
import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/api_client.dart';
import 'package:ulima_plus/services/asesoria_service.dart';
import 'package:ulima_plus/services/contacto_service.dart';
import 'package:ulima_plus/services/delegate_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

class DescripCursosController extends GetxController {
  final SeccionService _seccionService = SeccionService();
  final DelegateService _delegateService = DelegateService();
  final AsesoriaService _asesoriaService = AsesoriaService();
  final ContactoService _contactoService = ContactoService();

  RxList<Seccion> secciones = <Seccion>[].obs;
  Rxn<Seccion> seccionActual = Rxn<Seccion>();
  RxList<Anuncio> anuncios = <Anuncio>[].obs;
  RxList<Asesoria> asesorias = <Asesoria>[].obs;
  RxList<ContactoCurso> alumnosContacto = <ContactoCurso>[].obs;
  Rxn<Docente> docenteContacto = Rxn<Docente>();
  RxInt selectedTab = 0.obs;
  RxBool isLoading = false.obs;
  RxnString errorMessage = RxnString();

  Seccion? getSeccionPorId(String id) {
    return secciones.firstWhereOrNull((section) => section.idSeccion == id);
  }

  Future<void> cargarDatosCurso(String idSeccion) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;
      final seccion = await _seccionService.findSectionById(idSeccion);
      if (seccion == null) {
        throw Exception('No existe seccion con id $idSeccion');
      }

      seccionActual.value = seccion;
      secciones.value = [seccion];

      final resolvedSectionId = seccion.idSeccion;
      await Future.wait([
        fetchAnuncios(resolvedSectionId),
        fetchAsesorias(resolvedSectionId),
        fetchContactos(resolvedSectionId),
      ]);
    } catch (e) {
      debugPrint('Error cargando datos del curso: $e');
      errorMessage.value = 'No se pudo cargar la seccion.';
      limpiarDatos();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchAnuncios(String idSeccion) async {
    if (idSeccion.isEmpty) {
      anuncios.clear();
      return;
    }
    try {
      // Se manda el identificador tal cual: puede ser id numérico ("1") o
      // código ("IS-856"). El backend resuelve ambos.
      anuncios.value = await _delegateService.fetchAnuncios(idSeccion);
    } on ApiException catch (e) {
      // Un fallo de anuncios NO debe borrar el resto de la pantalla,
      // por eso se atrapa aquí y no se relanza.
      anuncios.clear();
      debugPrint('Error cargando anuncios: ${e.message}');
    }
  }

  Future<void> fetchAsesorias(String idSeccion) async {
    asesorias.value = await _asesoriaService.fetchAsesorias(idSeccion);
  }

  Future<void> fetchContactos(String idSeccion) async {
    final data = await _contactoService.fetchContactos(idSeccion);
    docenteContacto.value = data['docente'] as Docente?;
    alumnosContacto.value = List<ContactoCurso>.from(data['alumnos'] ?? []);
  }

  void limpiarDatos() {
    secciones.clear();
    seccionActual.value = null;
    anuncios.clear();
    asesorias.clear();
    alumnosContacto.clear();
    docenteContacto.value = null;
  }
}
