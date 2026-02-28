/// Normalize score to 0-10 scale.
/// Scores above 10 are assumed to be on a 0-100 scale and are divided by 10.
/// Result is always clamped to [0.0, 10.0].
double normalizeScore(double score) {
  if (score > 10) return (score / 10).clamp(0.0, 10.0);
  return score.clamp(0.0, 10.0);
}
