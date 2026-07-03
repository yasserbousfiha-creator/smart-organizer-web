import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal_client.dart';

class PortalProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? profile;
  const PortalProfileScreen({super.key, this.profile});

  static const _indigo = Color(0xFF06B6D4);

  void _showChangePasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0D2731),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ChangePasswordSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = profile ?? {};
    final isMobile = MediaQuery.of(context).size.width < 700;
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
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAvatar(p),
                    const SizedBox(height: 12),
                    Text(p['name'] as String? ?? '—',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('رقم الموظف: ${p['employee_number'] ?? '—'}',
                        style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                        overflow: TextOverflow.ellipsis),
                  ],
                )
              : Row(
                  children: [
                    _buildAvatar(p),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] as String? ?? '—',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text('رقم الموظف: ${p['employee_number'] ?? '—'}',
                              style: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _showChangePasswordSheet(context),
              icon: const Icon(Icons.lock_outline, size: 16, color: _indigo),
              label: const Text('تغيير كلمة المرور',
                  style: TextStyle(fontSize: 13, color: _indigo)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _indigo.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 14),
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
                    gradient: const LinearGradient(colors: [_indigo, Color(0xFF0EA5E9)]),
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
        gradient: const LinearGradient(colors: [_indigo, Color(0xFF0EA5E9)]),
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
          colors: [Color(0xFF0E7490), Color(0xFF123540)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3306B6D4)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: const Color(0x3306B6D4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: Color(0xFF22D3EE), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('الراتب الأساسي الشهري',
                    style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(
                  '${salary.toStringAsFixed(salary.truncateToDouble() == salary ? 0 : 2)} ريال',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
        : const Color(0xFF22D3EE);
    final isMobile = MediaQuery.of(context).size.width < 700;
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (department.isNotEmpty)
                      Text(department,
                          style: const TextStyle(
                              color: Color(0x99FFFFFF), fontSize: 11),
                          overflow: TextOverflow.ellipsis),
                    const Text('بيانات العيادة',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          isMobile
              ? Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ClinicChip(
                      icon: Icons.door_front_door_outlined,
                      label: 'عيادة رقم $clinicNumber',
                      color: const Color(0xFF34D399),
                    ),
                    _ClinicChip(
                      icon: Icons.schedule_outlined,
                      label: 'دوام $shift',
                      color: shiftColor,
                    ),
                  ],
                )
              : Row(
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
          Flexible(
            child: Text(label,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
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
              color: const Color(0x1A06B6D4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF06B6D4)),
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

// ── نافذة تغيير كلمة المرور ──
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();
  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _submitting = false;
  String? _error;

  static const _indigo = Color(0xFF06B6D4);
  static const _green = Color(0xFF34D399);
  static const _red = Color(0xFFF87171);

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = _currentCtrl.text;
    final next = _newCtrl.text;
    final confirm = _confirmCtrl.text;

    if (current.isEmpty) { setState(() => _error = 'أدخل كلمة المرور الحالية'); return; }
    if (next.length < 6) { setState(() => _error = 'كلمة المرور الجديدة يجب أن تكون 6 أحرف على الأقل'); return; }
    if (next != confirm) { setState(() => _error = 'كلمتا المرور الجديدتان غير متطابقتين'); return; }
    if (next == current) { setState(() => _error = 'كلمة المرور الجديدة مطابقة للحالية'); return; }

    final email = portalClient.auth.currentUser?.email;
    if (email == null) { setState(() => _error = 'تعذّر التحقق من الجلسة، سجّل الدخول مجدداً'); return; }

    setState(() { _submitting = true; _error = null; });
    try {
      // التحقق من كلمة المرور الحالية قبل تغييرها
      await portalClient.auth.signInWithPassword(email: email, password: current);
      await portalClient.auth.updateUser(UserAttributes(password: next));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تم تغيير كلمة المرور بنجاح ✓'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on AuthException catch (e) {
      final msg = e.message.contains('Invalid login')
          ? 'كلمة المرور الحالية غير صحيحة'
          : e.message;
      if (mounted) setState(() => _error = msg);
    } catch (e) {
      if (mounted) setState(() => _error = 'خطأ: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  InputDecoration _decoration(String label, {required bool obscure, required VoidCallback onToggle}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0x99FFFFFF), fontSize: 13),
      prefixIcon: const Icon(Icons.lock_outline, color: Color(0x66FFFFFF), size: 18),
      suffixIcon: IconButton(
        icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.white38, size: 18),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: const Color(0x0AFFFFFF),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0x1AFFFFFF))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _indigo, width: 1.5)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('تغيير كلمة المرور',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),

          TextField(
            controller: _currentCtrl,
            obscureText: _obscureCurrent,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _decoration('كلمة المرور الحالية',
                obscure: _obscureCurrent,
                onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _newCtrl,
            obscureText: _obscureNew,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _decoration('كلمة المرور الجديدة',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmCtrl,
            obscureText: _obscureNew,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: _decoration('تأكيد كلمة المرور الجديدة',
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew)),
            onSubmitted: (_) => _submit(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withValues(alpha: 0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: _red, fontSize: 13)),
            ),
          ],

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: _indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('حفظ كلمة المرور الجديدة',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
