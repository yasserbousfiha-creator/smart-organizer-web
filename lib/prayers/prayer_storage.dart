import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal/portal_client.dart';
import 'morocco_time.dart';
import 'prayer_times_service.dart';

const List<String> kPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const int kChallengeGoalPoints = 1000;
const int kChallengeLengthDays = 15;

class PrayerDay {
  PrayerDay({
    required this.date,
    required this.status,
    required this.points,
    this.quranPage,
    this.quranDone = false,
    this.quranPoints = 0,
    this.sabahDone = false,
    this.sabahPoints = 0,
    this.masaaDone = false,
    this.masaaPoints = 0,
  });

  final DateTime date;
  final Map<String, bool> status;
  final Map<String, int> points;

  /// The page of the Quran (1-604) assigned for this day's reading — rotates
  /// forward every day (not tied to the 15-day challenge cycle) so the whole
  /// Mushaf gets read gradually over time.
  final int? quranPage;
  final bool quranDone;
  final int quranPoints;
  final bool sabahDone;
  final int sabahPoints;
  final bool masaaDone;
  final int masaaPoints;

  bool get allDone => kPrayerNames.every((p) => status[p] == true);
  int get totalPoints =>
      points.values.fold(0, (a, b) => a + b) + quranPoints + sabahPoints + masaaPoints;

  factory PrayerDay.fromRow(Map<String, dynamic> row) {
    return PrayerDay(
      date: DateTime.parse(row['prayer_date'] as String),
      status: {for (final p in kPrayerNames) p: row[p] == true},
      points: {for (final p in kPrayerNames) p: (row['${p}_points'] as int?) ?? 0},
      quranPage: row['quran_page'] as int?,
      quranDone: row['quran_done'] == true,
      quranPoints: row['quran_points'] as int? ?? 0,
      sabahDone: row['sabah_done'] == true,
      sabahPoints: row['sabah_points'] as int? ?? 0,
      masaaDone: row['masaa_done'] == true,
      masaaPoints: row['masaa_points'] as int? ?? 0,
    );
  }

  factory PrayerDay.empty(DateTime date) {
    return PrayerDay(
      date: date,
      status: {for (final p in kPrayerNames) p: false},
      points: {for (final p in kPrayerNames) p: 0},
    );
  }
}

class PrayerMessage {
  PrayerMessage({required this.id, required this.text, required this.createdAt});

  final String id;
  final String text;
  final DateTime createdAt;

