import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal/portal_client.dart';

/// أسماء الصلوات الخمس بترتيبها اليومي، وهي نفسها أسماء الأعمدة فجدول
/// `prayers` فـ Supabase.
const List<String> kPrayerNames = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

class PrayerDay {
  PrayerDay({required this.date, required this.status});

  final DateTime date;
  final Map<String, bool> status;

  bool get allDone => kPrayerNames.every((p) => status[p] == true);

  factory PrayerDay.fromRow(Map<String, dynamic> row) {
    return PrayerDay(
      date: DateTime.parse(row['prayer_date'] as String),
      status: {for (final p in kPrayerNames) p: row[p] == true},
    );
  }

  factory PrayerDay.empty(DateTime date) {
    return PrayerDay(date: date, status: {for (final p in kPrayerNames) p: false});
  }
}

class PrayerMessage {
  PrayerMessage({required this.id, required this.text, required this.createdAt});

  final String id;
  final String text;
  final DateTime createdAt;

  factory PrayerMessage.fromRow(Map<String, dynamic> row) {
    return PrayerMessage(
      id: row['id'] as String,
      text: row['message'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}

class PrayerStorage {
  static const table = 'prayers';

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// كيجيب صف اليوم، وكيخلق وحد فارغ إيلا ماكانش موجود بعد.
  static Future<PrayerDay> fetchToday() async {
    final today = _todayKey();
    final existing = await portalClient
        .from(table)
        .select()
        .eq('prayer_date', today)
        .maybeSingle();

    if (existing != null) {
      return PrayerDay.fromRow(existing);
    }

    final created = await portalClient
        .from(table)
        .insert({'prayer_date': today})
        .select()
        .single();
    return PrayerDay.fromRow(created);
  }

  static Future<PrayerDay> setPrayer(String prayerName, bool value) async {
    final today = _todayKey();
    final updated = await portalClient
        .from(table)
        .update({prayerName: value, 'updated_at': DateTime.now().toIso8601String()})
        .eq('prayer_date', today)
        .select()
        .single();
    return PrayerDay.fromRow(updated);
  }

  /// اشتراك مباشر (Realtime) فتغييرات صف اليوم — باش الصفحة تتحدث وحدها
  /// من غير ما تحتاج refresh، حتى لو الصلاة تعلمت من جهاز آخر.
  static RealtimeChannel subscribeToday(void Function(PrayerDay day) onChange) {
    final today = _todayKey();
    return portalClient
        .channel('prayers-$today')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'prayer_date',
            value: today,
          ),
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isNotEmpty) {
              onChange(PrayerDay.fromRow(row));
            }
          },
        )
        .subscribe();
  }

  static const messagesTable = 'prayer_messages';

  /// آخر حد لدورة الرسائل: 5:00 صباحا بالتوقيت المحلي ديال الجهاز. إيلا
  /// كان الوقت الحالي قبل 5 صباحا، كتحسب 5 صباحا ديال البارح.
  static DateTime _messagesCycleStart() {
    final now = DateTime.now();
    final todayAt5 = DateTime(now.year, now.month, now.day, 5);
    return now.isBefore(todayAt5) ? todayAt5.subtract(const Duration(days: 1)) : todayAt5;
  }

  /// كيمسح الرسائل القديمة (قبل 5 صباحا ديال الدورة الحالية)، ومن بعد
  /// كيرجع الرسائل المتبقية.
  static Future<List<PrayerMessage>> fetchMessages() async {
    final cycleStart = _messagesCycleStart();
    await portalClient
        .from(messagesTable)
        .delete()
        .lt('created_at', cycleStart.toIso8601String());

    final rows = await portalClient.from(messagesTable).select().order('created_at', ascending: true);
    return rows.map((r) => PrayerMessage.fromRow(r)).toList();
  }

  static Future<void> sendMessage(String text) async {
    await portalClient.from(messagesTable).insert({'message': text});
  }

  static RealtimeChannel subscribeMessages(void Function() onChange) {
    return portalClient
        .channel('prayer-messages')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: messagesTable,
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
