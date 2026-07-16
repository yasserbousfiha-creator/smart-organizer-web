import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'prayer_tracker_screen.dart';

const String _kPrayerSecretCode = '2033';

/// Passcode gate for direct-URL access to Abdulrahman's prayer tracker
/// (mirrors the dialog in hidden_moon_icon.dart, as a standalone page).
class PrayerGateScreen extends StatefulWidget {
  const PrayerGateScreen({super.key});

  @override
  State<PrayerGateScreen> createState() => _PrayerGateScreenState();
}

class _PrayerGateScreenState extends State<PrayerGateScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _unlocked = false;

  void _submit() {
    if (_controller.text.trim() == _kPrayerSecretCode) {
      setState(() => _unlocked = true);
    } else {
      setState(() => _error = 'الرمز غير صحيح');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_unlocked) return const PrayerTrackerScreen();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_rounded, color: Colors.white70, size: 28),
                  const SizedBox(height: 14),
                  const Text(
                    'صفحة خاصة',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, letterSpacing: 4),
                    decoration: InputDecoration(
                      hintText: 'الرمز السري',
                      hintStyle: const TextStyle(color: Colors.white38),
                      errorText: _error,
                      filled: true,
                      fillColor: AppColors.surfaceHi,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('دخول'),
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
