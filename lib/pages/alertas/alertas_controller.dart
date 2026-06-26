import 'package:get/get.dart';
import 'package:ulima_plus/models/alerta_model.dart';
import 'package:ulima_plus/services/alertas_service.dart';

class AlertasController extends GetxController {
  RxList<AlertaModel> get alertas => AlertasService.to.alertas;
  RxBool get cargando => AlertasService.to.cargando;
  int get sinLeer => AlertasService.to.sinLeer;

  Future<void> generarAlertas() => AlertasService.to.generarAlertas();
  void marcarComoLeido(String id) => AlertasService.to.marcarComoLeido(id);
  void marcarTodasComoLeidas() => AlertasService.to.marcarTodasComoLeidas();
}