  factory PrayerMessage.fromRow(Map<String, dynamic> row) {
    return PrayerMessage(
      id: row['id'] as String,
      text: row['message'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

/// A 15-day points challenge cycle — either the currently active one (live
/// totalPoints, computed on the fly) or a finished one pulled from history.
class PrayerChallengeRecord {
  PrayerChallengeRecord({
    required this.startDate,
    required this.endDate,
    required this.totalPoints,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalPoints;

  bool get rewardReached => totalPoints >= kChallengeGoalPoints;

  int get daysRemaining {
    final today = MoroccoTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final remaining = endDate.difference(todayDate).inDays + 1;
    return remaining < 0 ? 0 : remaining;
  }
}

class PrayerStorage {
  static const table = 'prayers';
  static const settingsTable = 'prayer_settings';
  static const challengesTable = 'prayer_challenges';

  static String _todayKey() => _dateOnly(MoroccoTime.now());

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static DateTime _parseDateOnly(String s) {
    final d = DateTime.parse(s);
    return DateTime(d.year, d.month, d.day);
  }

  static const _quranPageEpoch = 604;

  /// A page number (1-604) that changes every calendar day, cycling through
  /// the whole Mushaf — deterministic so it's the same for everyone reading
  /// on the same day without needing to store any extra "which day" counter.
  static int _quranPageFor(DateTime date) {
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = DateTime(date.year, date.month, date.day).difference(epoch).inDays;
    final normalized = daysSinceEpoch % _quranPageEpoch;
    return (normalized < 0 ? normalized + _quranPageEpoch : normalized) + 1;
  }

  static Future<PrayerDay> fetchToday() async {
    final today = MoroccoTime.now();
    final todayKey = _todayKey();
    final existing = await portalClient
        .from(table)
        .select()
        .eq('prayer_date', todayKey)
        .maybeSingle();

    if (existing != null) {
      return PrayerDay.fromRow(existing);
    }

    final created = await portalClient
        .from(table)
        .insert({'prayer_date': todayKey, 'quran_page': _quranPageFor(today)})
        .select()
        .single();
    return PrayerDay.fromRow(created);
  }

  /// Fetches (or creates) the prayer row for an arbitrary date — used by the
  /// hidden parent panel's "yesterday" tab so a prayer forgotten right before
  /// midnight can still be logged after the day has rolled over.
  static Future<PrayerDay> fetchForDate(DateTime date) async {
    final key = _dateOnly(date);
    final existing = await portalClient
        .from(table)
        .select()
        .eq('prayer_date', key)
        .maybeSingle();

    if (existing != null) {
      return PrayerDay.fromRow(existing);
    }

    final created = await portalClient
        .from(table)
        .insert({'prayer_date': key, 'quran_page': _quranPageFor(date)})
        .select()
        .single();
    return PrayerDay.fromRow(created);
  }

  static Future<PrayerDay> setPrayer(String prayerName, bool value, {int points = 0}) {
    return setPrayerForDate(MoroccoTime.now(), prayerName, value, points: points);
  }

  static Future<PrayerDay> setPrayerForDate(
    DateTime date,
    String prayerName,
    bool value, {
    int points = 0,
  }) async {
    final key = _dateOnly(date);
    final updated = await portalClient
        .from(table)
        .update({
          prayerName: value,
          '${prayerName}_points': value ? points : 0,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('prayer_date', key)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  static Future<PrayerDay> setQuranDone() async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({
          'quran_done': true,
          'quran_points': 10,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  static Future<PrayerDay> setSabahDone() async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({
          'sabah_done': true,
          'sabah_points': 10,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  static Future<PrayerDay> setMasaaDone() async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({
          'masaa_done': true,
          'masaa_points': 10,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  static const bonusTable = 'prayer_bonus_points';

  /// Free-form points a parent can grant for something outside the prayer
  /// checklist (e.g. a good deed that day) — kept as a ledger, separate from
  /// per-prayer points, so multiple bonuses can stack in the same day.
  static Future<void> addBonusPoints(int amount, String? note) async {
    await portalClient.from(bonusTable).insert({
      'bonus_date': _todayKey(),
      'amount': amount,
      'note': note,
    });
  }

  static RealtimeChannel subscribeToday(void Function(PrayerDay day) onChange) {
    final today = _todayKey();
    return portalClient
        .channel('prayers-$today')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'prayer_date',
            value: today,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              onChange(PrayerDay.fromRow(row));
            }
          },
        )
        .subscribe();
  }

  static const messagesTable = 'prayer_messages';

  static DateTime _messagesCycleStart() {
    final now = MoroccoTime.now();
    final todayAt5 = MoroccoTime.date(now.year, now.month, now.day, 5);
    return now.isBefore(todayAt5) ? todayAt5.subtract(const Duration(days: 1)) : todayAt5;
  }

  static Future<List<PrayerMessage>> fetchMessages() async {
    final cycleStart = _messagesCycleStart();
    await portalClient
        .from(messagesTable)
        .delete()
        .lt('created_at', cycleStart.toIso8601String());

    final rows = await portalClient.from(messagesTable).select().order('created_at', ascending: true);
    return rows.map((r) => PrayerMessage.fromRow(r)).toList();
  }

  static Future<void> sendMessage(String text) async {
    await portalClient.from(messagesTable).insert({'message': text});
  }

  static RealtimeChannel subscribeMessages(void Function() onChange) {
    return portalClient
        .channel('prayer-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: messagesTable,
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  static Future<int> _sumPointsBetween(DateTime start, DateTime end) async {
    final rows = await portalClient
        .from(table)
        .select(
          'fajr_points,dhuhr_points,asr_points,maghrib_points,isha_points,'
          'quran_points,sabah_points,masaa_points',
        )
        .gte('prayer_date', _dateOnly(start))
        .lte('prayer_date', _dateOnly(end));
    var total = 0;
    for (final row in rows) {
      for (final p in kPrayerNames) {
        total += (row['${p}_points'] as int?) ?? 0;
      }
      total += (row['quran_points'] as int?) ?? 0;
      total += (row['sabah_points'] as int?) ?? 0;
      total += (row['masaa_points'] as int?) ?? 0;
    }

    final quizRows = await portalClient
        .from('english_quiz_days')
        .select('points')
        .gte('quiz_date', _dateOnly(start))
        .lte('quiz_date', _dateOnly(end));
    for (final row in quizRows) {
      total += (row['points'] as int?) ?? 0;
    }

    final religiousQuizRows = await portalClient
        .from('religious_quiz_days')
        .select('points')
        .gte('quiz_date', _dateOnly(start))
        .lte('quiz_date', _dateOnly(end));
    for (final row in religiousQuizRows) {
      total += (row['points'] as int?) ?? 0;
    }

    final bonusRows = await portalClient
        .from(bonusTable)
        .select('amount')
        .gte('bonus_date', _dateOnly(start))
        .lte('bonus_date', _dateOnly(end));
    for (final row in bonusRows) {
      total += (row['amount'] as int?) ?? 0;
    }

    return total;
  }

  /// The date whose Fajr is the next one to come — today's, if it hasn't
  /// happened yet, otherwise tomorrow's. Used as the very first challenge's
  /// start date so it begins clean at the next prayer instead of retroactively
  /// counting whatever was already prayed earlier today.
  static Future<DateTime> _nextFajrStartDate() async {
    final now = MoroccoTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final times = await PrayerTimesService.timingsFor(now);
    final fajr = times?['fajr'];
    if (fajr != null && now.isBefore(fajr)) return today;
    return today.add(const Duration(days: 1));
  }

  /// Returns the currently active 15-day challenge, rolling over (and
  /// archiving into [challengesTable]) any cycle(s) that have already ended.
  static Future<PrayerChallengeRecord> fetchCurrentChallenge() async {
    var settings = await portalClient
        .from(settingsTable)
        .select()
        .eq('id', 1)
        .maybeSingle();
    settings ??= await portalClient
        .from(settingsTable)
        .insert({'id': 1, 'current_challenge_start': _dateOnly(await _nextFajrStartDate())})
        .select()
        .single();

    var start = _parseDateOnly(settings['current_challenge_start'] as String);
    var end = start.add(const Duration(days: kChallengeLengthDays - 1));
    final today = MoroccoTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    while (todayDate.isAfter(end)) {
      final total = await _sumPointsBetween(start, end);
      await portalClient.from(challengesTable).insert({
        'start_date': _dateOnly(start),
        'end_date': _dateOnly(end),
        'total_points': total,
        'reward_reached': total >= kChallengeGoalPoints,
      });
      start = end.add(const Duration(days: 1));
      end = start.add(const Duration(days: kChallengeLengthDays - 1));
      await portalClient
          .from(settingsTable)
          .update({'current_challenge_start': _dateOnly(start)})
          .eq('id', 1);
    }

    final totalPoints = await _sumPointsBetween(start, end);
    return PrayerChallengeRecord(startDate: start, endDate: end, totalPoints: totalPoints);
  }

  static Future<List<PrayerChallengeRecord>> fetchChallengeHistory() async {
    final rows = await portalClient
        .from(challengesTable)
        .select()
        .order('start_date', ascending: false);
    return rows
        .map((r) => PrayerChallengeRecord(
              startDate: _parseDateOnly(r['start_date'] as String),
              endDate: _parseDateOnly(r['end_date'] as String),
              totalPoints: r['total_points'] as int,
            ))
        .toList();
  }

  static Future<String?> fetchRewardChoice() async {
    final row = await portalClient
        .from(settingsTable)
        .select('reward_choice')
        .eq('id', 1)
        .maybeSingle();
    return row?['reward_choice'] as String?;
  }

  static Future<void> setRewardChoice(String choice) async {
    await portalClient.from(settingsTable).update({'reward_choice': choice}).eq('id', 1);
  }
}
