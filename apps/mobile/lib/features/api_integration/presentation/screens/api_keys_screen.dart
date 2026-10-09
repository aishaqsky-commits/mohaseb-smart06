import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});

  @override
  State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final List<Map<String, dynamic>> _apiKeys = [
    {
      'id': 'key_1',
      'name': 'ربط متجر سلة',
      'key': 'sk_live_51Mxxxxx...',
      'created_at': '2026-10-01',
      'last_used': 'قبل ساعتين',
      'status': 'نشط',
    },
    {
      'id': 'key_2',
      'name': 'تطبيق المناديب الخاص',
      'key': 'sk_live_98Yxxxxx...',
      'created_at': '2026-09-15',
      'last_used': 'الآن',
      'status': 'نشط',
    }
  ];

  void _copyToClipboard(String key) {
    Clipboard.setData(ClipboardData(text: key));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم نسخ المفتاح بنجاح!')),
    );
  }

  void _revokeKey(int index) {
    setState(() {
      _apiKeys[index]['status'] = 'ملغى';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إبطال المفتاح')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('واجهات الربط البرمجي (API)'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: ColorTokens.neutralInfo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: ColorTokens.neutralInfo.withValues(alpha: 0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, color: ColorTokens.neutralInfo),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التكامل الخارجي',
                        style: TextStyle(fontWeight: FontWeight.bold, color: ColorTokens.neutralInfo),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'استخدم هذه المفاتيح لربط حسابك مع المنصات الخارجية مثل المتاجر الإلكترونية أو أنظمة الفوترة الضريبية (ZATCA). يرجى الحفاظ على سرية هذه المفاتيح.',
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Text(
            'المفاتيح النشطة',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._apiKeys.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isActive = item['status'] == 'نشط';

            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? ColorTokens.positive.withValues(alpha: 0.1) : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item['status'],
                            style: TextStyle(
                              color: isActive ? ColorTokens.positive : Colors.grey,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item['key'],
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: Colors.grey.shade600,
                              decoration: isActive ? null : TextDecoration.lineThrough,
                            ),
                          ),
                        ),
                        if (isActive)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20, color: ColorTokens.neutralInfo),
                            onPressed: () => _copyToClipboard(item['key']),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('آخر استخدام: ${item['last_used']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                        if (isActive)
                          TextButton(
                            onPressed: () => _revokeKey(index),
                            child: const Text('إبطال المفتاح', style: TextStyle(color: ColorTokens.negative)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إنشاء مفتاح جديد - سيتم توفيره لاحقاً')),
          );
        },
        backgroundColor: ColorTokens.positive,
        icon: const Icon(Icons.key),
        label: const Text('إنشاء مفتاح API'),
      ),
    );
  }
}
