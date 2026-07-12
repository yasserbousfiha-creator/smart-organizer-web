import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

/// Celebration overlay shown whenever Soufiane completes any task: his
/// smiling photo, clapping emojis flying up, an English encouragement
/// message, and a clap sound (no kiss sound here, unlike the prayers page).
class SystemCelebrationOverlay extends StatefulWidget {
  const SystemCelebrationOverlay({super.key, required this.onClose});

  final VoidCallback onClose;

  static const _messages = [
    ("You're crushing it, Soufiane! 💪", 'Keep pushing, champion!'),
    ('Great job, Soufiane! 👏', 'One step closer to your best self'),
    ('Beast mode, Soufiane! 🔥', 'Discipline is showing'),
    ('Well done, Soufiane! 👏', 'Consistency is key'),
    ('Legend move, Soufiane! ⚡', 'Keep that streak alive'),
  ];

  static (String, String) randomMessage() {
    return _messages[Random().nextInt(_messages.length)];
  }

  @override
  State<SystemCelebrationOverlay> createState() => _SystemCelebrationOverlayState();
}

class _FloatingEmoji {
  _FloatingEmoji({required this.emoji, required this.left, required this.delay, required this.controller});

  final String emoji;
  final double left;
  final Duration delay;
  final AnimationController controller;
}

class _SystemCelebrationOverlayState extends State<SystemCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _photoController;
  late final List<_FloatingEmoji> _emojis;
  late final (String, String) _message;
  final _player = AudioPlayer();

  static const _emojiChoices = ['👏', '🔥', '💪', '⚡', '✨'];

  @override
  void initState() {
    super.initState();
    _message = SystemCelebrationOverlay.randomMessage();
    _photoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();

    final rnd = Random();
    _emojis = List.generate(20, (i) {
      final duration = Duration(milliseconds: 2200 + rnd.nextInt(1800));
      return _FloatingEmoji(
        emoji: _emojiChoices[rnd.nextInt(_emojiChoices.length)],
        left: rnd.nextDouble(),
        delay: Duration(milliseconds: rnd.nextInt(1400)),
        controller: AnimationController(vsync: this, duration: duration),
      );
    });
    for (final e in _emojis) {
      Future.delayed(e.delay, () {
        if (mounted) e.controller.repeat();
      });
    }

    _playClapSound();
  }

  Future<void> _playClapSound() async {
    try {
      await _player.play(AssetSource('system/clap.mp3'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  @override
  void dispose() {
    _photoController.dispose();
    for (final e in _emojis) {
      e.controller.dispose();
    }
    _player.dispose();
    super.dispose();
  }

  Widget _buildFloatingEmoji(BuildContext context, _FloatingEmoji e) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: e.controller,
      builder: (context, child) {
        final t = e.controller.value;
        final top = size.height * (1 - t) - 40;
        final wobble = sin(t * 6 * pi) * 14;
        return Positioned(
          left: e.left * size.width + wobble,
          top: top,
          child: Opacity(
            opacity: (1 - t).clamp(0.0, 1.0),
            child: Text(e.emoji, style: const TextStyle(fontSize: 26)),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.88),
      child: Stack(
        children: [
          ..._emojis.map((e) => _buildFloatingEmoji(context, e)),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ScaleTransition(
                    scale: CurvedAnimation(parent: _photoController, curve: Curves.elasticOut),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight, width: 4),
                        image: const DecorationImage(
                          image: AssetImage('assets/system/soufiane.jpg'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.55),
                            blurRadius: 44,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    _message.$1,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _message.$2,
                    style: const TextStyle(color: Colors.white70, fontSize: 15),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: widget.onClose,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: const Text('Nice!'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
