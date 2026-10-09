import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/app_spacing.dart';

class SimpleSummaryCard extends StatelessWidget {
  final String title;
  final String amountText;
  final bool isPositive;

  const SimpleSummaryCard({
    super.key,
    required this.title,
    required this.amountText,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPositive ? ColorTokens.positive : ColorTokens.negative;
    final iconData = isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ColorTokens.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amountText,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                iconData,
                color: color,
                size: 20,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
