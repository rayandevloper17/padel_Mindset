import 'dart:async';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationController extends GetxController {
  final RxBool isDetecting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxString locationLabel = ''.obs;
  final Rx<Position?> currentPosition = Rx<Position?>(null);
  final RxBool showSuccessPulse = false.obs;

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void onInit() {
    super.onInit();
    _loadSavedLocation();
  }

  Future<void> _loadSavedLocation() async {
    final savedLabel = await _storage.read(key: 'user_location_label');
    final savedLat = await _storage.read(key: 'user_location_lat');
    final savedLon = await _storage.read(key: 'user_location_lon');
    if (savedLabel != null && savedLat != null && savedLon != null) {
      locationLabel.value = savedLabel;
      try {
        currentPosition.value = Position(
          latitude: double.parse(savedLat),
          longitude: double.parse(savedLon),
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      } catch (_) {}
    }
  }

  Future<bool> _ensurePermissions() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      errorMessage.value = 'Location services are disabled';
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        errorMessage.value = 'Location permissions are denied';
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      errorMessage.value = 'Location permissions permanently denied';
      return false;
    }
    return true;
  }

  Future<void> selectLocation() async {
    if (isDetecting.value) return;
    isDetecting.value = true;
    errorMessage.value = '';
    try {
      final ok = await _ensurePermissions();
      if (!ok) {
        isDetecting.value = false;
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = pos;

      final label = await _labelFromPosition(pos);
      locationLabel.value = label;

      await _storage.write(
        key: 'user_location_label',
        value: label,
      );
      await _storage.write(
        key: 'user_location_lat',
        value: pos.latitude.toString(),
      );
      await _storage.write(
        key: 'user_location_lon',
        value: pos.longitude.toString(),
      );

      // Success feedback pulse
      showSuccessPulse.value = true;
      Future.delayed(const Duration(milliseconds: 800), () {
        showSuccessPulse.value = false;
      });
    } catch (e) {
      errorMessage.value = 'Failed to detect location';
    } finally {
      isDetecting.value = false;
    }
  }

  Future<String> _labelFromPosition(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final pm = placemarks.first;
        final locality = pm.locality?.isNotEmpty == true ? pm.locality : null;
        final admin = pm.administrativeArea?.isNotEmpty == true
            ? pm.administrativeArea
            : null;
        final country = pm.country?.isNotEmpty == true ? pm.country : null;
        final parts = [locality, admin, country].whereType<String>().toList();
        if (parts.isNotEmpty) {
          return parts.join(', ');
        }
      }
    } catch (_) {}
    return '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
  }
}