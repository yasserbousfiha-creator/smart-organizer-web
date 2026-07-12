import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/app_colors.dart';
import 'prayer_celebration.dart';
import 'prayer_storage.dart';

/// شاشة سحابية (متزامنة مع Supabase) لمتابعة صلوات عبدالرحمن اليومية —
/// أي تعديل كيتسجل فالسحابة مباشرة، وكيبان فأي جهاز آخر فاتح نفس
/// الشاشة بفضل الاشتراك المباشر (Realtime).
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
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذر الاتصال بالسحابة:\n$e';
      });
    }
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
    setState(() => current.status[name] = value);
    final updated = await PrayerStorage.setPrayer(name, value);
    if (!mounted) return;
    setState(() => _day = updated);
    if (value) _celebrate(updated.allDone);
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
                  const SizedBox(height: 28),
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

  Widget _buildPrayerTile(String name) {
    final done = _day!.status[name] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: done ? AppColors.primary : Colors.white12),
      ),
      child: SwitchListTile(
        value: done,
        onChanged: (v) => _toggle(name, v),
        activeThumbColor: AppColors.primary,
        title: Text(
          _labels[name]!,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        secondary: Icon(
          done ? Icons.check_circle_rounded : Icons.circle_outlined,
          color: done ? AppColors.primary : Colors.white38,
        ),
      ),
    );
  }
}
