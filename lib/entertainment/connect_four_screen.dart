import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const int _kCols = 7;
const int _kRows = 6;

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({super.key});

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  List<List<String?>> _board = List.generate(_kRows, (_) => List<String?>.filled(_kCols, null));
  bool _aTurn = true;
  String? _winner; // 'A', 'B', or 'draw'
  List<List<int>>? _winCells;
  int _aScore = 0;
  int _bScore = 0;

  void _drop(int col) {
    if (_winner != null) return;
    for (var r = _kRows - 1; r >= 0; r--) {
      if (_board[r][col] == null) {
        final player = _aTurn ? 'A' : 'B';
        setState(() {
          _board[r][col] = player;
          final win = _findWin(r, col, player);
          if (win != null) {
            _winner = player;
            _winCells = win;
            if (player == 'A') {
              _aScore++;
            } else {
              _bScore++;
            }
          } else if (_board.every((row) => row.every((c) => c != null))) {
            _winner = 'draw';
          } else {
            _aTurn = !_aTurn;
          }
        });
        return;
      }
    }
  }

  List<List<int>>? _findWin(int row, int col, String player) {
    const directions = [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, -1],
    ];
    for (final d in directions) {
      final cells = [
        [row, col],
      ];
      for (final sign in [1, -1]) {
        var r = row + d[0] * sign;
        var c = col + d[1] * sign;
        while (r >= 0 && r < _kRows && c >= 0 && c < _kCols && _board[r][c] == player) {
          cells.add([r, c]);
          r += d[0] * sign;
          c += d[1] * sign;
        }
      }
      if (cells.length >= 4) return cells;
    }
    return null;
  }

  void _reset() {
    setState(() {
      _board = List.generate(_kRows, (_) => List<String?>.filled(_kCols, null));
      _winner = null;
      _winCells = null;
      _aTurn = true;
    });
  }

  bool _isWinCell(int r, int c) => _winCells?.any((cell) => cell[0] == r && cell[1] == c) ?? false;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('اربح 4'),
        ),
        body: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _scoreChip('اللاعب 1', _aScore, AppColors.primary, _aTurn && _winner == null),
                      const SizedBox(width: 20),
                      _scoreChip('اللاعب 2', _bScore, AppColors.danger, !_aTurn && _winner == null),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _winner == 'draw'
                        ? 'تعادل!'
                        : _winner != null
                            ? '${_winner == 'A' ? 'اللاعب 1' : 'اللاعب 2'} فاز 🎉'
                            : 'دور: ${_aTurn ? 'اللاعب 1' : 'اللاعب 2'}',
                    style: TextStyle(
                      color: _winner == null
                          ? (_aTurn ? AppColors.primary : AppColors.danger)
                          : _winner == 'draw'
                              ? Colors.white
                              : (_winner == 'A' ? AppColors.primary : AppColors.danger),
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AspectRatio(
                    aspectRatio: _kCols / _kRows,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _kCols,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: _kCols * _kRows,
                      itemBuilder: (context, i) {
                        final r = i ~/ _kCols;
                        final c = i % _kCols;
                        return _cell(r, c);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _reset,
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

  Widget _cell(int r, int c) {
    final value = _board[r][c];
    final isWinning = _isWinCell(r, c);
    return GestureDetector(
      onTap: () => _drop(c),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: isWinning ? Colors.white : Colors.white12, width: isWinning ? 2 : 1),
        ),
        child: Center(
          child: Container(
            width: double.infinity,
            height: double.infinity,
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value == 'A'
                  ? AppColors.primary
                  : value == 'B'
                      ? AppColors.danger
                      : Colors.white10,
            ),
          ),
        ),
      ),
    );
  }
}
