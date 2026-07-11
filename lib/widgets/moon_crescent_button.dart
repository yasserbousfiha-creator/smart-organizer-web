import 'package:flutter/material.dart';

/// أيقونة هلال صغيرة ومضغوطة (بلا حبل معلّق) — بلون خافت فحالة السكون،
/// وكتضوي وتصبح ذهبية عند مرور الماوس، بحال شعار Moon Abaya. الضغط
/// عليها كيفتح نافذة تسجيل الدخول ديال Moon Abaya.
class MoonCrescentButton extends StatefulWidget {
  final VoidCallback onTap;
  final double size;
  const MoonCrescentButton({super.key, required this.onTap, this.size = 18});

  @override
  State<MoonCrescentButton> createState() => _MoonCrescentButtonState();
}

class _MoonCrescentButtonState extends State<MoonCrescentButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Moon Abaya',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: CustomPaint(painter: _CrescentPainter(lit: _hovered)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrescentPainter extends CustomPainter {
  static const _gold = Color(0xFFE3C486);
  final bool lit;
  const _CrescentPainter({required this.lit});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final center = Offset(w / 2, h / 2);

    if (lit) {
      canvas.drawCircle(
        center,
        w * 0.95,
        Paint()
          ..shader = RadialGradient(
            colors: [_gold.withValues(alpha: 0.5), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: w * 0.95)),
      );
    }

    // هلال: دائرة كاملة نطرحو منها دائرة أصغر مزاحة — نفس تقنية رسم شعار القمر
    final outer = Path()..addOval(Rect.fromCircle(center: center, radius: w / 2));
    final inner = Path()
      ..addOval(Rect.fromCircle(center: Offset(w * 0.62, h * 0.4), radius: w * 0.42));
    final crescent = Path.combine(PathOperation.difference, outer, inner);

    canvas.drawPath(
      crescent,
      Paint()..color = lit ? _gold : Colors.white.withValues(alpha: 0.55),
    );
  }

  @override
  bool shouldRepaint(covariant _CrescentPainter oldDelegate) => oldDelegate.lit != lit;
}
