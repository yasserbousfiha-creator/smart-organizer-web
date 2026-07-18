/// Points awarded for praying on time, per Yasser's rule:
/// - within 30 minutes of the Adhan: 20 points
/// - after that, but before the next prayer's Adhan: 5 points
/// - at or after the next prayer's Adhan: 0 points
int computePrayerPoints({
  required DateTime adhanTime,
  required DateTime nextAdhanTime,
  required DateTime prayedAt,
}) {
  if (!prayedAt.isBefore(nextAdhanTime)) return 0;
  if (prayedAt.isBefore(adhanTime)) return 0;
  final delta = prayedAt.difference(adhanTime);
  return delta <= const Duration(minutes: 30) ? 20 : 5;
}
