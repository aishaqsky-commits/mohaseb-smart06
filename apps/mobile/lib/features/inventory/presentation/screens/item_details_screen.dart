import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class ItemDetailsScreen extends StatelessWidget {
  final String itemName;
  final int totalQuantity;
  final double averageCost;

  const ItemDetailsScreen({
    super.key,
    required this.itemName,
    required this.totalQuantity,
    required this.averageCost,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(itemName),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.white,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرصيد الإجمالي: $totalQuantity علبة',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'متوسط التكلفة: ${averageCost.toStringAsFixed(0)} ريال/علبة',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'الدفعات (الأحدث أولاً)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: [
                _buildBatchCard(
                  context,
                  batchId: 'B-2024-09',
                  supplier: 'شركة النور',
                  expiryDate: '2025-01-10',
                  isExpired: true,
                  quantity: 12,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildBatchCard(
                  context,
                  batchId: 'B-2024-11',
                  supplier: 'مورد محلي',
                  expiryDate: 'بعد 20 يوم',
                  isExpired: false,
                  isExpiringSoon: true,
                  quantity: 48,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    child: const Text('تعديل الصنف'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    child: const Text('تحويل بين المخازن'),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBatchCard(
    BuildContext context, {
    required String batchId,
    required String supplier,
    required String expiryDate,
    required int quantity,
    bool isExpired = false,
    bool isExpiringSoon = false,
  }) {
    Color statusColor = Colors.grey;
    if (isExpired) {
      statusColor = ColorTokens.negative;
    } else if (isExpiringSoon) {
      statusColor = ColorTokens.warning;
    } else {
      statusColor = ColorTokens.positive;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, color: statusColor, size: 12),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'دفعة $batchId',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                if (supplier.isNotEmpty)
                  Text('المورد: $supplier', style: Theme.of(context).textTheme.bodyMedium),
                Text(
                  'تنتهي: $expiryDate ${isExpired ? "(منتهية)" : ""}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isExpired ? ColorTokens.negative : Colors.black87,
                      ),
                ),
                const SizedBox(height: 4),
                Text('الكمية: $quantity علبة', style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
        ],
      ),
    );
  }
}
