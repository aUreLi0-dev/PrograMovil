import 'package:get/get.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();
  final RxInt currentTabIndex = 0.obs;
}
