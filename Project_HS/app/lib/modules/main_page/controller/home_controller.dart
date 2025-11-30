import 'package:get/get.dart';

class HomeController extends GetxController {
  int currentIndex = 2;

  void changeTab(int index) {
    currentIndex = index;
    update();
  }
}
