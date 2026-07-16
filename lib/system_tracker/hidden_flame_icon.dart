import 'package:flutter/material.dart';

/// Tiny hidden flame icon — separate from the moon icon used for the
/// prayers page, sitting a bit lower on the landing page. Tapping it opens
/// Soufiane's daily system tracker (behind its own passcode gate).
class HiddenFlameIcon extends StatefulWidget {
  const HiddenFlameIcon({super.key});

  @override
  State<HiddenFlameIcon> createState() => _HiddenFlameIconState();
}

class _HiddenFlameIconState extends State<HiddenFlameIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/soufiane'),
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
