import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import 'email_notifier.dart';
import 'prayer_celebration.dart';
import 'prayer_points.dart';
import 'prayer_storage.dart';
import 'prayer_times_service.dart';

class PrayerTrackerScreen extends StatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  State<PrayerTrackerScreen> createState() => _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends State<PrayerTrackerScreen> {
  PrayerDay? _day;
  bool _loading = true;
  bool _celebrationOpen = false;
  bool _sendingMessage = false;
  String? _error;
  RealtimeChannel? _channel;
  RealtimeChannel? _messagesChannel;
  final _messageController = TextEditingController();
  List<PrayerMessage> _messages = [];
  PrayerChallengeRecord? _challenge;
  String? _rewardChoice;
  List<PrayerChallengeRecord> _history = [];
  bool _loadingChallenge = true;
  Map<String, DateTime>? _todayTimes;
  DateTime? _tomorrowFajr;
  Timer? _countdownTimer;

  static const _labels = {
    'fajr': 'الفجر',
    'dhuhr': 'الظهر',
    'asr': 'العصر',
    'maghrib': 'المغرب',
    'isha': 'العشاء',
  };

  static const _months = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'ماي', 'يونيو',
    'يوليوز', 'غشت', 'شتنبر', 'أكتوبر', 'نونبر', 'دجنبر',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final day = await PrayerStorage.fetchToday();
      if (!mounted) return;
      setState(() {
        _day = day;
        _loading = false;
      });
      _channel = PrayerStorage.subscribeToday(_onRemoteChange);
      _messagesChannel = PrayerStorage.subscribeMessages(_loadMessages);
      unawaited(_loadMessages());
      unawaited(_loadChallenge());
      unawaited(_loadTimes());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر الاتصال بالسحابة:\n$e';
      });
    }
  }

  Future<void> _loadTimes() async {
    final now = DateTime.now();
    final times = await PrayerTimesService.timingsFor(now);
    final tomorrowTimes = await PrayerTimesService.timingsFor(now.add(const Duration(days: 1)));
    if (!mounted || times == null) return;
    setState(() {
      _todayTimes = times;
      _tomorrowFajr = tomorrowTimes?['fajr'];
    });
  }

  Future<void> _loadChallenge() async {
    try {
      final challenge = await PrayerStorage.fetchCurrentChallenge();
      final reward = await PrayerStorage.fetchRewardChoice();
      final history = await PrayerStorage.fetchChallengeHistory();
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _rewardChoice = reward;
        _history = history;
        _loadingChallenge = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingChallenge = false);
    }
  }

  Future<void> _refreshChallengeAndCheckGoal() async {
    final prevReached = _challenge?.rewardReached ?? false;
    try {
      final challenge = await PrayerStorage.fetchCurrentChallenge();
      if (!mounted) return;
      setState(() => _challenge = challenge);
      if (!prevReached && challenge.rewardReached) {
        final reward = _rewardChoice == 'brawl_stars' ? 'Brawl Stars' : 'Fortnite';
        unawaited(PrayerEmailNotifier.notifyPrayerActivated('🎉 وصل عبدالرحمن لـ 1000 نقطة! الجائزة: $reward'));
      }
    } catch (_) {
      // Points still saved; challenge total will refresh on next load.
    }
  }

  Future<void> _selectReward(String value) async {
    setState(() => _rewardChoice = value);
    try {
      await PrayerStorage.setRewardChoice(value);
    } catch (_) {
      // Ignore; user can retry by tapping again.
    }
  }

  Future<int> _computePoints(String name) async {
    final now = DateTime.now();
    final todayTimes = await PrayerTimesService.timingsFor(now);
    if (todayTimes == null) return 0;
    DateTime? nextBoundary;
    if (name == 'isha') {
      final tomorrowTimes = await PrayerTimesService.timingsFor(now.add(const Duration(days: 1)));
      nextBoundary = tomorrowTimes?['fajr'];
    } else {
      final idx = kPrayerNames.indexOf(name);
      nextBoundary = todayTimes[kPrayerNames[idx + 1]];
    }
    final adhan = todayTimes[name];
    if (adhan == null || nextBoundary == null) return 0;
    return computePrayerPoints(adhanTime: adhan, nextAdhanTime: nextBoundary, prayedAt: now);
  }

  void _onRemoteChange(PrayerDay day) {
    if (!mounted) return;
    final prev = _day;
    final newlyDone = prev != null &&
        kPrayerNames.any((p) => prev.status[p] != true && day.status[p] == true);
    setState(() => _day = day);
    if (newlyDone) _celebrate(day.allDone);
  }

  Future<void> _loadMessages() async {
    final messages = await PrayerStorage.fetchMessages();
    if (!mounted) return;
    setState(() => _messages = messages);
  }

  void _celebrate(bool allDone) {
    if (_celebrationOpen) return;
    _celebrationOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => PrayerCelebrationOverlay(
        allDone: allDone,
        onClose: () => Navigator.of(context).pop(),
      ),
    ).then((_) => _celebrationOpen = false);
  }

  Future<void> _toggle(String name, bool value) async {
    final current = _day;
    if (current == null) return;
    if (current.status[name] == true && !value) return;

    if (value) {
      final times = _todayTimes ?? await PrayerTimesService.timingsFor(DateTime.now());
      final adhan = times?[name];
      if (adhan != null && DateTime.now().isBefore(adhan)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('لم يدخل وقت ${_labels[name]} بعد (الأذان الساعة ${_formatTime(adhan)})')),
        );
        return;
      }
    }

    setState(() => current.status[name] = value);
    final points = value ? await _computePoints(name) : 0;
    final updated = await PrayerStorage.setPrayer(name, value, points: points);
    if (!mounted) return;
    setState(() => _day = updated);
    if (value) {
      _celebrate(updated.allDone);
      unawaited(PrayerEmailNotifier.notifyPrayerActivated(_labels[name]!));
      unawaited(_refreshChallengeAndCheckGoal());
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sendingMessage) return;
    setState(() => _sendingMessage = true);
    try {
      await PrayerStorage.sendMessage(text);
      if (!mounted) return;
      _messageController.clear();
      await _loadMessages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الرسالة لباباك 💌')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر إرسال الرسالة: $e')),
      );
    } finally {
      if (mounted) setState(() => _sendingMessage = false);
    }
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _messagesChannel?.unsubscribe();
    _messageController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('تتبع صلاة عبدالرحمن'),
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
                : _day == null
                    ? const SizedBox.shrink()
                    : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    _formatDate(_day!.date),
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  ...kPrayerNames.map(_buildPrayerTile),
                  const SizedBox(height: 20),
                  _buildChallengeSection(),
                  const SizedBox(height: 8),
                  const Text(
                    'رسالة توجهها لوالدك',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: TextField(
                      controller: _messageController,
                      maxLines: 4,
                      minLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'اكتب رسالتك هنا...',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendingMessage ? null : _sendMessage,
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(_sendingMessage ? 'جاري الإرسال...' : 'إرسال'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  if (_messages.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'الرسائل اليوم',
                      style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ..._messages.reversed.map(_buildMessageTile),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildMessageTile(PrayerMessage m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceHi,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(m.text, style: const TextStyle(color: Colors.white)),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('كيفاش كتتحسب النقاط؟', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _RuleLine('✅', 'صليت خلال 30 دقيقة من الأذان', '20 نقطة'),
              SizedBox(height: 10),
              _RuleLine('🕓', 'صليت بعد 30 دقيقة (وقبل دخول الصلاة الموالية)', '5 نقاط'),
              SizedBox(height: 10),
              _RuleLine('❌', 'صليت بعد دخول وقت الصلاة الموالية', '0 نقطة'),
              SizedBox(height: 18),
              Divider(color: Colors.white12),
              SizedBox(height: 10),
              Text(
                '🎯 الهدف: 1000 نقطة خلال 15 يوم',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text(
                '🎁 الجائزة: 10 دولار (Fortnite أو Brawl Stars — عبدالرحمن يختار)',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                'كي يكمل الـ15 يوم، كيبدا تحدي جديد من 0 نقطة — والتحدي القديم كيبقى محفوظ فـ"التحديات السابقة".',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('فهمت'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeSection() {
    final challenge = _challenge;
    if (_loadingChallenge || challenge == null) return const SizedBox.shrink();

    final progress = (challenge.totalPoints / kChallengeGoalPoints).clamp(0.0, 1.0);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'تحدي 1000 نقطة',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: _showRulesDialog,
                    icon: const Icon(Icons.info_outline_rounded, color: Colors.white54, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
              ),
              Text(
                'متبقي ${challenge.daysRemaining} يوم',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(
                challenge.rewardReached ? Colors.greenAccent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${challenge.totalPoints} / $kChallengeGoalPoints نقطة',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          const Text(
            'اختر جائزتك',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _rewardButton('fortnite', 'Fortnite')),
              const SizedBox(width: 10),
              Expanded(child: _rewardButton('brawl_stars', 'Brawl Stars')),
            ],
          ),
          if (_history.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text(
              'التحديات السابقة',
              style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._history.map(_buildHistoryTile),
          ],
        ],
      ),
    );
  }

  Widget _rewardButton(String value, String label) {
    final selected = _rewardChoice == value;
    return OutlinedButton(
      onPressed: () => _selectReward(value),
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
        side: BorderSide(color: selected ? AppColors.primary : Colors.white24),
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.primary : Colors.white70,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildHistoryTile(PrayerChallengeRecord r) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.surfaceHi, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_formatDate(r.startDate)} - ${_formatDate(r.endDate)}',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Row(
            children: [
              Icon(
                r.rewardReached ? Icons.emoji_events_rounded : Icons.circle_outlined,
                color: r.rewardReached ? Colors.amberAccent : Colors.white38,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                '${r.totalPoints} نقطة',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatRemaining(Duration d) {
    final totalMinutes = d.inMinutes;
    if (totalMinutes < 1) return 'أقل من دقيقة';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    return h > 0 ? '$h س $m د' : '$m د';
  }

  Widget? _buildCountdown(String name) {
    final adhan = _todayTimes?[name];
    if (adhan == null) return null;
    final idx = kPrayerNames.indexOf(name);
    final next = name == 'isha' ? _tomorrowFajr : _todayTimes?[kPrayerNames[idx + 1]];
    if (next == null) return null;

    final now = DateTime.now();
    final graceEnd = adhan.add(const Duration(minutes: 30));

    late final Color color;
    late final String text;
    if (now.isBefore(adhan)) {
      color = AppColors.success;
      text = 'متبقي ${_formatRemaining(adhan.difference(now))} لدخول ${_labels[name]}';
    } else if (now.isBefore(graceEnd)) {
      color = AppColors.warning;
      text = 'متبقي ${_formatRemaining(graceEnd.difference(now))} على النقاط الكاملة';
    } else if (now.isBefore(next)) {
      color = AppColors.danger;
      text = 'تدارك قبل ${_labels[kPrayerNames[name == 'isha' ? 0 : idx + 1]]}! متبقي ${_formatRemaining(next.difference(now))}';
    } else {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildPrayerTile(String name) {
    final done = _day!.status[name] == true;
    final time = _todayTimes?[name];
    final countdown = done ? null : _buildCountdown(name);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.primary : Colors.white12),
      ),
      child: SwitchListTile(
        value: done,
        onChanged: done ? null : (v) => _toggle(name, v),
        activeThumbColor: AppColors.primary,
        title: Text(
          _labels[name]!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        subtitle: time == null && countdown == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (time != null)
                    Text(_formatTime(time), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                  ?countdown,
                ],
              ),
        secondary: Icon(
          done ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: done ? AppColors.primary : Colors.white38,
        ),
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine(this.emoji, this.description, this.points);

  final String emoji;
  final String description;
  final String points;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(description, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
        ),
        const SizedBox(width: 8),
        Text(points, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
