import 'package:flutter/material.dart';

import '../../constants/widget_size_constants.dart';
import '../services/sensory_feedback_service.dart';

/// Accessible icon button with proper touch target size and haptic feedback
class AccessibleIconButton extends StatelessWidget {
  const AccessibleIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.semanticLabel,
    this.iconSize = WidgetSizeConstants.kDefaultIconSize,
    this.enableHaptic = true,
    this.color,
  });
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final double iconSize;
  final bool enableHaptic;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final feedbackService = SensoryFeedbackService();
    final effectiveLabel = semanticLabel ?? tooltip;

    // Ensure minimum touch target size (44x44 points)
    final button = IconButton(
      icon: Icon(icon, size: iconSize, color: color),
      onPressed: onPressed == null
          ? null
          : () {
              if (enableHaptic) {
                feedbackService.trigger(SensoryFeedbackType.buttonTap);
              }
              onPressed!();
            },
      tooltip: tooltip,
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
    );

    if (effectiveLabel != null) {
      return Semantics(
        label: effectiveLabel,
        button: true,
        enabled: onPressed != null,
        child: button,
      );
    }

    return button;
  }
}

