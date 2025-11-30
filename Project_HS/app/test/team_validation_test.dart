import 'package:flutter_test/flutter_test.dart';
import 'package:app/modules/Padel/utils/team_validation.dart';

void main() {
  group('Team index validation', () {
    test('accepts valid indices 0, 1, 2, 3', () {
      expect(isValidTeamIndex(0), isTrue);
      expect(isValidTeamIndex(1), isTrue);
      expect(isValidTeamIndex(2), isTrue);
      expect(isValidTeamIndex(3), isTrue);
    });

    test('rejects invalid indices', () {
      expect(isValidTeamIndex(-1), isFalse);
      expect(isValidTeamIndex(4), isFalse);
      expect(isValidTeamIndex(99), isFalse);
    });

    test('provides standardized error message', () {
      expect(kTeamIndexErrorMessage, equals('Team must be 0, 1, 2, or 3'));
    });
  });
}