import 'package:app/modules/join_Pages/services/reservation_service.dart';
import 'package:get/get.dart';

class ReservationController extends GetxController {
  final ReservationService service;

  ReservationController(this.service);

  var reservation = {}.obs;
  var isLoading = false.obs;
  var errorMessage = "".obs;

  Future<void> getReservationByCode(String code) async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final data = await service.fetchReservationByCode(code);
      reservation.value = data;
    } catch (e) {
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
