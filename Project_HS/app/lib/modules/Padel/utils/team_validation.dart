const String kTeamIndexErrorMessage = 'Team must be 0, 1, 2, or 3';

bool isValidTeamIndex(int index) {
  return index >= 0 && index <= 3;
}