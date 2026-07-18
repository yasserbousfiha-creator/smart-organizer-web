import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const int _kTarget = 21;

/// Classic turn-based counting duel: each turn add 1, 2, or 3 to the running
/// total. Whoever makes it hit exactly 21 wins.
class CountTo21Screen extends StatefulWidget {
  const CountTo21Screen({super.key});

  @override
  State<CountTo21Screen> createState() => _CountTo21ScreenState();
}

class _CountTo21ScreenState extends State<CountTo21Screen> {
  int _total = 0;
  bool _p1Turn = true;
  String? _winner;
  int _p1Score = 0;
  int _p2Score = 0;

  void _add(int n) {
    if (_winner != null || _total + n > _kTarget) return;
    setState(() {
      _total += n;
      if (_total == _kTarget) {
        _winner = _p1Turn ? 'اللاعب 1' : 'اللاعب 2';
        if (_p1Turn) {
          _p1Score++;
        } else {
          _p2Score++;
        }
      } else {
        _p1Turn = !_p1Turn;
      }
    });
  }

  void _reset() {
    setState(() {
      _total = 0;
      _p1Turn = true;
      _winner = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final turnColor = _p1Turn ? AppColors.primary : AppColors.danger;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('لعبة 21'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'كل دور اختر 1 أو 2 أو 3 لتضيفها للمجموع — من يصل بالضبط لـ21 يفوز.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreChip('اللاعب 1', _p1Score, AppColors.primary, _p1Turn && _winner == null),
                      const SizedBox(width: 20),
                      _scoreChip('اللاعب 2', _p2Score, AppColors.danger, !_p1Turn && _winner == null),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    '$_total',
                    style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _winner != null ? '$_winner فاز 🎉' : 'دور: ${_p1Turn ? 'اللاعب 1' : 'اللاعب 2'}',
                    style: TextStyle(
                      color: _winner != null ? Colors.greenAccent : turnColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (_winner == null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [1, 2, 3]
                          .map((n) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ElevatedButton(
                                  onPressed: _total + n > _kTarget ? null : () => _add(n),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: turnColor,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.white12,
                                    padding: const EdgeInsets.all(20),
                                    shape: const CircleBorder(),
                                  ),
                                  child: Text('+$n', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                                ),
                              ))
                          .toList(),
                    ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceHi,
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('جولة جديدة'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color color, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: active ? 1 : 0.4), width: active ? 2 : 1),
      ),
      child: Text('$label: $score', style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12.5)),
    );
  }
}
