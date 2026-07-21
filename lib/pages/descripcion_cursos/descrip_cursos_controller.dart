import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:ulima_plus/models/anuncio_model.dart';
import 'package:ulima_plus/models/asesoria_model.dart';
import 'package:ulima_plus/models/contacto_model.dart';
import 'package:ulima_plus/models/docente_model.dart';
import 'package:ulima_plus/models/seccion_model.dart';
import 'package:ulima_plus/services/anuncio_service.dart';
import 'package:ulima_plus/services/asesoria_service.dart';
import 'package:ulima_plus/services/contacto_service.dart';
import 'package:ulima_plus/services/seccion_service.dart';

class DescripCursosController extends GetxController {
  final SeccionService _seccionService = SeccionService();
  final AnuncioService _anuncioService = AnuncioService();
  final AsesoriaService _asesoriaService = AsesoriaService();
  final ContactoService _contactoService = ContactoService();

  final RxList<Seccion> secciones = <Seccion>[].obs;
  final Rxn<Seccion> seccionActual = Rxn<Seccion>();
  final RxList<Anuncio> anuncios = <Anuncio>[].obs;
  final RxList<Asesoria> asesorias = <Asesoria>[].obs;
  final RxList<ContactoCurso> alumnosContacto = <ContactoCurso>[].obs;
  final Rxn<Docente> docenteContacto = Rxn<Docente>();
  final RxInt selectedTab = 0.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  Seccion? getSeccionPorId(String id) {
    return secciones.firstWhereOrNull((section) => section.idSeccion == id);
  }

  Future<void> cargarDatosCurso(String idSeccion) async {
    try {
      isLoading.value = true;
      errorMessage.value = null;

      final seccion = await _resolveSection(idSeccion);
      final resolvedSectionId = seccion.idSeccion;

      _setCurrentSection(seccion);
      await _loadSectionTabs(resolvedSectionId);
    } catch (e) {
      debugPrint('Error cargando datos del curso: $e');
      errorMessage.value = 'No se pudo cargar la seccion.';
      limpiarDatos();
    } finally {
      isLoading.value = false;
    }
  }

  Future<Seccion> _resolveSection(String idSeccion) async {
    final seccion = await _seccionService.findSectionById(idSeccion);
    if (seccion == null) {
      throw Exception('No existe seccion con id $idSeccion');
    }
    return seccion;
  }

  void _setCurrentSection(Seccion seccion) {
    seccionActual.value = seccion;
    secciones.value = [seccion];
  }

  Future<void> _loadSectionTabs(String idSeccion) async {
    await Future.wait([
      fetchAnuncios(idSeccion),
      fetchAsesorias(idSeccion),
      fetchContactos(idSeccion),
    ]);
  }

  Future<void> fetchAnuncios(String idSeccion) async {
    final response = await _anuncioService.fetchAnuncios(idSeccion);
    if (response.success && response.data != null) {
      anuncios.value = response.data!;
    } else {
      anuncios.clear();
    }
  }

  Future<void> fetchAsesorias(String idSeccion) async {
    asesorias.value = await _asesoriaService.fetchAsesorias(idSeccion);
  }

  Future<void> fetchContactos(String idSeccion) async {
    final data = await _contactoService.fetchContactos(idSeccion);
    docenteContacto.value = data.docente;
    alumnosContacto.value = data.alumnos;
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
