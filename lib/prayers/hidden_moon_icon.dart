import 'package:flutter/material.dart';

class HiddenMoonIcon extends StatefulWidget {
  const HiddenMoonIcon({super.key});

  @override
  State<HiddenMoonIcon> createState() => _HiddenMoonIconState();
}

class _HiddenMoonIconState extends State<HiddenMoonIcon> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => Navigator.of(context).pushNamed('/abdulrahman'),
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
