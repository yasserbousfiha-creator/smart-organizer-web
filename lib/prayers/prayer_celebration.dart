import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

class PrayerCelebrationOverlay extends StatefulWidget {
  const PrayerCelebrationOverlay({
    super.key,
    required this.onClose,
    this.allDone = false,
  });

  final VoidCallback onClose;
  final bool allDone;

  static const _singlePrayerMessages = [
    ('عبدالرحمن البطل! 🦸', 'صلاة مقبولة إن شاء الله، كمل الباقي 🤲'),
    ('شاطر يا عبدالرحمن! 💪', 'الله يجعلها فميزان حسناتك'),
    ('ممتاز يا عبدالرحمن! 👏', 'استمر هكذا، باقي شوية وتكمل يومك'),
    ('ما شاء الله عليك! ✨', 'فخورين بيك بزاف يا بطل'),
    ('الله يبارك فيك! 🌙', 'خطوة قريبة ديال الجنة إن شاء الله'),
  ];

  static (String, String) randomMessage() {
    final list = _singlePrayerMessages;
    return list[Random().nextInt(list.length)];
  }

  @override
  State<PrayerCelebrationOverlay> createState() => _PrayerCelebrationOverlayState();
}

class _FloatingEmoji {
  _FloatingEmoji({
    required this.emoji,
    required this.left,
    required this.delay,
    required this.controller,
  });

  final String emoji;
  final double left;
  final Duration delay;
  final AnimationController controller;
}

class _PrayerCelebrationOverlayState extends State<PrayerCelebrationOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _photoController;
  late final List<_FloatingEmoji> _emojis;
  late final (String, String) _message;
  final _player = AudioPlayer();

  static const _emojiChoices = ['😂', '💋', '❤️', '🎉', '✨'];

  @override
  void initState() {
    super.initState();
    _message = widget.allDone
        ? ('كملتي الصلوات الخمس اليوم يا بطل! 🎉🌙', 'الله يبارك فيك يا عبدالرحمن، فخورين بيك بزاف 😂💋')
        : PrayerCelebrationOverlay.randomMessage();
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

    _playCelebrationSounds();
  }

  Future<void> _playCelebrationSounds() async {
    try {
      await _player.play(AssetSource('prayers/laugh.mp3'));
      await Future.delayed(const Duration(milliseconds: 1100));
      await _player.play(AssetSource('prayers/kiss.mp3'));
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
                    scale: CurvedAnimation(
                      parent: _photoController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryLight, width: 4),
                        image: const DecorationImage(
                          image: AssetImage('assets/prayers/abdulrahman.jpg'),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
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
                    child: const Text('تمام 🥰'),
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
