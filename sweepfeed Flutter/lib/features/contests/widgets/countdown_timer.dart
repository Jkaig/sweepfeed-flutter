import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({required this.endDate, super.key});
  final DateTime endDate;

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.endDate.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining = widget.endDate.difference(DateTime.now());
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_timeRemaining.isNegative) {
      return Text(
        'Contest Ended',
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.errorRed),
      );
    }

    final days = _timeRemaining.inDays;
    final hours = _timeRemaining.inHours % 24;
    final minutes = _timeRemaining.inMinutes % 60;

    return Text(
      '$days d $hours h $minutes m remaining',
      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textLight),
      overflow: TextOverflow.ellipsis,
    );
  }
}
