import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const List<List<int>> _kWinLines = [
  [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
  [0, 3, 6], [1, 4, 7], [2, 5, 8], // columns
  [0, 4, 8], [2, 4, 6], // diagonals
];

class TicTacToeScreen extends StatefulWidget {
  const TicTacToeScreen({super.key});

  @override
  State<TicTacToeScreen> createState() => _TicTacToeScreenState();
}

class _TicTacToeScreenState extends State<TicTacToeScreen> {
  List<String?> _board = List.filled(9, null);
  bool _xTurn = true;
  List<int>? _winningLine;
  int _xScore = 0;
  int _oScore = 0;

  String? get _winner {
    for (final line in _kWinLines) {
      final a = _board[line[0]];
      if (a != null && a == _board[line[1]] && a == _board[line[2]]) {
        _winningLine = line;
        return a;
      }
    }
    return null;
  }

  bool get _isDraw => !_board.contains(null) && _winner == null;

  void _tap(int i) {
    if (_board[i] != null || _winner != null) return;
    setState(() {
      _board[i] = _xTurn ? 'X' : 'O';
      final w = _winner;
      if (w == 'X') _xScore++;
      if (w == 'O') _oScore++;
      _xTurn = !_xTurn;
    });
  }

  void _resetBoard() {
    setState(() {
      _board = List.filled(9, null);
      _winningLine = null;
      _xTurn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final winner = _winner;
    final draw = _isDraw;
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('إكس أو'),
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
                      _scoreChip('X', _xScore, AppColors.primary, active: _xTurn && winner == null),
                      const SizedBox(width: 20),
                      _scoreChip('O', _oScore, AppColors.danger, active: !_xTurn && winner == null),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    winner != null
                        ? 'فاز $winner 🎉'
                        : draw
                            ? 'تعادل!'
                            : 'دور: ${_xTurn ? 'X' : 'O'}',
                    style: TextStyle(
                      color: winner != null
                          ? (winner == 'X' ? AppColors.primary : AppColors.danger)
                          : draw
                              ? Colors.white
                              : (_xTurn ? AppColors.primary : AppColors.danger),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 300,
                    height: 300,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 9,
                      itemBuilder: (context, i) => _cell(i),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _resetBoard,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
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

  Widget _scoreChip(String label, int score, Color color, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: active ? 0.25 : 0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: active ? 1 : 0.4), width: active ? 2 : 1),
      ),
      child: Text('$label: $score', style: TextStyle(color: color, fontWeight: FontWeight.w700)),
    );
  }

  Widget _cell(int i) {
    final value = _board[i];
    final isWinning = _winningLine?.contains(i) ?? false;
    return GestureDetector(
      onTap: () => _tap(i),
      child: Container(
        decoration: BoxDecoration(
          color: isWinning ? AppColors.primary.withValues(alpha: 0.25) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isWinning ? AppColors.primary : Colors.white12),
        ),
        child: Center(
          child: Text(
            value ?? '',
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: value == 'X' ? AppColors.primary : AppColors.danger,
            ),
          ),
        ),
      ),
    );
  }
}
