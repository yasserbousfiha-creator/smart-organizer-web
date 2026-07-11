import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// زر "بوابة الموظفين" — بنفس ستايل زر إذاعة القرآن الكريم بالضبط (بيضة
/// مضغوطة بالجوال، بطاقة بأيقونة+نص بسطح المكتب)، بأيقونة مصباح صغيرة
/// بدل النص العادي. الضغط عليه كيفتح نافذة تسجيل الدخول.
class LampPullButton extends StatefulWidget {
  final VoidCallback onPulled;
  final bool compact;
  const LampPullButton({super.key, required this.onPulled, this.compact = false});

  @override
  State<LampPullButton> createState() => _LampPullButtonState();
}

class _LampPullButtonState extends State<LampPullButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final icon = SizedBox(
      width: widget.compact ? 19 : 18,
      height: widget.compact ? 19 : 18,
      child: CustomPaint(painter: _LampGlyphPainter(lit: _hovered)),
    );

    Widget content;
    if (widget.compact) {
      content = Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.22)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryLight.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        alignment: Alignment.center,
        child: icon,
      );
    } else {
      content = Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: _hovered
                ? AppColors.primaryLight.withValues(alpha: 0.55)
                : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              'بوابة الموظفين',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _hovered ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: 'بوابة الموظفين',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPulled,
          child: content,
        ),
      ),
    );
  }
}

/// أيقونة مصباح صغيرة (قبة + عمود قصير + كرة السحب) مرسومة بالكامل داخل
/// حدودها الخاصة — بلا أي عنصر معلّق برا الصندوق، فما كاينش خطر overflow.
class _LampGlyphPainter extends CustomPainter {
  final bool lit;
  const _LampGlyphPainter({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final domeColor = lit ? const Color(0xFFFFF7E0) : Colors.white.withValues(alpha: 0.85);

    // القبة
    final shadePath = Path()
      ..moveTo(w * 0.5, h * 0.02)
      ..lineTo(w * 0.14, h * 0.42)
      ..quadraticBezierTo(w * 0.5, h * 0.6, w * 0.86, h * 0.42)
      ..close();
    canvas.drawPath(shadePath, Paint()..color = domeColor);

    if (lit) {
      canvas.drawCircle(
        Offset(w / 2, h * 0.3),
        w * 0.55,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.primaryLight.withValues(alpha: 0.45), Colors.transparent],
          ).createShader(Rect.fromCircle(center: Offset(w / 2, h * 0.3), radius: w * 0.55)),
      );
    }

    // العمود + كرة السحب
    final cordPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = w * 0.06;
    canvas.drawLine(Offset(w / 2, h * 0.42), Offset(w / 2, h * 0.82), cordPaint);

    canvas.drawCircle(
      Offset(w / 2, h * 0.88),
      w * 0.14,
      Paint()..color = const Color(0xFFF59E0B),
    );
  }

  @override
  bool shouldRepaint(covariant _LampGlyphPainter oldDelegate) => oldDelegate.lit != lit;
}
