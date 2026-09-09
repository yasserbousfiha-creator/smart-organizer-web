import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal_client.dart';
import 'portal_i18n.dart';

class PortalTasksScreen extends StatefulWidget {
  final String employeeId;
  final bool isEnglish;
  const PortalTasksScreen({super.key, required this.employeeId, this.isEnglish = false});

  @override
  State<PortalTasksScreen> createState() => _PortalTasksScreenState();
}

class _PortalTasksScreenState extends State<PortalTasksScreen> {
  List<Map<String, dynamic>> _tasks = [];
  bool _loading = true;
  late final RealtimeChannel _channel;

  static const _indigo = Color(0xFF06B6D4);
  static const _green = Color(0xFF34D399);
  static const _amber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = portalClient
        .channel('emp-tasks-${widget.employeeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'portal_tasks',
          callback: (_) { if (mounted) _load(); },
        )
        .subscribe();
  }

  @override
  void dispose() {
    portalClient.removeChannel(_channel);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final data = await portalClient
          .from('portal_tasks')
          .select()
          .eq('employee_id', widget.employeeId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _tasks = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _completeTask(String id) async {
    try {
      await portalClient.from('portal_tasks').update({
        'status': 'مكتملة',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      await _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final pending = _tasks.where((t) => t['status'] == 'قيد الانتظار').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(widget.isEnglish, 'المهام'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
              widget.isEnglish
                  ? '$pending pending task(s)'
                  : '$pending مهمة قيد الانتظار',
              style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _indigo))
                : _tasks.isEmpty
                    ? _empty(tr(widget.isEnglish, 'لا توجد مهام'))
                    : ListView.separated(
                        itemCount: _tasks.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final t = _tasks[i];
                          final status = t['status'] as String? ?? 'قيد الانتظار';
                          final done = status != 'قيد الانتظار';
                          final color = done ? _green : _amber;
                          final title = t['title'] as String? ?? '';
                          final details = t['details'] as String?;
                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0x0AFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color.withValues(alpha: 0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 38, height: 38,
                                      decoration: BoxDecoration(
                                        color: _indigo.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(Icons.task_alt_outlined, color: _indigo, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(title,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                          if (details != null && details.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(details, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: color.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(tr(widget.isEnglish, status),
                                          style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                if (!done) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FilledButton.icon(
                                      onPressed: () => _completeTask(t['id'] as String),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: Text(tr(widget.isEnglish, 'إنهاء المهمة'), style: const TextStyle(fontSize: 13)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

Widget _empty(String msg) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.task_alt_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
    ],
  ),
);
