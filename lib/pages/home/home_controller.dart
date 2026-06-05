import 'package:get/get.dart';
import 'package:ulima_plus/pages/calculadora/calculadora_controller.dart';
import 'package:ulima_plus/services/auth_service.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final RxInt currentTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    ever(currentTabIndex, _onTabChanged);
  }

  void _onTabChanged(int index) {
    if (index == 1) {
      Get.find<CalculadoraController>().reload();
    }
  }

  Future<void> loadDelegateStatus() async {
    await AuthService.to.refreshDelegateStatus();
  }
}
