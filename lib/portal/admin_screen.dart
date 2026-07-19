import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal_client.dart';
import 'portal_i18n.dart';

class AdminScreen extends StatefulWidget {
  final bool isEnglish;
  const AdminScreen({super.key, this.isEnglish = false});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  static const _bg = Color(0xFF061A22);
  static const _indigo = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: const Color(0xFF061A22),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [_indigo, Color(0xFF0EA5E9)]),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Text(tr(widget.isEnglish, 'لوحة الإدارة'),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: _indigo,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0x66FFFFFF),
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: [
            Tab(icon: const Icon(Icons.beach_access_outlined, size: 18),
                text: tr(widget.isEnglish, 'الإجازات')),
            Tab(icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                text: tr(widget.isEnglish, 'السلف')),
            Tab(icon: const Icon(Icons.people_outline, size: 18),
                text: tr(widget.isEnglish, 'الموظفون')),
            Tab(icon: const Icon(Icons.access_time_outlined, size: 18),
                text: tr(widget.isEnglish, 'الدوامات')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _LeavesTab(isEnglish: widget.isEnglish),
          _AdvancesTab(isEnglish: widget.isEnglish),
          _EmployeesTab(isEnglish: widget.isEnglish),
          _ShiftsTab(isEnglish: widget.isEnglish),
        ],
      ),
    );
  }
}

// ── Leaves Tab ─────────────────────────────────────────────────
class _LeavesTab extends StatefulWidget {
  final bool isEnglish;
  const _LeavesTab({this.isEnglish = false});
  @override
  State<_LeavesTab> createState() => _LeavesTabState();
}

class _LeavesTabState extends State<_LeavesTab> {
  List<Map<String, dynamic>> _requests = [];
  Map<String, Map<String, dynamic>> _empMap = {};
  bool _loading = true;
  String _filter = 'قيد المراجعة';
  String? _error;
  late final RealtimeChannel _channel;

  static const _indigo = Color(0xFF06B6D4);
  static const _green = Color(0xFF34D399);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFF87171);
  static const _surface = Color(0xFF0D2731);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = portalClient
        .channel('admin-leaves-tab')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leave_requests',
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
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        portalClient.from('leave_requests').select().order('submitted_at', ascending: false),
        portalClient.from('employee_profiles').select('id, name, department'),
      ]);
      final requests = List<Map<String, dynamic>>.from(results[0] as List);
      final emps = List<Map<String, dynamic>>.from(results[1] as List);
      final empMap = <String, Map<String, dynamic>>{
        for (final e in emps) e['id'].toString(): e,
      };
      if (mounted) {
        setState(() {
          _requests = requests;
          _empMap = empMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await portalClient
          .from('leave_requests')
          .update({'status': status})
          .eq('id', id);
      await _load();
      if (mounted) {
        _snack(status == 'موافق عليها' ? tr(widget.isEnglish, 'تمت الموافقة') : tr(widget.isEnglish, 'تم الرفض'),
            status == 'موافق عليها' ? _green : _red);
      }
    } catch (e) {
      if (mounted) _snack(widget.isEnglish ? 'Error: $e' : 'خطأ: $e', _red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Color _statusColor(String status) {
    if (status == 'موافق عليها') return _green;
    if (status == 'مرفوضة') return _red;
    return _amber;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'الكل') return _requests;
    return _requests.where((r) => r['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _indigo));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    final filterChips = [
      for (final f in ['قيد المراجعة', 'موافق عليها', 'مرفوضة', 'الكل'])
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _filter == f
                    ? _indigo
                    : const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filter == f
                      ? _indigo
                      : const Color(0x1AFFFFFF),
                ),
              ),
              child: Text(tr(widget.isEnglish, f),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: _filter == f
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _filter == f
                          ? Colors.white
                          : const Color(0x99FFFFFF))),
            ),
          ),
        ),
    ];
    final refreshButton = IconButton(
      icon: const Icon(Icons.refresh, color: Color(0x99FFFFFF), size: 18),
      onPressed: _load,
      tooltip: tr(widget.isEnglish, 'تحديث'),
    );

    return Column(
      children: [
        // Filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isMobile
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [...filterChips, refreshButton],
                )
              : Row(
                  children: [
                    ...filterChips,
                    const Spacer(),
                    refreshButton,
                  ],
                ),
        ),

        // List
        Expanded(
          child: _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(widget.isEnglish ? 'Error: $_error' : 'خطأ: $_error',
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                ))
              : _filtered.isEmpty
              ? Center(
                  child: Text(tr(widget.isEnglish, 'لا توجد طلبات'),
                      style: const TextStyle(color: Color(0x66FFFFFF))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final req = _filtered[i];
                    final empId = req['employee_id']?.toString() ?? '';
                    final empData = _empMap[empId];
                    final empName = empData?['name'] as String? ?? empId.substring(0, empId.length.clamp(0, 8));
                    final dept = empData?['department'] as String? ?? '';
                    final type = req['type'] as String? ?? '';
                    final status = req['status'] as String? ?? 'قيد الانتظار';
                    final start = req['start_date'] as String? ?? '';
                    final end = req['end_date'] as String? ?? '';
                    final reason = req['reason'] as String? ?? '';
                    final submittedAt = req['submitted_at'] as String?;

                    String fmtDate(String d) {
                      try {
                        return intl.DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(d));
                      } catch (_) {
                        return d;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _statusColor(status).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(empName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    if (dept.isNotEmpty)
                                      Text(dept,
                                          style: const TextStyle(
                                              color: Color(0x66FFFFFF),
                                              fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(tr(widget.isEnglish, status),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _infoChip(Icons.category_outlined, tr(widget.isEnglish, type)),
                              _infoChip(Icons.calendar_today_outlined,
                                  '${fmtDate(start)} → ${fmtDate(end)}'),
                              if (submittedAt != null)
                                _infoChip(Icons.schedule_outlined,
                                    fmtDate(submittedAt)),
                            ],
                          ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(reason,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0x99FFFFFF),
                                    height: 1.5)),
                          ],
                          if (status == 'قيد المراجعة') ...[
                            const SizedBox(height: 12),
                            isMobile
                                ? Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'رفض'),
                                        color: _red,
                                        icon: Icons.close_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(), 'مرفوضة'),
                                      ),
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'موافقة'),
                                        color: _green,
                                        icon: Icons.check_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(),
                                            'موافق عليها'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'رفض'),
                                        color: _red,
                                        icon: Icons.close_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(), 'مرفوضة'),
                                      ),
                                      const SizedBox(width: 8),
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'موافقة'),
                                        color: _green,
                                        icon: Icons.check_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(),
                                            'موافق عليها'),
                                      ),
                                    ],
                                  ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0x66FFFFFF)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: Color(0x99FFFFFF))),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Advances Tab ───────────────────────────────────────────────
