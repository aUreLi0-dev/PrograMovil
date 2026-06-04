import 'package:get/get.dart';
import 'package:ulima_plus/services/auth_service.dart';
import 'package:ulima_plus/services/section_representative_service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final RxInt currentTabIndex = 0.obs;
  final RxBool mostrarDelegado = false.obs;

  final SectionRepresentativeService _representativeService =
      SectionRepresentativeService();

  @override
  void onInit() {
    super.onInit();
    cargarAccesoDelegado();
  }

  Future<void> cargarAccesoDelegado() async {
    final user = AuthService.to.currentUser;

    if (user == null) {
      mostrarDelegado.value = false;
      return;
    }

    final tieneSeccionDelegada = await _representativeService
        .isRepresentativeInAnySection(user.code);

    mostrarDelegado.value = tieneSeccionDelegada;

    if (!tieneSeccionDelegada && currentTabIndex.value > 3) {
      currentTabIndex.value = 3;
    }
  }
}
