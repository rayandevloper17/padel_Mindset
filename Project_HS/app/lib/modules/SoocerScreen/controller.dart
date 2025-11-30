import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class Scoorcontroller extends GetxController {
  int currentIndex = 2;

  void changeTab(int index) {
    if (index != currentIndex) {
      currentIndex = index;
      update(); // notify GetBuilder to rebuild
    }
  }
}
