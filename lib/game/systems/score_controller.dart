class ScoreController {
  int total = 0;

  void addHit(int base, {int multiplier = 1}) {
    total += base * multiplier;
  }

  void addBurst(int bonus, {int multiplier = 1}) {
    total += bonus * multiplier;
  }

  void reset() => total = 0;
}
