// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'portal_client.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'leaves_screen.dart';
import 'advances_screen.dart';
import 'payslip_screen.dart';
import 'requests_screen.dart';
import 'messages_screen.dart';
import 'clinic_schedule_screen.dart';
import 'admin_screen.dart';
import 'admin_messages_screen.dart';
import 'portal_i18n.dart';

String trGreeting(bool isEnglish, String name) =>
    isEnglish ? 'Welcome, $name 👋' : 'مرحباً، $name 👋';

class _LanguageToggleButton extends StatelessWidget {
  final bool isEnglish;
  final VoidCallback onTap;
  const _LanguageToggleButton({required this.isEnglish, required this.onTap});

  static const _indigo = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _indigo.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _indigo.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language_rounded, size: 14, color: _indigo),
              const SizedBox(width: 4),
              Text(
                isEnglish ? 'AR' : 'EN',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _indigo,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PortalHomeScreen extends StatefulWidget {
  const PortalHomeScreen({super.key});
  @override
  State<PortalHomeScreen> createState() => _PortalHomeScreenState();
}

class _PortalHomeScreenState extends State<PortalHomeScreen> {
  int _tab = 0;
  Map<String, dynamic>? _profile;
  bool _loading = true;
  int _unreadMsgCount = 0;
  bool _hasLeaveUpdate = false;
  RealtimeChannel? _badgeChannel;
  bool _isEnglish = false;

  static const _bgColor = Color(0xFF061A22);
  static const _indigo = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    _loadLanguage();
    _checkSessionTimeout();
    _loadProfile();
  }

  void _loadLanguage() {
    try {
      _isEnglish = html.window.localStorage['portal_lang'] == 'en';
    } catch (_) {}
  }

  void _toggleLanguage() {
    setState(() => _isEnglish = !_isEnglish);
    try {
      html.window.localStorage['portal_lang'] = _isEnglish ? 'en' : 'ar';
    } catch (_) {}
  }

  @override
  void dispose() {
    if (_badgeChannel != null) portalClient.removeChannel(_badgeChannel!);
    super.dispose();
  }

  Future<void> _initBadges(String empId) async {
    try {
      final rows = await portalClient
          .from('portal_messages')
          .select('id')
          .eq('employee_id', empId)
          .inFilter('sender', ['admin', 'hr'])
          .eq('is_read', false);
      if (mounted) setState(() => _unreadMsgCount = (rows as List).length);
    } catch (_) {}

    _badgeChannel = portalClient
        .channel('home-badges-$empId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'portal_messages',
          callback: (_) async {
            try {
              final rows = await portalClient
                  .from('portal_messages')
                  .select('id')
                  .eq('employee_id', empId)
                  .inFilter('sender', ['admin', 'hr'])
                  .eq('is_read', false);
              if (mounted) setState(() => _unreadMsgCount = (rows as List).length);
            } catch (_) {}
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'leave_requests',
          callback: (_) { if (mounted) setState(() => _hasLeaveUpdate = true); },
        )
        .subscribe();
  }

  void _switchTab(int i, List<_TabItem> tabs) {
    final msgIdx   = tabs.indexWhere((t) => t.label == 'المراسلات');
    final leaveIdx = tabs.indexWhere((t) => t.label == 'الإجازات');
    setState(() {
      _tab = i;
      if (i == msgIdx)   _unreadMsgCount = 0;
      if (i == leaveIdx) _hasLeaveUpdate  = false;
    });
  }

  void _checkSessionTimeout() {
    try {
      final closedStr = html.window.localStorage['portal_closed_at'];
      if (closedStr != null) {
        final closedAt = DateTime.tryParse(closedStr);
        html.window.localStorage.remove('portal_closed_at');
        if (closedAt != null &&
            DateTime.now().difference(closedAt).inMinutes >= 5) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _logout());
          return;
        }
      }
      html.window.addEventListener('beforeunload', (_) {
        html.window.localStorage['portal_closed_at'] =
            DateTime.now().toIso8601String();
      });
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final userId = portalClient.auth.currentUser?.id;
      if (userId == null) return;
      final data = await portalClient
          .from('employee_profiles')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (mounted) setState(() { _profile = data; _loading = false; });
      if (data != null && data['is_admin'] != true) {
        final empId = data['id'] as String?;
        if (empId != null) _initBadges(empId);
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _logout() async {
    try {
      await portalClient.auth.signOut()
          .timeout(const Duration(seconds: 3));
    } catch (_) {
    }
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => Directionality(
            textDirection: TextDirection.rtl,
            child: const PortalLoginScreen(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _indigo)),
      );
    }

    final empId = _profile?['id'] as String?;
    final name = _profile?['name'] as String? ?? tr(_isEnglish, 'موظف');
    final dept = _profile?['department'] as String? ?? '';

    final isMedical = (_profile?['clinic_number'] != null) ||
        dept.contains('طبيب') ||
        dept.contains('ممرض') ||
        dept == 'التمريض';

    final isAdmin = _profile?['is_admin'] == true;

    final tabs = isAdmin
        ? [
            _TabItem(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              screen: _AdminHomeTab(name: name, isEnglish: _isEnglish),
            ),
            _TabItem(
              icon: Icons.chat_outlined,
              label: 'المراسلات',
              screen: AdminMessagesScreen(isEnglish: _isEnglish),
            ),
            _TabItem(
              icon: Icons.admin_panel_settings_outlined,
              label: 'الإدارة',
              screen: AdminScreen(isEnglish: _isEnglish),
            ),
          ]
        : [
            _TabItem(icon: Icons.home_rounded, label: 'الرئيسية',
                screen: _DashboardTab(profile: _profile, isMedical: isMedical,
                    isEnglish: _isEnglish,
                    onTabSwitch: (i) => setState(() => _tab = i))),
            _TabItem(icon: Icons.person_outline, label: 'ملفي',
                screen: PortalProfileScreen(profile: _profile, isEnglish: _isEnglish)),
            _TabItem(icon: Icons.beach_access_outlined, label: 'الإجازات',
                screen: PortalLeavesScreen(employeeId: empId ?? '', employeeName: name, isEnglish: _isEnglish)),
            _TabItem(icon: Icons.account_balance_wallet_outlined, label: 'السلف',
                screen: PortalAdvancesScreen(employeeId: empId ?? '', employeeName: name, isEnglish: _isEnglish)),
            _TabItem(icon: Icons.receipt_long_outlined, label: 'الراتب',
                screen: PortalPayslipScreen(employeeId: empId ?? '', isEnglish: _isEnglish)),
            _TabItem(icon: Icons.description_outlined, label: 'الطلبات',
                screen: PortalRequestsScreen(employeeId: empId ?? '', employeeName: name, isEnglish: _isEnglish)),
            _TabItem(icon: Icons.chat_outlined, label: 'المراسلات',
                screen: PortalMessagesScreen(employeeId: empId ?? '', isEnglish: _isEnglish)),
            if (isMedical)
              _TabItem(
                icon: Icons.mood_outlined,
                label: 'العيادات',
                screen: ClinicScheduleScreen(
                  employeeId: empId ?? '',
                  defaultClinic: _profile?['clinic_number']?.toString(),
                  defaultShift: _profile?['shift'] as String?,
                  isEnglish: _isEnglish,
                ),
              ),
          ];

    final isMobile = MediaQuery.of(context).size.width < 650;

    return Directionality(
      textDirection: _isEnglish ? TextDirection.ltr : TextDirection.rtl,
      child: Scaffold(
      backgroundColor: _bgColor,
      // ── Bottom Nav (mobile) ──
      bottomNavigationBar: isMobile
          ? Container(
              decoration: const BoxDecoration(
                color: Color(0xFF061A22),
                border: Border(top: BorderSide(color: Color(0x14FFFFFF))),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: List.generate(tabs.length, (i) {
                      final active = _tab == i;
                      final showMsgBadge   = tabs[i].label == 'المراسلات' && _unreadMsgCount > 0;
                      final showLeaveBadge = tabs[i].label == 'الإجازات'  && _hasLeaveUpdate;
                      final showBadge = showMsgBadge || showLeaveBadge;
                      return GestureDetector(
                        onTap: () => _switchTab(i, tabs),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: active ? _indigo.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavBadge(
                                icon: tabs[i].icon,
                                iconSize: 22,
                                iconColor: active ? _indigo : const Color(0x66FFFFFF),
                                show: showBadge,
                                count: showMsgBadge ? _unreadMsgCount : 0,
                              ),
                              const SizedBox(height: 3),
                              Text(tr(_isEnglish, tabs[i].label),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: active ? FontWeight.w700 : FontWeight.normal,
                                      color: active ? _indigo : const Color(0x66FFFFFF))),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            )
          : null,
      // ── AppBar (mobile) ──
      appBar: isMobile
          ? AppBar(
              backgroundColor: const Color(0xFF061A22),
              elevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 12,
              title: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [_indigo, Color(0xFF0EA5E9)]),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0] : '?',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(name,
                        style: const TextStyle(color: Colors.white,
                            fontSize: 14, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1),
                  ),
                  const Spacer(),
                  _LanguageToggleButton(
                    isEnglish: _isEnglish,
                    onTap: _toggleLanguage,
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout,
                        color: Colors.redAccent, size: 15),
                    label: Text(tr(_isEnglish, 'خروج'),
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(
                              color: Colors.red.withValues(alpha: 0.25))),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            )
          : null,
      body: isMobile
          // ── Mobile: content only ──
          ? tabs[_tab].screen
          // ── Desktop: sidebar + content ──
          : Row(
              children: [
                Container(
                  width: 220,
                  decoration: const BoxDecoration(
                    color: Color(0x0AFFFFFF),
                    border: Border(right: BorderSide(color: Color(0x14FFFFFF))),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: _LanguageToggleButton(
                                isEnglish: _isEnglish,
                                onTap: _toggleLanguage,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_indigo, Color(0xFF0EA5E9)]),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  name.isNotEmpty ? name[0] : '?',
                                  style: const TextStyle(color: Colors.white,
                                      fontSize: 22, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(name,
                                style: const TextStyle(color: Colors.white,
                                    fontWeight: FontWeight.w600, fontSize: 14),
                                textAlign: TextAlign.center),
                            if (dept.isNotEmpty)
                              Text(dept,
                                  style: const TextStyle(
                                      color: Color(0x99FFFFFF), fontSize: 11),
                                  textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                      const Divider(color: Color(0x14FFFFFF), height: 1),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: tabs.length,
                          itemBuilder: (_, i) {
                            final active = _tab == i;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                              onTap: () => _switchTab(i, tabs),
                              borderRadius: BorderRadius.circular(8),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 4),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: active
                                      ? _indigo.withValues(alpha: 0.15)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: active
                                          ? _indigo.withValues(alpha: 0.4)
                                          : Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    _NavBadge(
                                      icon: tabs[i].icon,
                                      iconSize: 18,
                                      iconColor: active ? _indigo : const Color(0x99FFFFFF),
                                      show: (tabs[i].label == 'المراسلات' && _unreadMsgCount > 0) ||
                                            (tabs[i].label == 'الإجازات'  && _hasLeaveUpdate),
                                      count: tabs[i].label == 'المراسلات' ? _unreadMsgCount : 0,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(tr(_isEnglish, tabs[i].label),
                                        style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: active
                                                ? FontWeight.w600
                                                : FontWeight.normal,
                                            color: active
                                                ? Colors.white
                                                : const Color(0x99FFFFFF))),
                                  ],
                                ),
                              ),
                            ));
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton.icon(
                            onPressed: _logout,
                            icon: const Icon(Icons.logout,
                                size: 16, color: Colors.redAccent),
                            label: Text(tr(_isEnglish, 'تسجيل الخروج'),
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.redAccent)),
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  Colors.red.withValues(alpha: 0.08),
                              alignment: Alignment.centerRight,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                      color:
                                          Colors.red.withValues(alpha: 0.2))),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: tabs[_tab].screen),
              ],
            ),
      ),
    );
  }
}

