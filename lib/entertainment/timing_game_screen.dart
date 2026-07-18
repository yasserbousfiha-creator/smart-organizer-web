import 'package:flutter/material.dart';

import '../portal/portal_client.dart';
import '../theme/app_colors.dart';

class _ScoreEntry {
  _ScoreEntry({required this.playerName, required this.elapsedMs, required this.diffMs});

  final String playerName;
  final int elapsedMs;
  final int diffMs;

  factory _ScoreEntry.fromRow(Map<String, dynamic> row) => _ScoreEntry(
        playerName: row['player_name'] as String,
        elapsedMs: row['elapsed_ms'] as int,
        diffMs: row['diff_ms'] as int,
      );
}

/// Blind stopwatch game: press start, then stop as close as you can to the
/// target duration without watching a running clock. Every attempt is saved
/// to a shared leaderboard so more than one player can compare results.
class TimingGameScreen extends StatefulWidget {
  const TimingGameScreen({super.key});

  @override
  State<TimingGameScreen> createState() => _TimingGameScreenState();
}

class _TimingGameScreenState extends State<TimingGameScreen> {
  static const _targets = [5, 7, 8, 10, 12, 13, 15, 17, 18, 20];
  static const _table = 'timer_game_scores';

  int _targetSeconds = 5;
  final _nameController = TextEditingController();
  final _stopwatch = Stopwatch();
  bool _running = false;
  int? _lastElapsedMs;
  int? _lastDiffMs;
  List<_ScoreEntry> _leaderboard = [];
  bool _loadingLeaderboard = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _loadingLeaderboard = true);
    try {
      final rows = await portalClient
          .from(_table)
          .select()
          .eq('target_ms', _targetSeconds * 1000)
          .order('diff_ms', ascending: true)
          .limit(20);
      if (!mounted) return;
      setState(() {
        _leaderboard = rows.map((r) => _ScoreEntry.fromRow(r)).toList();
        _loadingLeaderboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLeaderboard = false);
    }
  }

  void _selectTarget(int seconds) {
    if (_running) return;
    setState(() {
      _targetSeconds = seconds;
      _lastElapsedMs = null;
      _lastDiffMs = null;
    });
    _loadLeaderboard();
  }

  void _start() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اكتب اسمك أولاً')),
      );
      return;
    }
    _stopwatch
      ..reset()
      ..start();
    setState(() {
      _running = true;
      _lastElapsedMs = null;
      _lastDiffMs = null;
    });
  }

  Future<void> _stop() async {
    _stopwatch.stop();
    final elapsed = _stopwatch.elapsedMilliseconds;
    final target = _targetSeconds * 1000;
    final diff = (elapsed - target).abs();
    setState(() {
      _running = false;
      _lastElapsedMs = elapsed;
      _lastDiffMs = diff;
      _saving = true;
    });
    try {
      await portalClient.from(_table).insert({
        'player_name': _nameController.text.trim(),
        'target_ms': target,
        'elapsed_ms': elapsed,
        'diff_ms': diff,
      });
      await _loadLeaderboard();
    } catch (_) {
      // Leaderboard just won't show this attempt; the result is still shown locally.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatMs(int ms) {
    final seconds = ms ~/ 1000;
    final hundredths = (ms % 1000) ~/ 10;
    return '$seconds.${hundredths.toString().padLeft(2, '0')}s';
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('لعبة تحديد الوقت'),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'اضغط ابدأ، ثم توقف بأقرب وقت ممكن من الهدف — بلا ما تشوف الثواني.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _targets
                  .map((t) => OutlinedButton(
                        onPressed: () => _selectTarget(t),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: _targetSeconds == t
                              ? AppColors.primary.withValues(alpha: 0.2)
                              : Colors.transparent,
                          side: BorderSide(
                            color: _targetSeconds == t ? AppColors.primary : Colors.white24,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          '$t ث',
                          style: TextStyle(
                            color: _targetSeconds == t ? AppColors.primary : Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              enabled: !_running,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'اسمك',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _running ? _stop : _start,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _running ? AppColors.danger : AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _running ? 'قف' : 'ابدأ',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (_lastElapsedMs != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    Text(
                      'وقتك: ${_formatMs(_lastElapsedMs!)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'الفرق عن الهدف: ${_formatMs(_lastDiffMs!)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    if (_saving) ...[
                      const SizedBox(height: 8),
                      const Text('جاري الحفظ...', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'أفضل النتائج ($_targetSeconds ثواني)',
              style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            if (_loadingLeaderboard)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_leaderboard.isEmpty)
              const Text('لا توجد نتائج بعد', style: TextStyle(color: Colors.white38, fontSize: 13))
            else
              ..._leaderboard.asMap().entries.map((entry) => _buildLeaderboardTile(entry.key + 1, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardTile(int rank, _ScoreEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceHi, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rank', style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: Text(entry.playerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
          Text(_formatMs(entry.elapsedMs), style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(width: 8),
          Text('±${_formatMs(entry.diffMs)}', style: const TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }
}
