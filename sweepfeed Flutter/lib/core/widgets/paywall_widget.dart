import 'package:flutter/material.dart';
import 'package:sweepfeed_app/core/theme/app_text_styles.dart';

class PaywallWidget extends StatelessWidget {
  final String message;
  final VoidCallback onPressed;

  const PaywallWidget({
    super.key,
    required this.message,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 60,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onPressed,
              child: const Text('Subscribe Now'),
            ),
          ],
        ),
      ),
    );
  }
}
