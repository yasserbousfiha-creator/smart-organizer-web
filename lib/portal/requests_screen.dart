import 'package:flutter/material.dart';
import 'portal_client.dart';

class PortalRequestsScreen extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  const PortalRequestsScreen(
      {super.key, required this.employeeId, required this.employeeName});

  @override
  State<PortalRequestsScreen> createState() => _PortalRequestsScreenState();
}

class _PortalRequestsScreenState extends State<PortalRequestsScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  bool _sending = false;

  static const _indigo = Color(0xFF6366F1);
  static const _bg = Color(0x0AFFFFFF);
  static const _border = Color(0x14FFFFFF);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    try {
      final data = await portalClient
          .from('general_requests')
          .select()
          .eq('employee_id', widget.employeeId)
          .order('submitted_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _requests = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // كم يوماً تبقّى حتى يُرفع الحظر على نوع معيّن (0 = مسموح)
  int _cooldownDaysLeft(String type) {
    final now = DateTime.now();
    for (final r in _requests) {
      if ((r['request_type'] as String?) == type) {
        final submitted = r['submitted_at'] as String?;
        if (submitted == null) continue;
        try {
          final dt = DateTime.parse(submitted);
          final diff = now.difference(dt).inDays;
          if (diff < 30) return 30 - diff;
        } catch (_) {}
      }
    }
    return 0;
  }

  Future<void> _submitRequest(String type, {String? details}) async {
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await portalClient.from('general_requests').insert({
        'employee_id': widget.employeeId,
        'employee_name': widget.employeeName,
        'request_type': type,
        if (details != null && details.isNotEmpty) 'details': details,
        'status': 'قيد المراجعة',
      });
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال الطلب بنجاح'),
            backgroundColor: Color(0xFF34D399),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل إرسال الطلب: ${e.toString().contains('relation') ? 'يرجى التواصل مع المسؤول لإعداد النظام' : e.toString()}'),
            backgroundColor: const Color(0xFFF87171),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _showCustomDialog() async {
    final typeCtrl = TextEditingController();
    final detailsCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('طلب جديد',
              style: TextStyle(color: Colors.white, fontSize: 17, fontFamily: 'Tajawal')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: typeCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                decoration: _fieldDec('نوع الطلب (مثال: خطاب بنكي، إجازة طارئة...)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsCtrl,
                style: const TextStyle(color: Colors.white, fontFamily: 'Tajawal'),
                maxLines: 3,
                decoration: _fieldDec('تفاصيل إضافية (اختياري)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء',
                  style: TextStyle(color: Color(0x99FFFFFF), fontFamily: 'Tajawal')),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _indigo),
              onPressed: () {
                final t = typeCtrl.text.trim();
                if (t.isNotEmpty) {
                  Navigator.pop(ctx);
                  _submitRequest(t, details: detailsCtrl.text.trim());
                }
              },
              child: const Text('إرسال', style: TextStyle(fontFamily: 'Tajawal')),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0x66FFFFFF), fontSize: 13, fontFamily: 'Tajawal'),
        filled: true,
        fillColor: const Color(0x0AFFFFFF),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x14FFFFFF))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0x14FFFFFF))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _indigo)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      );

  Color _statusColor(String s) {
    switch (s) {
      case 'موافق عليها':
        return const Color(0xFF34D399);
      case 'مرفوضة':
        return const Color(0xFFF87171);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final xpDays = _cooldownDaysLeft('شهادة خبرة');
    final salDays = _cooldownDaysLeft('شهادة راتب');

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── الرأس ──
          const Text('الطلبات',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('إرسال طلباتك الرسمية إلى الإدارة',
              style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
          const SizedBox(height: 20),

          // ── أزرار الطلبات ──
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ReqBtn(
                icon: Icons.workspace_premium_outlined,
                label: 'شهادة خبرة',
                color: _indigo,
                cooldownDays: xpDays,
                onTap: (_sending || xpDays > 0) ? null : () => _submitRequest('شهادة خبرة'),
              ),
              _ReqBtn(
                icon: Icons.receipt_outlined,
                label: 'شهادة راتب',
                color: const Color(0xFF8B5CF6),
                cooldownDays: salDays,
                onTap: (_sending || salDays > 0) ? null : () => _submitRequest('شهادة راتب'),
              ),
              _ReqBtn(
                icon: Icons.add_circle_outline,
                label: 'طلب آخر',
                color: const Color(0xFFF59E0B),
                cooldownDays: 0,
                onTap: _sending ? null : _showCustomDialog,
              ),
            ],
          ),

          if (_sending)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _indigo)),
                  SizedBox(width: 8),
                  Text('جاري الإرسال...', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // ── فاصل ──
          Container(
            height: 1,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Color(0x33FFFFFF), Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── عنوان الطلبات السابقة ──
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                decoration: BoxDecoration(
                  color: _indigo,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              const Text('الطلبات السابقة',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0x99FFFFFF))),
            ],
          ),
          const SizedBox(height: 12),

          // ── قائمة الطلبات ──
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _indigo))
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 48, color: Colors.white.withValues(alpha: 0.12)),
                            const SizedBox(height: 12),
                            const Text('لا توجد طلبات سابقة',
                                style: TextStyle(color: Color(0x66FFFFFF), fontSize: 13)),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _requests.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final r = _requests[i];
                          final status = r['status'] as String? ?? 'قيد المراجعة';
                          final type = r['request_type'] as String? ?? '';
                          final details = r['details'] as String?;
                          final response = r['response'] as String?;
                          final submittedAt = r['submitted_at'] as String? ?? '';
                          String dateStr = '';
                          try {
                            final dt = DateTime.parse(submittedAt).toLocal();
                            dateStr =
                                '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}';
                          } catch (_) {
                            dateStr = submittedAt.length >= 10 ? submittedAt.substring(0, 10) : submittedAt;
                          }
                          final sc = _statusColor(status);

                          return Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(type,
                                          style: const TextStyle(
                                              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: sc.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: sc.withValues(alpha: 0.3)),
                                      ),
                                      child: Text(status,
                                          style: TextStyle(
                                              color: sc, fontSize: 12, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                if (details != null && details.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(details,
                                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_outlined,
                                        size: 11, color: Color(0x55FFFFFF)),
                                    const SizedBox(width: 4),
                                    Text(dateStr,
                                        style: const TextStyle(color: Color(0x55FFFFFF), fontSize: 11)),
                                  ],
                                ),
                                if (response != null && response.isNotEmpty) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF34D399).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: const Color(0xFF34D399).withValues(alpha: 0.25)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.comment_outlined,
                                            size: 13, color: Color(0xFF34D399)),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(response,
                                              style: const TextStyle(
                                                  color: Color(0xFF34D399), fontSize: 12)),
                                        ),
                                      ],
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

class _ReqBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int cooldownDays;
  final VoidCallback? onTap;

  const _ReqBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.cooldownDays,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final activeColor = disabled ? const Color(0xFF64748B) : color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: activeColor.withValues(alpha: disabled ? 0.05 : 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: activeColor.withValues(alpha: disabled ? 0.15 : 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: activeColor, size: 18),
                  const SizedBox(width: 8),
                  Text(label,
                      style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13)),
                ],
              ),
              if (disabled && cooldownDays > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'متاح بعد $cooldownDays يوم',
                    style: const TextStyle(color: Color(0x88FFFFFF), fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
