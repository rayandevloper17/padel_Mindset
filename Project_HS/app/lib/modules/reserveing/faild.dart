import 'package:app/modules/reserveing/avilabale.dart';
import 'package:get/get.dart';

enum Field {
  soccer,
  padel,
}

extension FieldExtension on Field {
  String get displayName {
    switch (this) {
      case Field.soccer:
        return 'CENTRAL SOCCER';
      case Field.padel:
        return 'CENTRAL PADEL';
    }
  }
}

class FieldSchedule {
  final RxString fieldId;
  final RxString fieldName;
  final Rx<Field> fieldType;
  final RxString location;
  final RxList<AvailableDate> availableDates;

  FieldSchedule({
    required String fieldId,
    required String fieldName,
    required Field fieldType,
    required String location,
    required List<AvailableDate> availableDates,
  })  : fieldId = fieldId.obs,
        fieldName = fieldName.obs,
        fieldType = fieldType.obs,
        location = location.obs,
        availableDates = availableDates.obs;
}
