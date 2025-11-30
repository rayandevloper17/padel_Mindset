// field_reservation_event.dart

abstract class FieldReservationEvent {}

class LoadFieldSchedules extends FieldReservationEvent {
  final String fieldType;

  LoadFieldSchedules({required this.fieldType});
}
