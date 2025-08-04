import 'package:flutter/material.dart';
import 'package:sweep_feed/core/widgets/primary_button.dart';

class EnterButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool enabled;
  final String text;

  const EnterButton({
    super.key,
    this.onPressed,
    this.enabled = true,
    this.text = "Enter",
  });

  @override
  Widget build(BuildContext context) {
    // The button should take the width available in its parent.
    // If used in a Row, it might need to be wrapped in Flexible or Expanded.
    // For ContestCard, it's expected to be relatively small, so default PrimaryButton size is fine.
    return PrimaryButton(
      text: text,
      onPressed: enabled ? onPressed : null,
      isLoading: false, // Assuming EnterButton itself doesn't manage isLoading directly
    );
  }
}