class _AdminHomeTab extends StatelessWidget {
  final String name;
  final bool isEnglish;
  const _AdminHomeTab({required this.name, required this.isEnglish});

  static const _indigo = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(isEnglish ? 'Welcome, $name' : 'مرحباً، $name',
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(tr(isEnglish, 'لوحة تحكم مدير النظام'),
              style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF))),
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AdminCard(
                icon: Icons.chat_outlined,
                label: tr(isEnglish, 'المراسلات'),
                desc: tr(isEnglish, 'محادثات الموظفين'),
                color: _indigo,
                onTap: () {},
              ),
              _AdminCard(
                icon: Icons.beach_access_outlined,
                label: tr(isEnglish, 'الإجازات'),
                desc: tr(isEnglish, 'مراجعة الطلبات'),
                color: const Color(0xFF34D399),
                onTap: () {},
              ),
              _AdminCard(
                icon: Icons.people_outline,
                label: tr(isEnglish, 'الموظفون'),
                desc: tr(isEnglish, 'عرض البيانات'),
                color: const Color(0xFF0EA5E9),
                onTap: () {},
              ),
              _AdminCard(
                icon: Icons.access_time_outlined,
                label: tr(isEnglish, 'الدوامات'),
                desc: tr(isEnglish, 'تعديل الجداول'),
                color: const Color(0xFFF59E0B),
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String desc;
  final Color color;
  final VoidCallback onTap;
  const _AdminCard({required this.icon, required this.label,
      required this.desc, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(
                color: Color(0x66FFFFFF), fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  final Widget screen;
  const _TabItem({required this.icon, required this.label, required this.screen});
}

class _NavBadge extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final Color iconColor;
  final bool show;
  final int count;
  const _NavBadge({
    required this.icon,
    required this.iconSize,
    required this.iconColor,
    required this.show,
    this.count = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (!show) return Icon(icon, size: iconSize, color: iconColor);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, size: iconSize, color: iconColor),
        Positioned(
          top: -4,
          left: -4,
          child: Container(
            constraints: BoxConstraints(
              minWidth: count > 0 ? 16 : 8,
              minHeight: count > 0 ? 16 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              shape: count > 0 ? BoxShape.rectangle : BoxShape.circle,
              borderRadius: count > 0 ? BorderRadius.circular(8) : null,
            ),
            child: count > 0
                ? Center(
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final bool isMedical;
  final bool isEnglish;
  final void Function(int) onTabSwitch;
  const _DashboardTab({this.profile, required this.isMedical,
      required this.isEnglish, required this.onTabSwitch});

  static const _indigo = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    final name = profile?['name'] as String? ?? tr(isEnglish, 'الموظف');
    final dept = profile?['department'] as String? ?? '';
    final shift = profile?['shift'] as String? ?? '';
    final status = profile?['status'] as String? ?? '';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trGreeting(isEnglish, name),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 4),
          Text(tr(isEnglish, 'إليك نظرة سريعة على بياناتك'),
              style: const TextStyle(fontSize: 13, color: Color(0x99FFFFFF))),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _QuickCard(icon: Icons.business_center_outlined,
                  label: tr(isEnglish, 'القسم'), value: dept, color: _indigo),
              _QuickCard(icon: Icons.access_time_outlined,
                  label: tr(isEnglish, 'الدوام'), value: shift, color: const Color(0xFF0EA5E9)),
              _QuickCard(icon: Icons.check_circle_outline,
                  label: tr(isEnglish, 'الحالة'), value: status, color: const Color(0xFF34D399)),
            ],
          ),
          const SizedBox(height: 28),
          Text(tr(isEnglish, 'الوصول السريع'),
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _ActionBtn(icon: Icons.beach_access_outlined,
                  label: tr(isEnglish, 'طلب إجازة'), color: _indigo,
                  onTap: () => onTabSwitch(2)),
              _ActionBtn(icon: Icons.account_balance_wallet_outlined,
                  label: tr(isEnglish, 'طلب سلفة'), color: const Color(0xFF34D399),
                  onTap: () => onTabSwitch(3)),
              _ActionBtn(icon: Icons.receipt_long_outlined,
                  label: tr(isEnglish, 'كشف الراتب'), color: const Color(0xFFF59E0B),
                  onTap: () => onTabSwitch(4)),
              _ActionBtn(icon: Icons.description_outlined,
                  label: tr(isEnglish, 'طلباتي'), color: const Color(0xFF0EA5E9),
                  onTap: () => onTabSwitch(5)),
              _ActionBtn(icon: Icons.chat_outlined,
                  label: tr(isEnglish, 'مراسلة الإدارة'), color: const Color(0xFF0EA5E9),
                  onTap: () => onTabSwitch(6)),
              if (isMedical)
                _ActionBtn(icon: Icons.mood_outlined,
                    label: tr(isEnglish, 'جدول العيادات'), color: const Color(0xFF06B6D4),
                    onTap: () => onTabSwitch(7)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _QuickCard({required this.icon, required this.label,
      required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
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
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Color(0x99FFFFFF))),
                const SizedBox(height: 2),
                Text(value.isNotEmpty ? value : '—',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: Colors.white),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({required this.icon, required this.label,
      required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140, height: 72,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 5),
            Text(label, style: TextStyle(color: color, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
