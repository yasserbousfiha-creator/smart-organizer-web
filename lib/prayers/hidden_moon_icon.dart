import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import 'prayer_tracker_screen.dart';

const String _kPrayerSecretCode = '2033';

/// أيقونة قمر صغيرة جدا ومخفية (شبه شفافة) — علامة خاصة بلاصتها فوسط
/// الموقع. ماعندهاش علاقة بهلال Moon Abaya اللي جنب الشعار. ملي
/// تتضغط، كتطلب رمز سري قبل ما تفتح صفحة متابعة صلاة عبدالرحمن.
class HiddenMoonIcon extends StatefulWidget {
  const HiddenMoonIcon({super.key});

  @override
  State<HiddenMoonIcon> createState() => _HiddenMoonIconState();
}

class _HiddenMoonIconState extends State<HiddenMoonIcon> {
  bool _hovering = false;

  void _openLockDialog() {
    showDialog(
      context: context,
      builder: (_) => _PrayerLockDialog(
        onSuccess: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PrayerTrackerScreen()),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: _openLockDialog,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(
            Icons.nightlight_round,
            size: 11,
            color: Colors.white.withValues(alpha: _hovering ? 0.35 : 0.12),
          ),
        ),
      ),
    );
  }
}

class _PrayerLockDialog extends StatefulWidget {
  const _PrayerLockDialog({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_PrayerLockDialog> createState() => _PrayerLockDialogState();
}

class _PrayerLockDialogState extends State<_PrayerLockDialog> {
  final _controller = TextEditingController();
  String? _error;

  void _submit() {
    if (_controller.text.trim() == _kPrayerSecretCode) {
      widget.onSuccess();
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
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
    );
  }
}
