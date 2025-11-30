import 'package:get/get.dart';

class ReservingController extends GetxController {
  var userBalance = 1500.50.obs;
  int currentIndex = 2;

  void navigateToReserveField(context, dynamic fieldType) {
    Get.toNamed('/match', arguments: fieldType);
  }
  void changeTab(int index) {
    currentIndex = index;
    update();
  }
}
