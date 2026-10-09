import 'package:flutter/material.dart';
import '../theme/color_tokens.dart';
import '../theme/app_spacing.dart';

class OfflineBanner extends StatelessWidget {
  final bool isOffline;

  const OfflineBanner({
    super.key,
    this.isOffline = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isOffline) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      color: ColorTokens.warning, // Using warning color for offline state
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm,
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'أنت تعمل الآن في وضع عدم الاتصال (Local-First)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
