import 'package:app/modules/reserveing/faild.dart';
import 'package:flutter/src/material/theme_data.dart';
import 'package:get/get.dart';

class FieldReservationController extends GetxController {
  final RxList<FieldSchedule> fieldSchedules = <FieldSchedule>[].obs;
  final Rxn<FieldSchedule> selectedField = Rxn<FieldSchedule>();
  final RxString errorMessage = ''.obs;
  final RxBool isLoading = false.obs;
  
  // Make these non-nullable with default values to prevent null issues
  final RxString selectedDate = ''.obs;
  final RxString selectedTimeSlotId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize with some default data or load initial data
    _initializeDefaultData();
  }

  void _initializeDefaultData() {
    // You can initialize with empty data or load from API
    // This prevents null reference errors
    fieldSchedules.value = [];
    selectedField.value = null;
    selectedDate.value = '';
    selectedTimeSlotId.value = '';
    errorMessage.value = '';
  }

  void setFieldSchedules(List<FieldSchedule> schedules) {
    try {
      fieldSchedules.value = schedules;
      if (schedules.isNotEmpty) {
        selectedField.value = schedules[0];
      } else {
        selectedField.value = null;
      }
      clearError();
    } catch (e) {
      showError('Error setting field schedules: $e');
    }
  }

  void setSelectedDate(String date) {
    selectedDate.value = date;
  }

  void setSelectedTimeSlot(String timeSlotId) {
    selectedTimeSlotId.value = timeSlotId;
  }

  void loadFieldSchedules(String fieldType) async {
    try {
      isLoading.value = true;
      clearError();

      // TODO: Replace this block with your real API call
      await Future.delayed(const Duration(seconds: 2)); // simulate API delay

      // Simulate mock field data (replace with real data later)
      final mockSchedules = [
        FieldSchedule(
          fieldId: '1',
          fieldName: 'Terrain Central',
          fieldType: Field.soccer,
          location: 'Algiers',
          availableDates: [], // fill with actual available dates
        ),
        // Add more mock data for testing
        FieldSchedule(
          fieldId: '2',
          fieldName: 'Terrain Nord',
          fieldType: Field.soccer,
          location: 'Oran',
          availableDates: [],
        ),
      ];

      setFieldSchedules(mockSchedules);

    } catch (e) {
      showError('Failed to load field schedules: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> makeReservation([Map<String, dynamic>? request]) async {
    try {
      isLoading.value = true;
      clearError();

      // Validate required fields
      if (selectedField.value == null) {
        showError('Please select a field');
        return;
      }

      if (selectedDate.value.isEmpty) {
        showError('Please select a date');
        return;
      }

      if (selectedTimeSlotId.value.isEmpty) {
        showError('Please select a time slot');
        return;
      }

      // Simulate backend call
      await Future.delayed(const Duration(seconds: 2));
      
      // Show success message
      Get.snackbar(
        "Succès", 
        "Réservation confirmée !",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.primaryColor,
        colorText: Get.theme.onPrimary,
      );

      // Reset form after successful reservation
      _resetReservationForm();

    } catch (e) {
      showError("Une erreur s'est produite lors de la réservation: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _resetReservationForm() {
    selectedDate.value = '';
    selectedTimeSlotId.value = '';
    // Don't reset selectedField as user might want to make another reservation for same field
  }

  void showError(String message) {
    errorMessage.value = message;
    // Also show as snackbar for better UX
    Get.snackbar(
      'Erreur',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
    );
  }

  void clearError() {
    errorMessage.value = '';
  }

  // Getter to check if reservation can be made
  bool get canMakeReservation => 
      selectedField.value != null && 
      selectedDate.value.isNotEmpty && 
      selectedTimeSlotId.value.isNotEmpty &&
      !isLoading.value;

  // Helper method to get selected field name safely
  String get selectedFieldName {
    if (selectedField.value == null) return 'No field selected';
    return selectedField.value!.fieldName as String;
  }

  @override
  void onClose() {
    // Clean up resources
    fieldSchedules.close();
    selectedField.close();
    errorMessage.close();
    selectedDate.close();
    selectedTimeSlotId.close();
    isLoading.close();
    super.onClose();
  }
}

extension on ThemeData {
  get onPrimary => null;
}