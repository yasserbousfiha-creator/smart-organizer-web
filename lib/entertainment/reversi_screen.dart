import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const int _kSize = 8;
const List<List<int>> _kDirections = [
  [-1, -1], [-1, 0], [-1, 1],
  [0, -1], [0, 1],
  [1, -1], [1, 0], [1, 1],
];

class _Pos {
  const _Pos(this.row, this.col);
  final int row;
  final int col;
}

/// Classic Reversi/Othello: flank the opponent's discs between two of your
/// own to flip them. Most discs on the board when nobody can move wins.
class ReversiScreen extends StatefulWidget {
  const ReversiScreen({super.key});

  @override
  State<ReversiScreen> createState() => _ReversiScreenState();
}

class _ReversiScreenState extends State<ReversiScreen> {
  late List<List<int>> _board;
  int _currentPlayer = 1;
  String? _message;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_kSize, (_) => List.filled(_kSize, 0));
    _board[3][3] = 2;
    _board[3][4] = 1;
    _board[4][3] = 1;
    _board[4][4] = 2;
    _currentPlayer = 1;
    _message = null;
    _gameOver = false;
    setState(() {});
  }

  List<_Pos> _flanksInDirection(int row, int col, int dr, int dc, int player) {
    final opponent = player == 1 ? 2 : 1;
    final flanks = <_Pos>[];
    var r = row + dr;
    var c = col + dc;
    while (r >= 0 && r < _kSize && c >= 0 && c < _kSize && _board[r][c] == opponent) {
      flanks.add(_Pos(r, c));
      r += dr;
      c += dc;
    }
    if (r >= 0 && r < _kSize && c >= 0 && c < _kSize && _board[r][c] == player && flanks.isNotEmpty) {
      return flanks;
    }
    return const [];
  }

  List<_Pos> _allFlanks(int row, int col, int player) {
    if (_board[row][col] != 0) return const [];
    final all = <_Pos>[];
    for (final d in _kDirections) {
      all.addAll(_flanksInDirection(row, col, d[0], d[1], player));
    }
    return all;
  }

  bool _hasValidMove(int player) {
    for (var r = 0; r < _kSize; r++) {
      for (var c = 0; c < _kSize; c++) {
        if (_board[r][c] == 0 && _allFlanks(r, c, player).isNotEmpty) return true;
      }
    }
    return false;
  }

  (int, int) _counts() {
    var p1 = 0, p2 = 0;
    for (final row in _board) {
      for (final v in row) {
        if (v == 1) p1++;
        if (v == 2) p2++;
      }
    }
    return (p1, p2);
  }

  void _tap(int row, int col) {
    if (_gameOver) return;
    final flanks = _allFlanks(row, col, _currentPlayer);
    if (flanks.isEmpty) return;

    setState(() {
      _board[row][col] = _currentPlayer;
      for (final p in flanks) {
        _board[p.row][p.col] = _currentPlayer;
      }

      final other = _currentPlayer == 1 ? 2 : 1;
      if (_hasValidMove(other)) {
        _currentPlayer = other;
        _message = null;
      } else if (_hasValidMove(_currentPlayer)) {
        _message = 'الخصم ما عندهوش حركة، دورك مرة أخرى';
      } else {
        _gameOver = true;
        final (p1, p2) = _counts();
        _message = p1 == p2
            ? 'تعادل! $p1 - $p2'
            : 'فاز ${p1 > p2 ? "اللاعب 1 (أسود)" : "اللاعب 2 (أبيض)"}! $p1 - $p2';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final (p1, p2) = _counts();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('ريفيرسي (أوثيلو)'),
          actions: [
            IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded)),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _scoreChip('اللاعب 1', p1, Colors.black, _currentPlayer == 1 && !_gameOver),
                  _scoreChip('اللاعب 2', p2, Colors.white, _currentPlayer == 2 && !_gameOver),
                ],
              ),
              const SizedBox(height: 12),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _gameOver ? AppColors.primary : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDeep,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _kSize),
                        itemCount: _kSize * _kSize,
                        itemBuilder: (_, i) {
                          final row = i ~/ _kSize;
                          final col = i % _kSize;
                          final value = _board[row][col];
                          return GestureDetector(
                            onTap: () => _tap(row, col),
                            child: Container(
                              margin: const EdgeInsets.all(1),
                              color: AppColors.success.withValues(alpha: 0.55),
                              child: value == 0
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.all(3),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: value == 1 ? Colors.black : Colors.white,
                                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                                        ),
                                      ),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreChip(String label, int score, Color discColor, bool isTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isTurn ? AppColors.primary.withValues(alpha: 0.2) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isTurn ? AppColors.primary : Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(shape: BoxShape.circle, color: discColor, border: Border.all(color: Colors.white24)),
          ),
          const SizedBox(width: 8),
          Text('$label: $score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
