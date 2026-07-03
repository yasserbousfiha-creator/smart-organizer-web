import 'package:flutter/material.dart';
import 'portal_client.dart';

class PortalPayslipScreen extends StatefulWidget {
  final String employeeId;
  const PortalPayslipScreen({super.key, required this.employeeId});

  @override
  State<PortalPayslipScreen> createState() => _PortalPayslipScreenState();
}

class _PortalPayslipScreenState extends State<PortalPayslipScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  int? _selectedIdx;
  bool _showDetail = false;

  static const _indigo = Color(0xFF6366F1);
  static const _months = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
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
          .from('payroll_records')
          .select()
          .eq('employee_id', widget.employeeId)
          .order('year', ascending: false)
          .order('month', ascending: false);
      if (mounted) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
          if (_records.isNotEmpty) { _selectedIdx = 0; }
        });
      }
    } catch (_) {
      if (mounted) { setState(() => _loading = false); }
    }
  }

  String _monthName(int m) => (m > 0 && m < 13) ? _months[m] : '$m';

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────
          Row(
            children: [
              if (isMobile && _showDetail) ...[
                GestureDetector(
                  onTap: () => setState(() => _showDetail = false),
                  child: const Icon(Icons.arrow_back_ios_new,
                      color: Colors.white60, size: 18),
                ),
                const SizedBox(width: 8),
              ],
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('كشف الراتب',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                            color: Colors.white)),
                    SizedBox(height: 2),
                    Text('سجل مستحقاتك الشهرية',
                        style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── المحتوى ───────────────────────────────
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: _indigo)))
          else if (_records.isEmpty)
            Expanded(child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 52, color: Colors.white.withValues(alpha: 0.15)),
                  const SizedBox(height: 12),
                  const Text('لا توجد كشوف رواتب',
                      style: TextStyle(color: Color(0x66FFFFFF), fontSize: 14)),
                ],
              ),
            ))
          else if (isMobile)
            // ── Mobile: قائمة ثم تفاصيل ───────────────
            Expanded(
              child: _showDetail && _selectedIdx != null
                  ? SingleChildScrollView(
                      child: _PayslipDetail(record: _records[_selectedIdx!]))
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final month = r['month'] as int? ?? 0;
                        final year = r['year'] as int? ?? 0;
                        final net = (r['net_salary'] as num?)?.toDouble() ?? 0;
                        return GestureDetector(
                          onTap: () => setState(() {
                            _selectedIdx = i;
                            _showDetail = true;
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x0AFFFFFF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0x14FFFFFF)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: _indigo.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.receipt_long_outlined,
                                      color: _indigo, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(_monthName(month),
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                      Text('$year', style: const TextStyle(
                                          fontSize: 12, color: Color(0x66FFFFFF))),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${net.toStringAsFixed(0)} ريال',
                                        style: const TextStyle(
                                            color: _indigo,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15)),
                                    const Text('صافي',
                                        style: TextStyle(
                                            fontSize: 11, color: Color(0x66FFFFFF))),
                                  ],
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.chevron_left,
                                    color: Color(0x44FFFFFF), size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            )
          else
            // ── Desktop: جنباً لجنب ────────────────────
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // قائمة الأشهر
                  SizedBox(
                    width: 170,
                    child: ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (context, idx) => const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final r = _records[i];
                        final month = r['month'] as int? ?? 0;
                        final year = r['year'] as int? ?? 0;
                        final active = _selectedIdx == i;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedIdx = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: active
                                  ? _indigo.withValues(alpha: 0.15)
                                  : const Color(0x08FFFFFF),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: active
                                      ? _indigo.withValues(alpha: 0.4)
                                      : const Color(0x14FFFFFF)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_monthName(month),
                                    style: TextStyle(
                                        fontWeight: active
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                        color: active
                                            ? Colors.white
                                            : const Color(0x99FFFFFF))),
                                Text('$year',
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0x66FFFFFF))),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // تفاصيل
                  Expanded(
                    child: _selectedIdx != null
                        ? SingleChildScrollView(
                            child: _PayslipDetail(record: _records[_selectedIdx!]))
                        : const SizedBox(),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _PayslipDetail extends StatelessWidget {
  final Map<String, dynamic> record;
  const _PayslipDetail({required this.record});

  static const _months = [
    '', 'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
    'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const _indigo = Color(0xFF6366F1);
  static const _green = Color(0xFF34D399);
  static const _red = Color(0xFFF87171);

  double _d(String key) => (record[key] as num?)?.toDouble() ?? 0;

  @override
  Widget build(BuildContext context) {
    final month = record['month'] as int? ?? 0;
    final year = record['year'] as int? ?? 0;
    final basic = _d('basic_salary');
    final allowances = _d('allowances');
    final commissions = _d('commissions');
    final deductions = _d('deductions');
    final advDeduct = _d('advance_deduction');
    final net = _d('net_salary');
    final monthName = month > 0 && month < 13 ? _months[month] : '$month';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0x08FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // عنوان
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _indigo.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: _indigo, size: 18),
              ),
              const SizedBox(width: 12),
              Text('$monthName $year',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ],
          ),
          const SizedBox(height: 20),

          // الإيرادات
          _sectionHead('الإيرادات', _green),
          const SizedBox(height: 10),
          _Row(label: 'الراتب الأساسي', value: basic, color: _green),
          _Row(label: 'البدلات', value: allowances, color: _green),
          _Row(label: 'العمولات', value: commissions, color: _green),

          const SizedBox(height: 16),

          // الاستقطاعات
          _sectionHead('الاستقطاعات', _red),
          const SizedBox(height: 10),
          _Row(label: 'الاستقطاعات', value: deductions, color: _red, neg: true),
          if (advDeduct > 0)
            _Row(label: 'استقطاع السلفة', value: advDeduct, color: _red, neg: true),

          const SizedBox(height: 20),

          // صافي الراتب
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [_indigo, Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                const Text('صافي الراتب',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 6),
                Text('${net.toStringAsFixed(2)} ريال',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _sectionHead(String label, Color color) => Row(
    children: [
      Container(width: 3, height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
    ],
  );
}

class _Row extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool neg;
  const _Row({required this.label, required this.value, required this.color, this.neg = false});

  @override
  Widget build(BuildContext context) {
    if (value == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF))),
          Text('${neg ? '- ' : '+ '}${value.toStringAsFixed(2)} ريال',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
