import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class ContactDetailsScreen extends StatelessWidget {
  final String contactName;
  final double balance;
  final bool isDebit;

  const ContactDetailsScreen({
    super.key,
    required this.contactName,
    required this.balance,
    required this.isDebit,
  });

  @override
  Widget build(BuildContext context) {
    Color balanceColor = balance == 0
        ? ColorTokens.positive
        : isDebit
            ? ColorTokens.negative
            : ColorTokens.positive;

    return Scaffold(
      appBar: AppBar(
        title: Text(contactName),
        actions: [
          IconButton(icon: const Icon(Icons.phone), onPressed: () {}),
          IconButton(icon: const Icon(Icons.chat), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرصيد: ${balance.toStringAsFixed(0)} ${isDebit && balance > 0 ? "عليه" : "له"}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: balanceColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('كشف الحساب'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text('الفواتير المفتوحة'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                _buildTransactionRow(context, '15 يناير', 'فاتورة بيع', 15000, true),
                const Divider(),
                _buildTransactionRow(context, '10 يناير', 'تحصيل نقدي', 5000, false),
                const Divider(),
                _buildTransactionRow(context, '05 يناير', 'رصيد افتتاحي', 15000, true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.monetization_on),
                    label: const Text('تحصيل'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorTokens.positive,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                    label: const Text('إرسال تذكير'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTransactionRow(BuildContext context, String date, String desc, double amount, bool isIncrease) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(desc, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(date, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
            ],
          ),
          Text(
            '${isIncrease ? "+" : "-"}${amount.toStringAsFixed(0)}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: isIncrease ? ColorTokens.negative : ColorTokens.positive,
                  fontWeight: FontWeight.bold,
                ),
          )
        ],
      ),
    );
  }
}
