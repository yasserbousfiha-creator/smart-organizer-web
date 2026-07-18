import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

const int _kDotRows = 4;
const int _kDotCols = 4;
const int _kBoxRows = _kDotRows - 1;
const int _kBoxCols = _kDotCols - 1;

const double _kDotSize = 12;
const double _kLineLen = 44;
const double _kLineThickness = 26;

/// Dots and Boxes: draw one line per turn; completing a box's 4th side
/// scores it for you and grants an extra turn. Most boxes wins.
class DotsAndBoxesScreen extends StatefulWidget {
  const DotsAndBoxesScreen({super.key});

  @override
  State<DotsAndBoxesScreen> createState() => _DotsAndBoxesScreenState();
}

class _DotsAndBoxesScreenState extends State<DotsAndBoxesScreen> {
  late List<List<int>> _horizontal; // [rows][cols-1], 0=undrawn, else owner
  late List<List<int>> _vertical; // [rows-1][cols], 0=undrawn, else owner
  late List<List<int>> _boxOwner; // [boxRows][boxCols] 0=none,1,2
  int _currentPlayer = 1;
  String? _message;
  bool _gameOver = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _horizontal = List.generate(_kDotRows, (_) => List.filled(_kDotCols - 1, 0));
    _vertical = List.generate(_kDotRows - 1, (_) => List.filled(_kDotCols, 0));
    _boxOwner = List.generate(_kBoxRows, (_) => List.filled(_kBoxCols, 0));
    _currentPlayer = 1;
    _message = null;
    _gameOver = false;
    setState(() {});
  }

  bool _boxComplete(int r, int c) {
    return _horizontal[r][c] != 0 && _horizontal[r + 1][c] != 0 && _vertical[r][c] != 0 && _vertical[r][c + 1] != 0;
  }

  int _claimCompletedBoxes() {
    var claimed = 0;
    for (var r = 0; r < _kBoxRows; r++) {
      for (var c = 0; c < _kBoxCols; c++) {
        if (_boxOwner[r][c] == 0 && _boxComplete(r, c)) {
          _boxOwner[r][c] = _currentPlayer;
          claimed++;
        }
      }
    }
    return claimed;
  }

  void _afterMove() {
    final claimed = _claimCompletedBoxes();
    final totalBoxes = _kBoxRows * _kBoxCols;
    final filled = _boxOwner.expand((row) => row).where((v) => v != 0).length;

    if (filled == totalBoxes) {
      _gameOver = true;
      final (p1, p2) = _counts();
      _message = p1 == p2 ? 'تعادل! $p1 - $p2' : 'فاز ${p1 > p2 ? "اللاعب 1" : "اللاعب 2"}! $p1 - $p2';
      return;
    }

    if (claimed == 0) {
      _currentPlayer = _currentPlayer == 1 ? 2 : 1;
      _message = null;
    } else {
      _message = 'كملتي مربع! دورك مرة أخرى';
    }
  }

  void _tapHorizontal(int r, int c) {
    if (_gameOver || _horizontal[r][c] != 0) return;
    setState(() {
      _horizontal[r][c] = _currentPlayer;
      _afterMove();
    });
  }

  void _tapVertical(int r, int c) {
    if (_gameOver || _vertical[r][c] != 0) return;
    setState(() {
      _vertical[r][c] = _currentPlayer;
      _afterMove();
    });
  }

  (int, int) _counts() {
    var p1 = 0, p2 = 0;
    for (final row in _boxOwner) {
      for (final v in row) {
        if (v == 1) p1++;
        if (v == 2) p2++;
      }
    }
    return (p1, p2);
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
          title: const Text('النقط والصناديق'),
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
                  _scoreChip('اللاعب 1', p1, AppColors.primary, _currentPlayer == 1 && !_gameOver),
                  _scoreChip('اللاعب 2', p2, AppColors.warning, _currentPlayer == 2 && !_gameOver),
                ],
              ),
              const SizedBox(height: 12),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _gameOver ? AppColors.success : Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var r = 0; r < _kDotRows; r++) ...[
                          _dotRow(r),
                          if (r < _kDotRows - 1) _connectorRow(r),
                        ],
                      ],
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

  Widget _dot() => Container(
        width: _kDotSize,
        height: _kDotSize,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white70),
      );

  Widget _dotRow(int r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < _kDotCols; c++) ...[
          _dot(),
          if (c < _kDotCols - 1) _horizontalLine(r, c),
        ],
      ],
    );
  }

  Widget _horizontalLine(int r, int c) {
    final owner = _horizontal[r][c];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapHorizontal(r, c),
      child: SizedBox(
        width: _kLineLen,
        height: _kLineThickness,
        child: Center(
          child: Container(
            width: _kLineLen,
            height: 4,
            color: _lineColor(owner),
          ),
        ),
      ),
    );
  }

  Widget _connectorRow(int r) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var c = 0; c < _kDotCols; c++) ...[
          _verticalLine(r, c),
          if (c < _kBoxCols) _boxCell(r, c),
        ],
      ],
    );
  }

  Widget _verticalLine(int r, int c) {
    final owner = _vertical[r][c];
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _tapVertical(r, c),
      child: SizedBox(
        width: _kLineThickness,
        height: _kLineLen,
        child: Center(
          child: Container(
            width: 4,
            height: _kLineLen,
            color: _lineColor(owner),
          ),
        ),
      ),
    );
  }

  Color _lineColor(int owner) {
    if (owner == 1) return AppColors.primary;
    if (owner == 2) return AppColors.warning;
    return Colors.white12;
  }

  Widget _boxCell(int r, int c) {
    final owner = _boxOwner[r][c];
    final color = owner == 1
        ? AppColors.primary.withValues(alpha: 0.35)
        : owner == 2
            ? AppColors.warning.withValues(alpha: 0.35)
            : Colors.transparent;
    return Container(
      width: _kLineLen,
      height: _kLineLen,
      color: color,
      alignment: Alignment.center,
      child: owner == 0 ? null : Text(owner.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
    );
  }

  Widget _scoreChip(String label, int score, Color color, bool isTurn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isTurn ? color.withValues(alpha: 0.2) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isTurn ? color : Colors.white12),
      ),
      child: Text('$label: $score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }
}
