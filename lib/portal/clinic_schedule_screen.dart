import 'package:flutter/material.dart';
import 'portal_client.dart';

class ClinicScheduleScreen extends StatefulWidget {
  final String employeeId;
  final String? defaultShift;

  const ClinicScheduleScreen({
    super.key,
    required this.employeeId,
    this.defaultShift,
    // ignored — shift comes from employee profile
    String? defaultClinic,
  });

  @override
  State<ClinicScheduleScreen> createState() => _ClinicScheduleScreenState();
}

class _ClinicScheduleScreenState extends State<ClinicScheduleScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  static const _dayNames = {
    7: 'الأحد',
    1: 'الاثنين',
    2: 'الثلاثاء',
    3: 'الأربعاء',
    4: 'الخميس',
    5: 'الجمعة',
    6: 'السبت',
  };

  static const _weekOrder = [6, 7, 1, 2, 3, 4, 5];

  static const _indigo = Color(0xFF06B6D4);
  static const _teal   = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await portalClient
          .from('clinic_schedules')
          .select('*')
          .eq('employee_id', widget.employeeId);
      if (mounted) {
        setState(() {
          _rows = List<Map<String, dynamic>>.from(data as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<int, Map<String, dynamic>> _buildDayMap() {
    final map = <int, Map<String, dynamic>>{};
    for (final row in _rows) {
      final clinic = (row['clinic_number'] as num?)?.toInt() ?? 0;
      final shift  = row['shift'] as String? ?? '';
      final daysStr = row['days'] as String? ?? '';
      for (final part in daysStr.split(',')) {
        final d = int.tryParse(part.trim());
        if (d != null) map[d] = {'clinic': clinic, 'shift': shift};
      }
    }
    return map;
  }

  Map<int, List<String>> _buildSummary(Map<int, Map<String, dynamic>> dayMap) {
    final summary = <int, List<String>>{};
    for (final entry in dayMap.entries) {
      final clinic = entry.value['clinic'] as int;
      summary.putIfAbsent(clinic, () => []);
      summary[clinic]!.add(_dayNames[entry.key] ?? '');
    }
    return summary;
  }

  @override
  Widget build(BuildContext context) {
    final dayMap  = _buildDayMap();  // day → {clinic, shift}
    final summary = _buildSummary(dayMap);
    final todayFw = DateTime.now().weekday == 7 ? 7 : DateTime.now().weekday;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, _indigo],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(color: _teal.withValues(alpha: 0.35), blurRadius: 12),
                  ],
                ),
                child: const Center(
                  child: Text('🦷', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('جدول العيادات',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  SizedBox(height: 2),
                  Text('توزيعك الأسبوعي في العيادات',
                      style: TextStyle(fontSize: 12, color: Color(0x99FFFFFF))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _indigo))
                : _rows.isEmpty
                    ? _EmptyState()
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (summary.isNotEmpty) ...[
                              const Text('ملخص',
                                  style: TextStyle(fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xCCFFFFFF))),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10, runSpacing: 10,
                                children: summary.entries.map((e) =>
                                    _ClinicSummaryCard(
                                      clinic: e.key,
                                      dayNames: e.value,
                                    )).toList(),
                              ),
                              const SizedBox(height: 24),
                            ],

                            const Text('الجدول الأسبوعي',
                                style: TextStyle(fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xCCFFFFFF))),
                            const SizedBox(height: 10),
                            ..._weekOrder.map((fw) {
                              final entry = dayMap[fw];
                              final isOff = entry == null;
                              final isToday = fw == todayFw;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _DayRow(
                                  dayName: _dayNames[fw] ?? '',
                                  isToday: isToday,
                                  isOff: isOff,
                                  clinicNumber: entry?['clinic'] as int?,
                                  shift: entry?['shift'] as String?,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.event_busy_outlined, size: 52,
            color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        const Text('لم يتم تحديد جدول العيادات بعد',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: Color(0x66FFFFFF))),
        const SizedBox(height: 6),
        const Text('يرجى التواصل مع الإدارة',
            style: TextStyle(fontSize: 12, color: Color(0x44FFFFFF))),
      ],
    ),
  );
}