class _AdvancesTab extends StatefulWidget {
  final bool isEnglish;
  const _AdvancesTab({this.isEnglish = false});
  @override
  State<_AdvancesTab> createState() => _AdvancesTabState();
}

class _AdvancesTabState extends State<_AdvancesTab> {
  List<Map<String, dynamic>> _requests = [];
  Map<String, Map<String, dynamic>> _empMap = {};
  bool _loading = true;
  String _filter = 'قيد المراجعة';
  String? _error;
  late final RealtimeChannel _channel;

  static const _indigo = Color(0xFF06B6D4);
  static const _green = Color(0xFF34D399);
  static const _amber = Color(0xFFF59E0B);
  static const _red = Color(0xFFF87171);
  static const _surface = Color(0xFF0D2731);

  @override
  void initState() {
    super.initState();
    _load();
    _channel = portalClient
        .channel('admin-advances-tab')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'advance_requests',
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
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        portalClient.from('advance_requests').select().order('submitted_at', ascending: false),
        portalClient.from('employee_profiles').select('id, name, department'),
      ]);
      final requests = List<Map<String, dynamic>>.from(results[0] as List);
      final emps = List<Map<String, dynamic>>.from(results[1] as List);
      final empMap = <String, Map<String, dynamic>>{
        for (final e in emps) e['id'].toString(): e,
      };
      if (mounted) {
        setState(() {
          _requests = requests;
          _empMap = empMap;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = e.toString(); });
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await portalClient
          .from('advance_requests')
          .update({'status': status})
          .eq('id', id);
      await _load();
      if (mounted) {
        _snack(status == 'موافق عليها' ? tr(widget.isEnglish, 'تمت الموافقة') : tr(widget.isEnglish, 'تم الرفض'),
            status == 'موافق عليها' ? _green : _red);
      }
    } catch (e) {
      if (mounted) _snack(widget.isEnglish ? 'Error: $e' : 'خطأ: $e', _red);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Color _statusColor(String status) {
    if (status == 'موافق عليها') return _green;
    if (status == 'مرفوضة') return _red;
    return _amber;
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'الكل') return _requests;
    return _requests.where((r) => r['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _indigo));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    final filterChips = [
      for (final f in ['قيد المراجعة', 'موافق عليها', 'مرفوضة', 'الكل'])
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: GestureDetector(
            onTap: () => setState(() => _filter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _filter == f
                    ? _indigo
                    : const Color(0x0AFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _filter == f
                      ? _indigo
                      : const Color(0x1AFFFFFF),
                ),
              ),
              child: Text(tr(widget.isEnglish, f),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: _filter == f
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: _filter == f
                          ? Colors.white
                          : const Color(0x99FFFFFF))),
            ),
          ),
        ),
    ];
    final refreshButton = IconButton(
      icon: const Icon(Icons.refresh, color: Color(0x99FFFFFF), size: 18),
      onPressed: _load,
      tooltip: tr(widget.isEnglish, 'تحديث'),
    );

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: isMobile
              ? Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [...filterChips, refreshButton],
                )
              : Row(
                  children: [
                    ...filterChips,
                    const Spacer(),
                    refreshButton,
                  ],
                ),
        ),
        Expanded(
          child: _error != null
              ? Center(child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(widget.isEnglish ? 'Error: $_error' : 'خطأ: $_error',
                      style: const TextStyle(color: Color(0xFFF87171), fontSize: 12)),
                ))
              : _filtered.isEmpty
              ? Center(
                  child: Text(tr(widget.isEnglish, 'لا توجد طلبات'),
                      style: const TextStyle(color: Color(0x66FFFFFF))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final req = _filtered[i];
                    final empId = req['employee_id']?.toString() ?? '';
                    final empData = _empMap[empId];
                    final empName = empData?['name'] as String? ??
                        (req['employee_name'] as String? ??
                            empId.substring(0, empId.length.clamp(0, 8)));
                    final dept = empData?['department'] as String? ?? '';
                    final status = req['status'] as String? ?? 'قيد الانتظار';
                    final amount = (req['amount'] as num?)?.toDouble() ?? 0;
                    final remaining = (req['remaining_amount'] as num?)?.toDouble() ?? amount;
                    final monthly = (req['monthly_deduction'] as num?)?.toDouble() ?? 0;
                    final reason = req['reason'] as String? ?? '';
                    final submittedAt = req['submitted_at'] as String?;

                    String fmtDate(String d) {
                      try {
                        return intl.DateFormat('dd/MM/yyyy')
                            .format(DateTime.parse(d));
                      } catch (_) {
                        return d;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _statusColor(status).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(empName,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    if (dept.isNotEmpty)
                                      Text(dept,
                                          style: const TextStyle(
                                              color: Color(0x66FFFFFF),
                                              fontSize: 11)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _statusColor(status)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: _statusColor(status)
                                          .withValues(alpha: 0.4)),
                                ),
                                child: Text(tr(widget.isEnglish, status),
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _statusColor(status))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            children: [
                              _infoChip(Icons.payments_outlined,
                                  '${amount.toStringAsFixed(0)} ${tr(widget.isEnglish, 'ريال')}'),
                              _infoChip(Icons.account_balance_wallet_outlined,
                                  '${tr(widget.isEnglish, 'المتبقي')}: ${remaining.toStringAsFixed(0)}'),
                              _infoChip(Icons.calendar_month_outlined,
                                  '${tr(widget.isEnglish, 'شهري')}: ${monthly.toStringAsFixed(0)}'),
                              if (submittedAt != null)
                                _infoChip(Icons.schedule_outlined,
                                    fmtDate(submittedAt)),
                            ],
                          ),
                          if (reason.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(reason,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0x99FFFFFF),
                                    height: 1.5)),
                          ],
                          if (status == 'قيد المراجعة') ...[
                            const SizedBox(height: 12),
                            isMobile
                                ? Wrap(
                                    alignment: WrapAlignment.end,
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'رفض'),
                                        color: _red,
                                        icon: Icons.close_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(), 'مرفوضة'),
                                      ),
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'موافقة'),
                                        color: _green,
                                        icon: Icons.check_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(),
                                            'موافق عليها'),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'رفض'),
                                        color: _red,
                                        icon: Icons.close_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(), 'مرفوضة'),
                                      ),
                                      const SizedBox(width: 8),
                                      _actionBtn(
                                        label: tr(widget.isEnglish, 'موافقة'),
                                        color: _green,
                                        icon: Icons.check_rounded,
                                        onTap: () => _updateStatus(
                                            req['id'].toString(),
                                            'موافق عليها'),
                                      ),
                                    ],
                                  ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0x66FFFFFF)),
        const SizedBox(width: 4),
        Text(text,
            style: const TextStyle(
                fontSize: 12, color: Color(0x99FFFFFF))),
      ],
    );
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Employees Tab ───────────────────────────────────────────────
class _EmployeesTab extends StatefulWidget {
  final bool isEnglish;
  const _EmployeesTab({this.isEnglish = false});
  @override
  State<_EmployeesTab> createState() => _EmployeesTabState();
}

