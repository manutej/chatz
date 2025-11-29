import 'package:flutter/material.dart';
import 'package:chatz/core/themes/app_colors.dart';
import 'package:chatz/core/themes/app_text_styles.dart';

/// Animated typing indicator widget
class TypingIndicator extends StatefulWidget {
  final String userName;
  final bool showAvatar;

  const TypingIndicator({
    super.key,
    required this.userName,
    this.showAvatar = false,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (widget.showAvatar) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _getAvatarColor(),
              child: Text(
                widget.userName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.receiverBubbleDark
                  : AppColors.receiverBubbleLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${widget.userName} is typing',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.typing,
                  ),
                ),
                const SizedBox(height: 8),
                _TypingDots(controller: _controller),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor() {
    final colorIndex = widget.userName.hashCode % AppColors.groupColors.length;
    return AppColors.groupColors[colorIndex];
  }
}

/// Animated dots for typing indicator
class _TypingDots extends StatelessWidget {
  final AnimationController controller;

  const _TypingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _TypingDot(
          controller: controller,
          delay: 0,
        ),
        const SizedBox(width: 4),
        _TypingDot(
          controller: controller,
          delay: 0.2,
        ),
        const SizedBox(width: 4),
        _TypingDot(
          controller: controller,
          delay: 0.4,
        ),
      ],
    );
  }
}

/// Single animated dot
class _TypingDot extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _TypingDot({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final animation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(
          delay,
          delay + 0.6,
          curve: Curves.easeInOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.textSecondaryLight,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}
