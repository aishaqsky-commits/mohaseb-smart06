import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

class OperationSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> summaryData;

  const OperationSummaryScreen({
    super.key,
    required this.summaryData,
  });

  @override
  Widget build(BuildContext context) {
    final title = summaryData['title'] ?? 'تمت العملية بنجاح';
    final amount = summaryData['amount'] ?? 0.0;
    final contactName = summaryData['contactName'];
    final impactLines = (summaryData['impactLines'] as List<String>?) ?? [];
    final description = summaryData['description'] ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('ملخص العملية'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: ColorTokens.positive.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: ColorTokens.positive,
                          size: 56,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: ColorTokens.positive,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.unit),
                    Center(
                      child: Text(
                        'تم تسجيل القيد المحاسبي وحفظه بنمط Local-First بنجاح',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Amount Card
                    Card(
                      elevation: 0,
                      color: Colors.grey.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          children: [
                            Text(
                              'إجمالي المبلغ',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${amount.toStringAsFixed(0)} ريال',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: ColorTokens.neutralInfo,
                                  ),
                            ),
                            if (contactName != null && contactName.toString().isNotEmpty) ...[
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('الطرف المعني:'),
                                  Text(
                                    contactName.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                            if (description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('البيان:'),
                                  Expanded(
                                    child: Text(
                                      description,
                                      style: TextStyle(color: Colors.grey.shade700),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'الأثر المالي المباشر (المعادلة المحاسبية):',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    ...impactLines.map((line) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_circle_up, color: ColorTokens.positive, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  line,
                                  style: TextStyle(
                                    color: Colors.green.shade900,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: AppSpacing.lg),
                    // Accountant Double-entry breakdown (optional expansion)
                    ExpansionTile(
                      leading: const Icon(Icons.account_balance, color: Colors.blueGrey),
                      title: const Text(
                        'عرض القيد المزدوج الفني (للمحاسب)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.md),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('الحساب', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('مدين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                    Text('دائن', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('حساب المدين (${summaryData['debitAccount'] ?? 'الصندوق'})', style: const TextStyle(fontSize: 12)),
                                    Text('${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                                    const Text('-', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('حساب الدائن (${summaryData['creditAccount'] ?? 'المبيعات'})', style: const TextStyle(fontSize: 12)),
                                    const Text('-', style: TextStyle(fontSize: 12)),
                                    Text('${amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                                  ],
                                ),
                                const Divider(),
                                const Text(
                                  'القيد متوازن تماماً (القيد المزدوج: مدين = دائن)',
                                  style: TextStyle(fontSize: 11, color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📤 جاري مشاركة الإيصال عبر تطبيق واتساب...')),
                        );
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('مشاركة إيصال'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.go('/'),
                      icon: const Icon(Icons.home, size: 18),
                      label: const Text('الرئيسية'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorTokens.neutralInfo,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
