import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum _Move { rock, paper, scissors }

const Map<_Move, String> _kEmoji = {
  _Move.rock: '✊',
  _Move.paper: '✋',
  _Move.scissors: '✌️',
};

const Map<_Move, String> _kLabel = {
  _Move.rock: 'حجر',
  _Move.paper: 'ورقة',
  _Move.scissors: 'مقص',
};

/// Pass-and-play rock/paper/scissors: player 1 picks with the phone hidden
/// from player 2, then hands it over for player 2's pick, then both reveal.
enum _Phase { player1Picking, handoff, player2Picking, reveal }

class RockPaperScissorsScreen extends StatefulWidget {
  const RockPaperScissorsScreen({super.key});

  @override
  State<RockPaperScissorsScreen> createState() => _RockPaperScissorsScreenState();
}

class _RockPaperScissorsScreenState extends State<RockPaperScissorsScreen> {
  _Phase _phase = _Phase.player1Picking;
  _Move? _p1Move;
  _Move? _p2Move;
  int _p1Score = 0;
  int _p2Score = 0;

  void _pick(_Move move) {
    setState(() {
      if (_phase == _Phase.player1Picking) {
        _p1Move = move;
        _phase = _Phase.handoff;
      } else if (_phase == _Phase.player2Picking) {
        _p2Move = move;
        _phase = _Phase.reveal;
        final winner = _decide(_p1Move!, _p2Move!);
        if (winner == 1) _p1Score++;
        if (winner == 2) _p2Score++;
      }
    });
  }

  /// Returns 0 for draw, 1 if move A beats move B, 2 otherwise.
  int _decide(_Move a, _Move b) {
    if (a == b) return 0;
    final beats = {
      _Move.rock: _Move.scissors,
      _Move.paper: _Move.rock,
      _Move.scissors: _Move.paper,
    };
    return beats[a] == b ? 1 : 2;
  }

  void _nextRound() {
    setState(() {
      _phase = _Phase.player1Picking;
      _p1Move = null;
      _p2Move = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('حجر ورقة مقص'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreChip('اللاعب 1', _p1Score, AppColors.primary),
                      const SizedBox(width: 20),
                      _scoreChip('اللاعب 2', _p2Score, AppColors.danger),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildPhaseContent(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('$label: $score', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildPhaseContent() {
    switch (_phase) {
      case _Phase.player1Picking:
        return _pickerCard('دور اللاعب 1', AppColors.primary);
      case _Phase.handoff:
        return _handoffCard('اللاعب 1 اختار! مرر الهاتف للاعب 2', () {
          setState(() => _phase = _Phase.player2Picking);
        });
      case _Phase.player2Picking:
        return _pickerCard('دور اللاعب 2', AppColors.danger);
      case _Phase.reveal:
        return _revealCard();
    }
  }

  Widget _pickerCard(String title, Color color) {
    return Column(
      children: [
        Text(title, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _Move.values
              .map((m) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: _moveButton(m, () => _pick(m)),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _handoffCard(String message, VoidCallback onReady) {
    return Column(
      children: [
        const Icon(Icons.swap_horiz_rounded, color: Colors.white54, size: 40),
        const SizedBox(height: 12),
        Text(message, style: const TextStyle(color: Colors.white70, fontSize: 15), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: onReady,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('جاهز'),
        ),
      ],
    );
  }

  Widget _revealCard() {
    final result = _decide(_p1Move!, _p2Move!);
    final resultText = result == 0
        ? 'تعادل!'
        : result == 1
            ? 'اللاعب 1 فاز 🎉'
            : 'اللاعب 2 فاز 🎉';
    final resultColor = result == 0
        ? Colors.white
        : result == 1
            ? AppColors.primary
            : AppColors.danger;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _revealChip('اللاعب 1', _p1Move!, AppColors.primary),
            const SizedBox(width: 24),
            const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
            const SizedBox(width: 24),
            _revealChip('اللاعب 2', _p2Move!, AppColors.danger),
          ],
        ),
        const SizedBox(height: 20),
        Text(resultText, style: TextStyle(color: resultColor, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _nextRound,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('جولة جديدة'),
        ),
      ],
    );
  }

  Widget _revealChip(String label, _Move move, Color color) {
    return Column(
      children: [
        Text(_kEmoji[move]!, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: 4),
        Text(_kLabel[move]!, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _moveButton(_Move move, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_kEmoji[move]!, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 6),
            Text(_kLabel[move]!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
