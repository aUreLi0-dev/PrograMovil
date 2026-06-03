import '../../models/anuncio_model.dart';
import '../../services/anuncio_service.dart';

class DelegadoAnunciosController {
  final AnuncioService _service = AnuncioService();
  
  List<Anuncio> anuncios = [];
  bool cargando = true;

  Future<void> cargarAnuncios(String idSeccion, Function actualizarVista) async {
    try {
      anuncios = await _service.fetchAnuncios(idSeccion);
    } catch (e) {
      print("Error cargando datos: \$e");
    } finally {
      cargando = false;
      actualizarVista(); 
    }
  }

  void eliminarAnuncioLocal(int index, Function actualizarVista) {
    anuncios.removeAt(index);
    actualizarVista(); 
  }

  void agregarAnuncioLocal(String titulo, String mensaje, String idSeccion, Function actualizarVista) {
    final autorPorDefecto = anuncios.isNotEmpty ? anuncios.first.autor : null;
    final autorCodePorDefecto = anuncios.isNotEmpty ? anuncios.first.autorCode : "20230000";

    final nuevoAnuncio = Anuncio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idSeccion: idSeccion,
      titulo: titulo,
      mensaje: mensaje,
      fecha: "31-05-2026", 
      autorCode: autorCodePorDefecto,
      autor: autorPorDefecto!, 
    );

    anuncios.insert(0, nuevoAnuncio);
    actualizarVista();
  }
}