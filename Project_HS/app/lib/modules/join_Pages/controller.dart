import 'package:get/get.dart';

class JoinController extends GetxController {
  int currentIndex = 1;

 
  void changeTab(int index) {
    currentIndex = index;
    update();
  }
}
