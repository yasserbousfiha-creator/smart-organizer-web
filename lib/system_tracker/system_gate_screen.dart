import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'system_tracker_screen.dart';

const String _kSystemSecretCode = 'soufiane';

/// Passcode gate for direct-URL access to Soufiane's daily system tracker
/// (mirrors the dialog in hidden_flame_icon.dart, as a standalone page).
class SystemGateScreen extends StatefulWidget {
  const SystemGateScreen({super.key});

  @override
  State<SystemGateScreen> createState() => _SystemGateScreenState();
}

class _SystemGateScreenState extends State<SystemGateScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _unlocked = false;

  void _submit() {
    if (_controller.text.trim().toLowerCase() == _kSystemSecretCode) {
      setState(() => _unlocked = true);
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
    if (_unlocked) return const SystemTrackerScreen();

    return Directionality(
      textDirection: TextDirection.ltr,
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
      ),
    );
  }
}
