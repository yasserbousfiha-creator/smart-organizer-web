import '../portal/portal_client.dart';
import 'morocco_time.dart';
import 'prayer_storage.dart';
import 'religious_quiz_bank.dart';

const int kReligiousQuizDailyCount = 5;
const int kReligiousQuizPointsPerCorrect = 2;
const int kReligiousQuizMaxPoints = kReligiousQuizDailyCount * kReligiousQuizPointsPerCorrect;

class ReligiousQuizDay {
  ReligiousQuizDay({
    required this.date,
    required this.questionIds,
    required this.answers,
    required this.points,
  });

  final DateTime date;
  final List<int> questionIds;
  final Map<int, int> answers;
  final int points;

  bool get isComplete => questionIds.every(answers.containsKey);

  factory ReligiousQuizDay.fromRow(Map<String, dynamic> row) {
    final ids = (row['question_ids'] as List).map((e) => e as int).toList();
    final rawAnswers = (row['answers'] as Map?) ?? {};
    final answers = {for (final e in rawAnswers.entries) int.parse(e.key): e.value as int};
    return ReligiousQuizDay(
      date: DateTime.parse(row['quiz_date'] as String),
      questionIds: ids,
      answers: answers,
      points: row['points'] as int? ?? 0,
    );
  }
}

class ReligiousQuizStorage {
  static const table = 'religious_quiz_days';

  static String _todayKey() {
    final d = MoroccoTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Which day (1-15) of the current prayer challenge cycle "today" falls
  /// on — the religious quiz reuses the same 15-day cycle as the points
  /// challenge so its curated question set changes daily and repeats every
  /// 15 days in sync with a new challenge starting.
  static Future<int> _cycleDayIndex() async {
    final challenge = await PrayerStorage.fetchCurrentChallenge();
    final now = MoroccoTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final offset = today.difference(challenge.startDate).inDays % kChallengeLengthDays;
    final normalized = offset < 0 ? offset + kChallengeLengthDays : offset;
    return normalized + 1;
  }

  static Future<ReligiousQuizDay> fetchToday() async {
    final today = _todayKey();
    final existing = await portalClient
        .from(table)
        .select()
        .eq('quiz_date', today)
        .maybeSingle();

    if (existing != null) {
      return ReligiousQuizDay.fromRow(existing);
    }

    final dayIndex = await _cycleDayIndex();
    final picked = kReligiousQuizBank
        .where((q) => q.dayIndex == dayIndex)
        .map((q) => q.id)
        .toList();

    final created = await portalClient
        .from(table)
        .insert({'quiz_date': today, 'question_ids': picked})
        .select()
        .single();
    return ReligiousQuizDay.fromRow(created);
  }

  static Future<ReligiousQuizDay> submitAnswer(int questionId, int chosenIndex) async {
    final today = _todayKey();
    final current = await portalClient
        .from(table)
        .select()
        .eq('quiz_date', today)
        .single();

    final day = ReligiousQuizDay.fromRow(current);
    final answers = {...day.answers, questionId: chosenIndex};
    final correctCount = answers.entries.where((e) {
      final question = kReligiousQuizBank.firstWhere((q) => q.id == e.key);
      return question.correctIndex == e.value;
    }).length;
    final points = correctCount * kReligiousQuizPointsPerCorrect;

    final updated = await portalClient
        .from(table)
        .update({
          'answers': {for (final e in answers.entries) e.key.toString(): e.value},
          'points': points,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('quiz_date', today)
        .select()
        .single();
    return ReligiousQuizDay.fromRow(updated);
  }
}
