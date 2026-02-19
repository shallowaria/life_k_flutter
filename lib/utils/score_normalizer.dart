/// Normalize score from 0-100 to 0-10 scale
double normalizeScore(double score) {
  if (score > 10) {
    return (score / 10).roundToDouble();
  }
  return score;
}
