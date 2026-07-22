import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'religious_quiz_bank.dart';
import 'religious_quiz_storage.dart';

class ReligiousQuizScreen extends StatefulWidget {
  const ReligiousQuizScreen({super.key});

  @override
  State<ReligiousQuizScreen> createState() => _ReligiousQuizScreenState();
}

class _ReligiousQuizScreenState extends State<ReligiousQuizScreen> {
  ReligiousQuizDay? _day;
  bool _loading = true;
  String? _error;
  int? _submittingQuestionId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await ReligiousQuizStorage.fetchToday();
      if (!mounted) return;
      setState(() {
        _day = day;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر الاتصال بالسحابة:\n$e';
      });
    }
  }

  Future<void> _answer(int questionId, int chosenIndex) async {
    if (_day == null || _day!.answers.containsKey(questionId)) return;
    setState(() => _submittingQuestionId = questionId);
    try {
      final updated = await ReligiousQuizStorage.submitAnswer(questionId, chosenIndex);
      if (!mounted) return;
      setState(() {
        _day = updated;
        _submittingQuestionId = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _submittingQuestionId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تسجيل الجواب: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('أسئلة دينية'),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off_rounded, color: Colors.white38, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _load,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final day = _day!;
    final questions = day.questionIds.map((id) => kReligiousQuizBank.firstWhere((q) => q.id == id)).toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  '5 أسئلة دينية يوميا عن القرآن والسنة، كل جواب صحيح = نقطتين تنضافوا لتحدي الصلاة',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${day.points} / $kReligiousQuizMaxPoints',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < questions.length; i++) ...[
          _buildQuestionTile(i + 1, questions[i], day),
          const SizedBox(height: 14),
        ],
        if (day.isComplete) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.success),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'خلصتي أسئلة اليوم! رجع غدا لأسئلة جديدة.',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionTile(int number, ReligiousQuizQuestion question, ReligiousQuizDay day) {
    final chosen = day.answers[question.id];
    final answered = chosen != null;
    final submitting = _submittingQuestionId == question.id;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ${question.question}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...List.generate(question.options.length, (i) {
            Color borderColor = Colors.white24;
            Color? fillColor;
            Color textColor = Colors.white70;
            if (answered) {
              if (i == question.correctIndex) {
                borderColor = AppColors.success;
                fillColor = AppColors.success.withValues(alpha: 0.15);
                textColor = AppColors.success;
              } else if (i == chosen) {
                borderColor = AppColors.danger;
                fillColor = AppColors.danger.withValues(alpha: 0.15);
                textColor = AppColors.danger;
              }
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                onTap: answered || submitting ? null : () => _answer(question.id, i),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: fillColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(question.options[i], style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
