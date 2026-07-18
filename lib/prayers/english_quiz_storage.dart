import 'dart:math';

import '../portal/portal_client.dart';
import 'english_quiz_bank.dart';
import 'morocco_time.dart';

const int kEnglishQuizDailyCount = 5;
const int kEnglishQuizPointsPerCorrect = 2;
const int kEnglishQuizMaxPoints = kEnglishQuizDailyCount * kEnglishQuizPointsPerCorrect;

class EnglishQuizDay {
  EnglishQuizDay({
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

  factory EnglishQuizDay.fromRow(Map<String, dynamic> row) {
    final ids = (row['question_ids'] as List).map((e) => e as int).toList();
    final rawAnswers = (row['answers'] as Map?) ?? {};
    final answers = {for (final e in rawAnswers.entries) int.parse(e.key): e.value as int};
    return EnglishQuizDay(
      date: DateTime.parse(row['quiz_date'] as String),
      questionIds: ids,
      answers: answers,
      points: row['points'] as int? ?? 0,
    );
  }
}

class EnglishQuizStorage {
  static const table = 'english_quiz_days';

  static String _todayKey() {
    final d = MoroccoTime.now();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static Future<EnglishQuizDay> fetchToday() async {
    final today = _todayKey();
    final existing = await portalClient
        .from(table)
        .select()
        .eq('quiz_date', today)
        .maybeSingle();

    if (existing != null) {
      return EnglishQuizDay.fromRow(existing);
    }

    final ids = kEnglishQuizBank.map((q) => q.id).toList()..shuffle(Random());
    final picked = ids.take(kEnglishQuizDailyCount).toList();

    final created = await portalClient
        .from(table)
        .insert({'quiz_date': today, 'question_ids': picked})
        .select()
        .single();
    return EnglishQuizDay.fromRow(created);
  }

  static Future<EnglishQuizDay> submitAnswer(int questionId, int chosenIndex) async {
    final today = _todayKey();
    final current = await portalClient
        .from(table)
        .select()
        .eq('quiz_date', today)
        .single();

    final day = EnglishQuizDay.fromRow(current);
    final answers = {...day.answers, questionId: chosenIndex};
    final correctCount = answers.entries.where((e) {
      final question = kEnglishQuizBank.firstWhere((q) => q.id == e.key);
      return question.correctIndex == e.value;
    }).length;
    final points = correctCount * kEnglishQuizPointsPerCorrect;

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
    return EnglishQuizDay.fromRow(updated);
  }
}