class _EmployeesTabState extends State<_EmployeesTab> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String _search = '';

  static const _indigo = Color(0xFF06B6D4);
  static const _surface = Color(0xFF0D2731);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await portalClient
          .from('employee_profiles')
          .select()
          .order('name');
      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _employees;
    final q = _search.trim().toLowerCase();
    return _employees.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      final dept = (e['department'] as String? ?? '').toLowerCase();
      return name.contains(q) || dept.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _indigo));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr(widget.isEnglish, 'بحث باسم الموظف أو القسم...'),
                    hintStyle:
                        const TextStyle(color: Color(0x55FFFFFF), fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0x55FFFFFF), size: 18),
                    filled: true,
                    fillColor: const Color(0x0AFFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _indigo, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0x99FFFFFF), size: 18),
                onPressed: _load,
                tooltip: tr(widget.isEnglish, 'تحديث'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            widget.isEnglish ? '${_filtered.length} employee(s)' : '${_filtered.length} موظف',
            style: const TextStyle(
                fontSize: 12, color: Color(0x55FFFFFF)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(tr(widget.isEnglish, 'لا توجد نتائج'),
                      style: const TextStyle(color: Color(0x66FFFFFF))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final emp = _filtered[i];
                    final name = emp['name'] as String? ?? '—';
                    final dept = emp['department'] as String? ?? '—';
                    final shift = emp['shift'] as String? ?? '—';
                    final status = emp['status'] as String? ?? '—';
                    final phone = emp['phone'] as String? ?? '';
                    final clinicNum = emp['clinic_number'];

                    final avatar = Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                              color: _indigo,
                              fontWeight: FontWeight.w700,
                              fontSize: 17),
                        ),
                      ),
                    );
                    final nameColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                        const SizedBox(height: 2),
                        Text('$dept  •  ${tr(widget.isEnglish, shift)}',
                            style: const TextStyle(
                                color: Color(0x99FFFFFF),
                                fontSize: 11)),
                        if (phone.isNotEmpty)
                          Text(phone,
                              style: const TextStyle(
                                  color: Color(0x66FFFFFF),
                                  fontSize: 11)),
                      ],
                    );
                    final statusBadge = Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: status == 'نشط'
                            ? const Color(0xFF34D399)
                                .withValues(alpha: 0.12)
                            : Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(tr(widget.isEnglish, status),
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: status == 'نشط'
                                  ? const Color(0xFF34D399)
                                  : Colors.redAccent)),
                    );
                    final clinicText = clinicNum != null
                        ? Text('${widget.isEnglish ? 'Clinic' : 'عيادة'} $clinicNum',
                            style: const TextStyle(
                                fontSize: 10, color: Color(0x66FFFFFF)))
                        : null;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0x14FFFFFF)),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    avatar,
                                    const SizedBox(width: 12),
                                    Expanded(child: nameColumn),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    statusBadge,
                                    ?clinicText,
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                avatar,
                                const SizedBox(width: 12),
                                Expanded(child: nameColumn),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.end,
                                  children: [
                                    statusBadge,
                                    if (clinicText != null) ...[
                                      const SizedBox(height: 4),
                                      clinicText,
                                    ],
                                  ],
                                ),
                              ],
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Shifts Tab ──────────────────────────────────────────────────
class _ShiftsTab extends StatefulWidget {
  final bool isEnglish;
  const _ShiftsTab({this.isEnglish = false});
  @override
  State<_ShiftsTab> createState() => _ShiftsTabState();
}

