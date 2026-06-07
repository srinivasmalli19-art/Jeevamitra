import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class JmVoiceButton extends StatefulWidget {
  final VoidCallback onTap;
  final bool isListening;
  final double size;

  const JmVoiceButton({
    super.key,
    required this.onTap,
    this.isListening = false,
    this.size = 56,
  });

  @override
  State<JmVoiceButton> createState() => _JmVoiceButtonState();
}

class _JmVoiceButtonState extends State<JmVoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.isListening;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) => Transform.scale(
          scale: isListening ? _scale.value : 1.0,
          child: child,
        ),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isListening ? AppColors.error : AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: (isListening ? AppColors.error : AppColors.primary)
                    .withAlpha(77),
                blurRadius: isListening ? 16 : 8,
                spreadRadius: isListening ? 4 : 0,
              ),
            ],
          ),
          child: Icon(
            isListening ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: widget.size * 0.45,
          ),
        ),
      ),
    );
  }
}

/// Compact mic icon for use inside text fields / action bars
class JmMicIcon extends StatelessWidget {
  final VoidCallback onTap;
  final bool isListening;

  const JmMicIcon({super.key, required this.onTap, this.isListening = false});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        isListening ? Icons.stop_rounded : Icons.mic_rounded,
        color: isListening ? AppColors.error : AppColors.primary,
        size: AppSpacing.iconMd,
      ),
      tooltip: isListening ? 'Stop listening' : 'Voice input',
    );
  }
}
