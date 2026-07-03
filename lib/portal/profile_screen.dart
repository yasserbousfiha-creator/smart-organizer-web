import 'package:flutter/material.dart';

class PortalProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const PortalProfileScreen({super.key, this.profile});

  static const _indigo = Color(0xFF6366F1);

  @override
  Widget build(BuildContext context) {
    final p = profile ?? {};
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الملف الشخصي',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 6),
          const Text('بياناتك الوظيفية', style: TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
          const SizedBox(height: 28),
          Row(
            children: [
              _buildAvatar(p),
              const SizedBox(width: 18),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p['name'] as String? ?? '—',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('رقم الموظف: ${p['employee_number'] ?? '—'}',
                      style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── بطاقة الراتب ──
                  if (p['salary'] != null) ...[
                    _SalaryCard(salary: (p['salary'] as num).toDouble()),
                    const SizedBox(height: 20),
                  ],

                  // ── بطاقة العيادة (للأطباء والممرضين) ──
                  if (p['clinic_number'] != null) ...[
                    _ClinicCard(
                      clinicNumber: p['clinic_number'].toString(),
                      shift: p['shift'] as String? ?? '—',
                      department: p['department'] as String? ?? '',
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── البيانات العامة ──
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _InfoCard(label: 'القسم', value: p['department'] ?? '—', icon: Icons.business_center_outlined),
                      _InfoCard(label: 'الدوام', value: p['shift'] ?? '—', icon: Icons.access_time_outlined),
                      _InfoCard(label: 'الجنسية', value: p['nationality'] ?? '—', icon: Icons.flag_outlined),
                      _InfoCard(label: 'الهاتف', value: p['phone'] ?? '—', icon: Icons.phone_outlined),
                      _InfoCard(label: 'البريد الإلكتروني', value: p['email'] ?? '—', icon: Icons.email_outlined),
                      _InfoCard(label: 'الحالة الوظيفية', value: p['status'] ?? '—', icon: Icons.check_circle_outline),
                      _InfoCard(
                        label: 'تاريخ بداية العقد',
                        value: p['contract_start_date'] ?? '—',
                        icon: Icons.calendar_today_outlined,
                      ),
                      _InfoCard(
                        label: 'تاريخ نهاية العقد',
                        value: p['contract_end_date'] ?? '—',
                        icon: Icons.event_outlined,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(Map<String, dynamic> p) {
    final name = p['name'] as String? ?? '?';
    final photoUrl = p['photo_url'] as String?;
    final initial = name.isNotEmpty ? name[0] : '?';

    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.network(
          photoUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) => progress == null
              ? child
              : Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_indigo, Color(0xFF8B5CF6)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  ),
                ),
          errorBuilder: (ctx, e, st) => _avatarFallback(initial),
        ),
      );
    }
    return _avatarFallback(initial);
  }

  Widget _avatarFallback(String initial) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_indigo, Color(0xFF8B5CF6)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
              fontSize: 28, color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ── بطاقة الراتب الأساسي ──
class _SalaryCard extends StatelessWidget {
  final double salary;
  const _SalaryCard({required this.salary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF312E81), Color(0xFF1E1B4B)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x336366F1)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0x336366F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF818CF8), size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('الراتب الأساسي الشهري',
                  style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${salary.toStringAsFixed(salary.truncateToDouble() == salary ? 0 : 2)} ريال',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── بطاقة العيادة ──
class _ClinicCard extends StatelessWidget {
  final String clinicNumber;
  final String shift;
  final String department;
  const _ClinicCard(
      {required this.clinicNumber,
      required this.shift,
      required this.department});

  @override
  Widget build(BuildContext context) {
    final shiftColor = shift.contains('صباح')
        ? const Color(0xFFF59E0B)
        : const Color(0xFF818CF8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0x0A34D399),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x2534D399)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: const Color(0x1A34D399),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_hospital_outlined,
                    color: Color(0xFF34D399), size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (department.isNotEmpty)
                    Text(department,
                        style: const TextStyle(
                            color: Color(0x99FFFFFF), fontSize: 11)),
                  const Text('بيانات العيادة',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ClinicChip(
                icon: Icons.door_front_door_outlined,
                label: 'عيادة رقم $clinicNumber',
                color: const Color(0xFF34D399),
              ),
              const SizedBox(width: 10),
              _ClinicChip(
                icon: Icons.schedule_outlined,
                label: 'دوام $shift',
                color: shiftColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ClinicChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ClinicChip(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── بطاقة بيانات عامة ──
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _InfoCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x0AFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x14FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: const Color(0x1A6366F1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6366F1)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0x66FFFFFF))),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
