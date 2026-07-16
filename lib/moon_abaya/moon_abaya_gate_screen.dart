import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../portal/portal_client.dart';
import '../theme/app_colors.dart';
import 'moon_abaya_screen.dart';

/// Session/admin gate for direct-URL access to the Moon Abaya screen
/// (mirrors _openMoonAbaya + its login dialog in main.dart, as a standalone page).
class MoonAbayaGateScreen extends StatefulWidget {
  const MoonAbayaGateScreen({super.key});

  @override
  State<MoonAbayaGateScreen> createState() => _MoonAbayaGateScreenState();
}

class _MoonAbayaGateScreenState extends State<MoonAbayaGateScreen> {
  bool _checking = true;
  bool _isAdmin = false;
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<bool> _isMoonAbayaAdmin() async {
    final userId = portalClient.auth.currentUser?.id;
    if (userId == null) return false;
    try {
      final data = await portalClient
          .from('moon_abaya_admins')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();
      return data != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> _check() async {
    await portalReady;
    try {
      if (portalClient.auth.currentSession != null) {
        if (await _isMoonAbayaAdmin()) {
          _isAdmin = true;
        } else {
          await portalClient.auth.signOut();
        }
      }
    } catch (_) {
      _isAdmin = false;
    }
    if (!mounted) return;
    setState(() => _checking = false);
  }

  Future<void> _submit() async {
    if (_userCtrl.text.trim().isEmpty) {
      setState(() => _error = 'أدخل اسم المستخدم');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = '${_userCtrl.text.trim().toLowerCase()}@moonabaya.local';
      await portalClient.auth.signInWithPassword(email: email, password: _passCtrl.text);
      if (!await _isMoonAbayaAdmin()) {
        await portalClient.auth.signOut();
        setState(() {
          _loading = false;
          _error = 'هذا الحساب لا يملك صلاحية الوصول';
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _isAdmin = true;
      });
    } on AuthException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message.contains('Invalid login')
            ? 'اسم المستخدم أو كلمة المرور غير صحيحة'
            : e.message;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'خطأ: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_isAdmin) return const MoonAbayaScreen();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/moon_abaya_logo.png', height: 34),
                  const SizedBox(height: 16),
                  const Text(
                    'وصول مقيّد',
                    style: TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _userCtrl,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'اسم المستخدم',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passCtrl,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      hintText: 'كلمة المرور',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('دخول'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
