import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class CheckDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> checkData;
  const CheckDetailsScreen({super.key, required this.checkData});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مستحق': return ColorTokens.negative;
      case 'محصل': return ColorTokens.positive;
      case 'معلق': return ColorTokens.warning;
      default: return ColorTokens.neutralInfo;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الشيك'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 48, color: ColorTokens.neutralInfo),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      '${checkData['amount']} ${checkData['currency']}',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(checkData['status']).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        checkData['status'],
                        style: TextStyle(
                          color: _getStatusColor(checkData['status']),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Text('معلومات الشيك', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('الجهة'),
              subtitle: Text(checkData['contact_name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.numbers),
              title: const Text('رقم الشيك'),
              subtitle: Text(checkData['check_number'], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('تاريخ الاستحقاق'),
              subtitle: Text(checkData['due_date'], style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (checkData['status'] == 'معلق' || checkData['status'] == 'مستحق')
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحصيل الشيك بنجاح وتوليد القيد المحاسبي.'),
                      backgroundColor: ColorTokens.positive,
                    ),
                  );
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('تحصيل الشيك (إيداع/صرف)', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.positive,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
