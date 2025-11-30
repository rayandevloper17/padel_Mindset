import 'package:get/get.dart';

class SettingsController extends GetxController {
  int currentIndex = 3;

 
  void changeTab(int index) {
    currentIndex = index;
    update();
  }
}
