import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class SmartCommandSheet extends StatefulWidget {
  const SmartCommandSheet({super.key});

  /// Helper to show this bottom sheet
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const SmartCommandSheet(),
      ),
    );
  }

  @override
  State<SmartCommandSheet> createState() => _SmartCommandSheetState();
}

class _SmartCommandSheetState extends State<SmartCommandSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _isProcessing = false;
  Map<String, dynamic>? _parsedResult;

  void _processCommand() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isProcessing = true;
      _parsedResult = null;
    });

    // Mocking an AI delay
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Mocking a parsed AI result (e.g. from NLP backend)
    setState(() {
      _isProcessing = false;
      _parsedResult = {
        'template': 'بيع آجل',
        'contact': 'أحمد سالم',
        'items': 'بيبسي كبير × 5 كراتين',
        'amount': '15,000 ريال',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.mic, color: ColorTokens.neutralInfo),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'الأمر الذكي',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (_parsedResult == null) _buildInputSection(),
          if (_isProcessing) _buildLoadingSection(),
          if (_parsedResult != null) _buildConfirmationSection(),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      children: [
        TextField(
          controller: _controller,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'مثال: "بعت لأحمد خمسة كراتين بيبسي بخمسطعشر ألف أجل"',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _isProcessing ? null : _processCommand,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('تحليل العملية'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '⏳ جاري الفهم والاستخراج...',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationSection() {
    final result = _parsedResult!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'فهمت التالي، تأكد قبل الحفظ:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: ColorTokens.neutralInfo.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: ColorTokens.neutralInfo.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              _buildResultRow('القالب', result['template'], true),
              const Divider(),
              _buildResultRow('العميل', result['contact'], true),
              const Divider(),
              _buildResultRow('الصنف', result['items'], false),
              const Divider(),
              _buildResultRow('المبلغ', result['amount'], false),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // Navigate to the dynamic template form with prefilled data
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.edit),
                label: const Text('تعديل التفاصيل'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Final save logic (Optimistic UI)
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.check_circle),
                label: const Text('تأكيد وحفظ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.positive,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildResultRow(String label, String value, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700)),
          Row(
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (isVerified) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: ColorTokens.positive, size: 16),
              ]
            ],
          ),
        ],
      ),
    );
  }
}
