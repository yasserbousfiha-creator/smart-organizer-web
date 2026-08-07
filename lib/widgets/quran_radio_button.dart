import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

const String kQuranRadioStreamUrl =
    'https://stream.radiojar.com/0tpy1h0kxtzuv';

class QuranRadioButton extends StatefulWidget {
  final bool compact;
  final bool isEnglish;
  const QuranRadioButton({super.key, this.compact = false, this.isEnglish = false});

  @override
  State<QuranRadioButton> createState() => _QuranRadioButtonState();
}

class _QuranRadioButtonState extends State<QuranRadioButton> {
  final _player = AudioPlayer();
  bool _playing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _playing = state == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _loading = true);
    try {
      await _player.play(UrlSource(kQuranRadioStreamUrl));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEnglish
                ? 'Could not play the Quran radio, check your internet connection'
                : 'تعذّر تشغيل إذاعة القرآن الكريم، تحقق من اتصالك بالإنترنت'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final icon = _loading
        ? SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                widget.compact ? Colors.white : AppColors.primaryLight,
              ),
            ),
          )
        : Icon(
            _playing ? Icons.stop_rounded : Icons.radio_rounded,
            size: widget.compact ? 19 : 18,
            color: _playing ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.85),
          );

    if (widget.compact) {
      return Tooltip(
        message: widget.isEnglish ? 'Quran Radio' : 'إذاعة القرآن الكريم',
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: _toggle,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _playing
                    ? AppColors.primary.withValues(alpha: 0.22)
                    : Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: _playing
                      ? AppColors.primaryLight.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.16),
                ),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
          ),
        ),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: _playing
                ? AppColors.primary.withValues(alpha: 0.16)
                : Colors.white.withValues(alpha: 0.05),
            border: Border.all(
              color: _playing
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
                widget.isEnglish ? 'Quran Radio' : 'إذاعة القرآن الكريم',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _playing ? AppColors.primaryLight : Colors.white.withValues(alpha: 0.8),
                ),
              ),
              if (_playing) ...[
                const SizedBox(width: 7),
                _LiveDot(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveDot extends StatefulWidget {
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.3, end: 1).animate(_ctrl),
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.danger),
      ),
    );
  }
}
