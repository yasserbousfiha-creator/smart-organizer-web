import 'package:flutter/material.dart';
import '../portal/portal_client.dart';
import '../theme/app_colors.dart';

class WaitlistSection extends StatefulWidget {
  final bool isEnglish;
  const WaitlistSection({super.key, this.isEnglish = false});

  @override
  State<WaitlistSection> createState() => _WaitlistSectionState();
}

class _WaitlistSectionState extends State<WaitlistSection> {
  final _ctrl = TextEditingController();
  bool _submitting = false;
  bool _done = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _ctrl.text.trim();
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = widget.isEnglish
          ? 'Enter a valid email address'
          : 'أدخل بريداً إلكترونياً صحيحاً');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await portalClient.from('waitlist_signups').insert({'email': email});
      if (!mounted) return;
      setState(() { _submitting = false; _done = true; });
    } catch (e) {
      if (!mounted) return;
      final isDuplicate = e.toString().contains('duplicate') || e.toString().contains('unique');
      setState(() {
        _submitting = false;
        _error = widget.isEnglish
            ? (isDuplicate ? 'This email is already registered' : 'Failed to send, please try again')
            : (isDuplicate ? 'هذا البريد مسجّل مسبقاً' : 'تعذّر الإرسال، حاول مرة أخرى');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 60 : 80, horizontal: isMobile ? 20 : 40),
      child: Center(
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 560),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 34 : 44, horizontal: isMobile ? 22 : 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [AppColors.primary.withValues(alpha: 0.12), AppColors.secondary.withValues(alpha: 0.12)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
          ),
          child: _done ? _buildSuccess() : _buildForm(isMobile),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withValues(alpha: 0.15),
          ),
          child: const Icon(Icons.check_rounded, color: AppColors.success, size: 30),
        ),
        const SizedBox(height: 18),
        Text(
          widget.isEnglish ? 'Successfully registered!' : 'تم التسجيل بنجاح!',
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          widget.isEnglish
              ? "We'll email you as soon as registration opens to everyone."
              : 'سنراسلك فور فتح التسجيل للجميع.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.55)),
        ),
      ],
    );
  }

  Widget _buildForm(bool isMobile) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.notifications_active_rounded, color: AppColors.primaryLight, size: 30),
        const SizedBox(height: 16),
        Text(
          widget.isEnglish ? 'Notify me when registration opens' : 'أشعرني عند فتح التسجيل',
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'Tajawal', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
        ),
        const SizedBox(height: 10),
        Text(
          widget.isEnglish
              ? "Access is currently invite-only. Leave your email and we'll notify you when registration opens to everyone."
              : 'الوصول حالياً خاص بالمدعوين فقط. اترك بريدك الإلكتروني وسنعلمك عند فتح التسجيل للجميع.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha: 0.55), height: 1.7),
        ),
        const SizedBox(height: 26),
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isMobile ? CrossAxisAlignment.stretch : CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: const TextStyle(color: Colors.white, fontSize: 14),
                decoration: InputDecoration(
                  hintText: widget.isEnglish ? 'Your email' : 'بريدك الإلكتروني',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            SizedBox(width: isMobile ? 0 : 10, height: isMobile ? 10 : 0),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  width: isMobile ? double.infinity : 130,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(widget.isEnglish ? 'Notify Me' : 'أشعرني', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12.5)),
        ],
      ],
    );
  }
}
