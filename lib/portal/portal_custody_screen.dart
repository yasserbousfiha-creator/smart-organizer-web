import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal_client.dart';
import 'portal_i18n.dart';

class PortalCustodyScreen extends StatefulWidget {
  final String employeeId;
  final bool isEnglish;
  const PortalCustodyScreen({super.key, required this.employeeId, this.isEnglish = false});

  @override
  State<PortalCustodyScreen> createState() => _PortalCustodyScreenState();
}

class _PortalCustodyScreenState extends State<PortalCustodyScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  late final RealtimeChannel _channel;

  static const _indigo = Color(0xFF06B6D4);
  static const _green = Color(0xFF34D399);
  static const _amber = Color(0xFFF59E0B);
  static const _blue = Color(0xFF0EA5E9);
  static const _grey = Color(0xFF9CA3AF);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = portalClient
        .channel('emp-custody-${widget.employeeId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'portal_custody_items',
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
          .from('portal_custody_items')
          .select()
          .eq('employee_id', widget.employeeId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _items = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmReceived(String id) async {
    try {
      await portalClient.from('portal_custody_items').update({
        'status': 'مستلم',
        'received_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      await _load();
    } catch (_) {}
  }

  Future<void> _initiateReturn(String id) async {
    try {
      await portalClient.from('portal_custody_items').update({
        'status': 'قيد الإعادة',
        'return_initiated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      await _load();
    } catch (_) {}
  }

  Color _colorForStatus(String status) {
    switch (status) {
      case 'مستلم':
        return _green;
      case 'قيد الإعادة':
        return _blue;
      case 'أعيدت للإدارة':
        return _grey;
      default:
        return _amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _items.where((t) => t['status'] == 'بانتظار الاستلام').length;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr(widget.isEnglish, 'عهدتي'),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 2),
          Text(
              widget.isEnglish
                  ? '$pending item(s) awaiting confirmation'
                  : '$pending عنصر بانتظار تأكيد الاستلام',
              style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _indigo))
                : _items.isEmpty
                    ? _empty(tr(widget.isEnglish, 'لا توجد عهد'))
                    : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final it = _items[i];
                          final status = it['status'] as String? ?? 'بانتظار الاستلام';
                          final color = _colorForStatus(status);
                          final name = it['equipment_name'] as String? ?? '';
                          final notes = it['notes'] as String?;
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
                                      child: const Icon(Icons.inventory_2_outlined, color: _indigo, size: 18),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                                          if (notes != null && notes.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(notes, style: const TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
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
                                if (status == 'بانتظار الاستلام') ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: FilledButton.icon(
                                      onPressed: () => _confirmReceived(it['id'] as String),
                                      icon: const Icon(Icons.check_circle_outline, size: 16),
                                      label: Text(tr(widget.isEnglish, 'تم الاستلام'), style: const TextStyle(fontSize: 13)),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _green,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    ),
                                  ),
                                ] else if (status == 'مستلم') ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: OutlinedButton.icon(
                                      onPressed: () => _initiateReturn(it['id'] as String),
                                      icon: const Icon(Icons.assignment_return_outlined, size: 16),
                                      label: Text(tr(widget.isEnglish, 'إعادة العهدة للإدارة'), style: const TextStyle(fontSize: 13)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _blue,
                                        side: BorderSide(color: _blue.withValues(alpha: 0.5)),
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
      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.white.withValues(alpha: 0.2)),
      const SizedBox(height: 10),
      Text(msg, style: const TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
    ],
  ),
);
