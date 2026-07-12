import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal/portal_client.dart';

const List<String> kPrayerSubKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

const Map<String, String> kPrayerSubLabels = {
  'fajr': 'Fajr',
  'dhuhr': 'Dhuhr',
  'asr': 'Asr',
  'maghrib': 'Maghrib',
  'isha': 'Isha',
};

/// وصف المهام الافتراضية اللي كتتخلق من جديد كل يوم — كل وحدة عندها
/// `kind` كيحدد طريقة العرض والتفاعل: counter (عداد بزيادة `step`)،
/// prayers (5 مفاتيح فرعية)، أو simple (زر تشغيل/إطفاء عادي).
const List<Map<String, Object?>> kDefaultTaskDefs = [
  {'title': '100 Sit-ups', 'kind': 'counter', 'target': 100.0, 'unit': 'reps', 'step': 10.0},
  {'title': '100 Push-ups', 'kind': 'counter', 'target': 100.0, 'unit': 'reps', 'step': 10.0},
  {'title': '5 km Running', 'kind': 'counter', 'target': 5.0, 'unit': 'km', 'step': 1.0},
  {'title': '5 km Walking', 'kind': 'counter', 'target': 5.0, 'unit': 'km', 'step': 1.0},
  {'title': '5 Prayers', 'kind': 'prayers', 'target': 5.0, 'unit': 'prayers', 'step': null},
  {'title': 'Drink 3L of Water', 'kind': 'counter', 'target': 3000.0, 'unit': 'ml', 'step': 300.0},
];

class SystemTask {
  SystemTask({
    required this.id,
    required this.title,
    required this.kind,
    required this.done,
    required this.progress,
    required this.target,
    required this.unit,
    required this.step,
    required this.subStatus,
    required this.sortOrder,
    required this.isCustom,
  });

  final String id;
  final String title;
  final String kind;
  final bool done;
  final double progress;
  final double? target;
  final String? unit;
  final double? step;
  final Map<String, bool>? subStatus;
  final int sortOrder;
  final bool isCustom;

  factory SystemTask.fromRow(Map<String, dynamic> row) {
    Map<String, bool>? subStatus;
    final rawSub = row['sub_status'];
    if (rawSub is Map) {
      subStatus = rawSub.map((k, v) => MapEntry(k as String, v == true));
    }
    return SystemTask(
      id: row['id'] as String,
      title: row['title'] as String,
      kind: row['kind'] as String? ?? 'simple',
      done: row['done'] == true,
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
      target: (row['target'] as num?)?.toDouble(),
      unit: row['unit'] as String?,
      step: (row['step'] as num?)?.toDouble(),
      subStatus: subStatus,
      sortOrder: row['sort_order'] as int? ?? 0,
      isCustom: row['is_custom'] == true,
    );
  }
}

class SystemTaskStorage {
  static const table = 'system_tasks';

  static String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static Future<List<SystemTask>> fetchToday() async {
    final today = _todayKey();
    var tasks = await _fetchTasksFor(today);

    // إيلا اليوم فيه غير مهام خاصة (أو والو خالص)، بلا حتى وحدة من
    // الستة الافتراضيين — خاصهم يتخلقو، بلا ما نمسو المهام الخاصة
    // الموجودة.
    if (!tasks.any((t) => !t.isCustom)) {
      final rows = [
        for (var i = 0; i < kDefaultTaskDefs.length; i++)
          {
            'task_date': today,
            'sort_order': i,
            ...kDefaultTaskDefs[i],
            if (kDefaultTaskDefs[i]['kind'] == 'prayers')
              'sub_status': {for (final k in kPrayerSubKeys) k: false},
          },
      ];
      await portalClient.from(table).insert(rows);
      tasks = await _fetchTasksFor(today);
    }
    return tasks;
  }

  static Future<List<SystemTask>> _fetchTasksFor(String date) async {
    final rows = await portalClient
        .from(table)
        .select()
        .eq('task_date', date)
        .order('sort_order', ascending: true);
    return rows.map((r) => SystemTask.fromRow(r)).toList();
  }

  static Future<void> addCustomTask(String title) async {
    final today = _todayKey();
    await portalClient.from(table).insert({
      'task_date': today,
      'title': title,
      'kind': 'simple',
      'sort_order': 999,
      'is_custom': true,
    });
  }

  static Future<void> deleteTask(String id) async {
    await portalClient.from(table).delete().eq('id', id);
  }

  static Future<SystemTask> renameTask(String id, String title) async {
    final updated = await portalClient
        .from(table)
        .update({'title': title})
        .eq('id', id)
        .select()
        .single();
    return SystemTask.fromRow(updated);
  }

  static Future<SystemTask> setDone(String id, bool value) async {
    final updated = await portalClient
        .from(table)
        .update({'done': value, 'progress': value ? 1 : 0})
        .eq('id', id)
        .select()
        .single();
    return SystemTask.fromRow(updated);
  }

  /// كيبدل التقدم ديال مهمة "عداد" (سيت أب، جري، ما، إلخ)، وكيحسب `done`
  /// أوتوماتيكيا ملي التقدم يوصل للهدف.
  static Future<SystemTask> setProgress(String id, double newProgress, double target) async {
    final clamped = newProgress.clamp(0, target).toDouble();
    final updated = await portalClient
        .from(table)
        .update({'progress': clamped, 'done': clamped >= target})
        .eq('id', id)
        .select()
        .single();
    return SystemTask.fromRow(updated);
  }

  /// كيبدل حالة صلاة وحدة داخل مهمة "5 Prayers"، وكيحسب عدد الصلوات
  /// المكملة كـ`progress`، و`done` ملي الخمسة يكملو.
  static Future<SystemTask> setSubPrayer(
    String id,
    Map<String, bool> currentSubStatus,
    String key,
    bool value,
  ) async {
    final newSub = Map<String, bool>.from(currentSubStatus)..[key] = value;
    final progress = newSub.values.where((v) => v).length.toDouble();
    final updated = await portalClient
        .from(table)
        .update({'sub_status': newSub, 'progress': progress, 'done': progress >= 5})
        .eq('id', id)
        .select()
        .single();
    return SystemTask.fromRow(updated);
  }

  static RealtimeChannel subscribeToday(void Function() onChange) {
    final today = _todayKey();
    return portalClient
        .channel('system-tasks-$today')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'task_date',
            value: today,
          ),
          callback: (_) => onChange(),
        )
        .subscribe();
  }
}