class _ClinicSummaryCard extends StatelessWidget {
  final int clinic;
  final List<String> dayNames;
  const _ClinicSummaryCard({required this.clinic, required this.dayNames});

  static const _teal = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: _teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _teal.withValues(alpha: 0.25)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.door_front_door_outlined, color: _teal, size: 16),
            const SizedBox(width: 6),
            Text('عيادة $clinic',
                style: const TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w700, color: _teal)),
          ],
        ),
        const SizedBox(height: 6),
        Text('${dayNames.length} أيام: ${dayNames.join(' · ')}',
            style: const TextStyle(fontSize: 11, color: Color(0x99FFFFFF))),
      ],
    ),
  );
}

class _DayRow extends StatelessWidget {
  final String dayName;
  final bool isToday;
  final bool isOff;
  final int? clinicNumber;
  final String? shift;

  const _DayRow({
    required this.dayName,
    required this.isToday,
    required this.isOff,
    this.clinicNumber,
    this.shift,
  });

  static const _indigo = Color(0xFF06B6D4);
  static const _teal   = Color(0xFF06B6D4);
  static const _amber  = Color(0xFFF59E0B);
  static const _purple = Color(0xFF0EA5E9);

  bool get _isMorning => (shift ?? '').contains('صباح');

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    final circleAvatar = Container(
      width: 42, height: 42,
      decoration: BoxDecoration(
        color: isToday
            ? _indigo.withValues(alpha: 0.2)
            : isOff
                ? const Color(0x06FFFFFF)
                : _teal.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isToday
            ? Border.all(color: _indigo.withValues(alpha: 0.5), width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          dayName.length >= 2 ? dayName.substring(0, 2) : dayName,
          style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: isToday ? _indigo : isOff
                ? const Color(0x44FFFFFF) : _teal,
          ),
        ),
      ),
    );

    final dayNameSection = Expanded(
      child: Row(
        children: [
          Text(dayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                color: isOff && !isToday
                    ? const Color(0x55FFFFFF) : Colors.white,
              )),
          if (isToday) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _indigo.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _indigo.withValues(alpha: 0.5)),
              ),
              child: const Text('اليوم',
                  style: TextStyle(fontSize: 9, color: _indigo,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ],
      ),
    );

    final Widget trailingSection = isOff
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0x08FFFFFF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('إجازة',
                style: TextStyle(fontSize: 12, color: Color(0x44FFFFFF))),
          )
        : Wrap(
            spacing: 8,
            children: [
              _Badge(
                icon: Icons.door_front_door_outlined,
                label: 'عيادة $clinicNumber',
                color: _teal,
              ),
              if (shift != null && shift!.isNotEmpty)
                _Badge(
                  emoji: _isMorning ? '🌅' : '🌙',
                  label: shift!,
                  color: _isMorning ? _amber : _purple,
                ),
            ],
          );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isToday
            ? _indigo.withValues(alpha: 0.12)
            : isOff
                ? const Color(0x05FFFFFF)
                : const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? _indigo.withValues(alpha: 0.45)
              : const Color(0x14FFFFFF),
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    circleAvatar,
                    const SizedBox(width: 14),
                    dayNameSection,
                  ],
                ),
                const SizedBox(height: 10),
                trailingSection,
              ],
            )
          : Row(
              children: [
                circleAvatar,
                const SizedBox(width: 14),
                dayNameSection,
                trailingSection,
              ],
            ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData? icon;
  final String? emoji;
  final String label;
  final Color color;
  const _Badge({this.icon, this.emoji, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) Icon(icon, color: color, size: 13),
        if (emoji != null) Text(emoji!, style: const TextStyle(fontSize: 11)),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: color,
            fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
