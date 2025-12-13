import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';

class PremiumFlowScreen extends ConsumerWidget {
  const PremiumFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(
          title: const Text('Premium'),
          backgroundColor: AppColors.primaryDark,
        ),
        body: const Center(
          child: Text('Premium Flow Screen'),
        ),
      );
}