class _ShiftsTabState extends State<_ShiftsTab> {
  List<Map<String, dynamic>> _employees = [];
  bool _loading = true;
  String _search = '';

  static const _indigo = Color(0xFF06B6D4);
  static const _surface = Color(0xFF0D2731);
  static const _green = Color(0xFF34D399);
  static const _red = Color(0xFFF87171);

  static const _shiftOptions = [
    'صباحي',
    'مسائي',
    'صباحي + مسائي',
    'متناوب',
    'إداري',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await portalClient
          .from('employee_profiles')
          .select('id, name, department, shift, status')
          .order('name');
      if (mounted) {
        setState(() {
          _employees = List<Map<String, dynamic>>.from(data);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateShift(String empId, String newShift) async {
    try {
      await portalClient
          .from('employee_profiles')
          .update({'shift': newShift})
          .eq('id', empId);
      setState(() {
        final idx = _employees.indexWhere((e) => e['id'] == empId);
        if (idx != -1) _employees[idx] = {..._employees[idx], 'shift': newShift};
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(tr(widget.isEnglish, 'تم تحديث الدوام')),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.isEnglish ? 'Error: $e' : 'خطأ: $e'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  void _showEditSheet(Map<String, dynamic> emp) {
    final name = emp['name'] as String? ?? '—';
    String selected = emp['shift'] as String? ?? _shiftOptions[0];

    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Directionality(
        textDirection: widget.isEnglish ? TextDirection.ltr : TextDirection.rtl,
        child: StatefulBuilder(
        builder: (ctx, setLocal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  widget.isEnglish ? 'Change Shift: $name' : 'تغيير دوام: $name',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              ...List.generate(_shiftOptions.length, (i) {
                final opt = _shiftOptions[i];
                final isSelected = opt == selected;
                return GestureDetector(
                  onTap: () => setLocal(() => selected = opt),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _indigo.withValues(alpha: 0.15)
                          : const Color(0x0AFFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected
                              ? _indigo.withValues(alpha: 0.5)
                              : const Color(0x1AFFFFFF)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: isSelected
                              ? _indigo
                              : const Color(0x55FFFFFF),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(tr(widget.isEnglish, opt),
                            style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0x99FFFFFF),
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal)),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0x66FFFFFF),
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(tr(widget.isEnglish, 'إلغاء')),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updateShift(emp['id'].toString(), selected);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _indigo,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(tr(widget.isEnglish, 'حفظ'),
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.trim().isEmpty) return _employees;
    final q = _search.trim().toLowerCase();
    return _employees.where((e) {
      final name = (e['name'] as String? ?? '').toLowerCase();
      final dept = (e['department'] as String? ?? '').toLowerCase();
      return name.contains(q) || dept.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: _indigo));
    }

    final isMobile = MediaQuery.of(context).size.width < 700;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style:
                      const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: tr(widget.isEnglish, 'بحث...'),
                    hintStyle: const TextStyle(
                        color: Color(0x55FFFFFF), fontSize: 13),
                    prefixIcon: const Icon(Icons.search,
                        color: Color(0x55FFFFFF), size: 18),
                    filled: true,
                    fillColor: const Color(0x0AFFFFFF),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: Color(0x1AFFFFFF)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: _indigo, width: 1.5),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh,
                    color: Color(0x99FFFFFF), size: 18),
                onPressed: _load,
                tooltip: tr(widget.isEnglish, 'تحديث'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filtered.isEmpty
              ? Center(
                  child: Text(tr(widget.isEnglish, 'لا توجد نتائج'),
                      style: const TextStyle(color: Color(0x66FFFFFF))))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  itemCount: _filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final emp = _filtered[i];
                    final name = emp['name'] as String? ?? '—';
                    final dept = emp['department'] as String? ?? '—';
                    final shift = emp['shift'] as String? ?? '—';

                    final avatar = Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _indigo.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          name.isNotEmpty ? name[0] : '?',
                          style: const TextStyle(
                              color: _indigo,
                              fontWeight: FontWeight.w700,
                              fontSize: 16),
                        ),
                      ),
                    );
                    final nameColumn = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(dept,
                            style: const TextStyle(
                                color: Color(0x66FFFFFF),
                                fontSize: 11)),
                      ],
                    );
                    final shiftButton = GestureDetector(
                      onTap: () => _showEditSheet(emp),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _indigo.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: _indigo.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(tr(widget.isEnglish, shift),
                                style: const TextStyle(
                                    color: _indigo,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(width: 5),
                            const Icon(Icons.edit_outlined,
                                size: 13, color: _indigo),
                          ],
                        ),
                      ),
                    );

                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0x14FFFFFF)),
                      ),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    avatar,
                                    const SizedBox(width: 12),
                                    Expanded(child: nameColumn),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: shiftButton,
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                avatar,
                                const SizedBox(width: 12),
                                Expanded(child: nameColumn),
                                shiftButton,
                              ],
                            ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
