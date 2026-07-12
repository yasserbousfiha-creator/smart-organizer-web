import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'system_tracker_screen.dart';

const String _kSystemSecretCode = 'soufiane';

/// Tiny hidden flame icon — separate from the moon icon used for the
/// prayers page, sitting a bit lower on the landing page. Tapping it asks
/// for a text password before opening Soufiane's daily system tracker.
class HiddenFlameIcon extends StatefulWidget {
  const HiddenFlameIcon({super.key});

  @override
  State<HiddenFlameIcon> createState() => _HiddenFlameIconState();
}

class _HiddenFlameIconState extends State<HiddenFlameIcon> {
  bool _hovering = false;

  void _openLockDialog() {
    showDialog(
      context: context,
      builder: (_) => _SystemLockDialog(
        onSuccess: () {
          Navigator.of(context).pop();
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SystemTrackerScreen()),
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
            Icons.local_fire_department_rounded,
            size: 11,
            color: Colors.white.withValues(alpha: _hovering ? 0.35 : 0.12),
          ),
        ),
      ),
    );
  }
}

class _SystemLockDialog extends StatefulWidget {
  const _SystemLockDialog({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  State<_SystemLockDialog> createState() => _SystemLockDialogState();
}

class _SystemLockDialogState extends State<_SystemLockDialog> {
  final _controller = TextEditingController();
  String? _error;

  void _submit() {
    if (_controller.text.trim().toLowerCase() == _kSystemSecretCode) {
      widget.onSuccess();
    } else {
      setState(() => _error = 'Wrong code');
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
      textDirection: TextDirection.ltr,
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
                  'Private page',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _controller,
                  autofocus: true,
                  obscureText: true,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: 'Passcode',
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
                    child: const Text('Enter'),
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
