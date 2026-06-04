import '../../models/anuncio_model.dart';
import '../../services/anuncio_service.dart';
import '../../services/auth_service.dart';

class DelegadoAnunciosController {
  final AnuncioService _service = AnuncioService();

  List<Anuncio> anuncios = [];
  bool cargando = true;

  Future<void> cargarAnuncios(String idSeccion, Function actualizarVista) async {
    try {
      anuncios = await _service.fetchAnuncios(idSeccion);
    } catch (e) {
      print("Error cargando datos: $e");
    } finally {
      cargando = false;
      actualizarVista();
    }
  }

  void eliminarAnuncioLocal(int index, Function actualizarVista) {
    anuncios.removeAt(index);
    actualizarVista();
  }

  void agregarAnuncioLocal(
      String titulo, String mensaje, String idSeccion,
      Function actualizarVista) {
    final currentUser = AuthService.to.currentUser;
    final code = currentUser?.code ?? '20230000';
    final name = currentUser?.fullName ?? code;
    final role = AuthService.to.role;

    final nuevoAnuncio = Anuncio(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idSeccion: idSeccion,
      titulo: titulo,
      mensaje: mensaje,
      fecha: "31-05-2026",
      autorCode: code,
      autorName: name,
      autorRole: role,
    );

    anuncios.insert(0, nuevoAnuncio);
    actualizarVista();
  }
}
