import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final double current;
  final double max;

  const ProgressBar({
    super.key,
    required this.current,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final color = pct >= 1.0
        ? AppColors.accentRed
        : pct >= 0.8
            ? AppColors.accentAmber
            : AppColors.accentGreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(current.toStringAsFixed(2),
                style: const TextStyle(fontSize: 11, color: AppColors.dark300)),
            Text(max.toStringAsFixed(2),
                style: const TextStyle(fontSize: 11, color: AppColors.dark300)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct,
            backgroundColor: AppColors.dark700,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}
