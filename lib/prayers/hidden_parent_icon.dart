import 'package:flutter/material.dart';

/// Tiny near-invisible icon in the prayer tracker's app bar — lets the
/// parent (behind a PIN) add points for a prayer Abdulrahman prayed on time
/// but couldn't log immediately himself (e.g. no phone on him at that
/// moment).
class HiddenParentIcon extends StatefulWidget {
  const HiddenParentIcon({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<HiddenParentIcon> createState() => _HiddenParentIconState();
}

class _HiddenParentIconState extends State<HiddenParentIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Icon(
            Icons.shield_outlined,
            size: 14,
            color: Colors.white.withValues(alpha: _hovering ? 0.35 : 0.12),
          ),
        ),
      ),
    );
  }
}
