import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class CurrenciesListScreen extends StatefulWidget {
  const CurrenciesListScreen({super.key});

  @override
  State<CurrenciesListScreen> createState() => _CurrenciesListScreenState();
}

class _CurrenciesListScreenState extends State<CurrenciesListScreen> {
  final List<Map<String, dynamic>> _currencies = [
    {'code': 'YER', 'name': 'ريال يمني', 'rate': 1.0, 'is_base': true, 'is_active': true},
    {'code': 'SAR', 'name': 'ريال سعودي', 'rate': 140.5, 'is_base': false, 'is_active': true},
    {'code': 'USD', 'name': 'دولار أمريكي', 'rate': 530.0, 'is_base': false, 'is_active': true},
    {'code': 'AED', 'name': 'درهم إماراتي', 'rate': 144.2, 'is_base': false, 'is_active': false},
  ];

  void _updateRate(int index, double newRate) {
    setState(() {
      _currencies[index]['rate'] = newRate;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث سعر الصرف بنجاح')),
    );
  }

  void _showEditRateDialog(int index) {
    final currency = _currencies[index];
    if (currency['is_base']) return;

    final controller = TextEditingController(text: currency['rate'].toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحديث سعر الصرف: ${currency['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'سعر الصرف مقابل العملة المحلية',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final newRate = double.tryParse(controller.text);
              if (newRate != null && newRate > 0) {
                _updateRate(index, newRate);
                Navigator.pop(context);
              }
            },
            child: const Text('تحديث'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعدد العملات وأسعار الصرف'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: _currencies.length,
        itemBuilder: (context, index) {
          final currency = _currencies[index];
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              leading: CircleAvatar(
                backgroundColor: currency['is_base'] ? ColorTokens.positive.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                foregroundColor: currency['is_base'] ? ColorTokens.positive : Colors.black87,
                child: Text(currency['code'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              title: Row(
                children: [
                  Text(currency['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (currency['is_base']) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorTokens.positive,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('العملة الأساسية', style: TextStyle(color: Colors.white, fontSize: 10)),
                    )
                  ]
                ],
              ),
              subtitle: Text(
                currency['is_base'] 
                  ? 'سعر ثابت' 
                  : '1 ${currency['code']} = ${currency['rate']} ${_currencies.firstWhere((c) => c['is_base'])['code']}',
                style: const TextStyle(color: Colors.grey),
              ),
              trailing: Switch(
                value: currency['is_active'] as bool,
                onChanged: currency['is_base'] ? null : (val) {
                  setState(() {
                    _currencies[index]['is_active'] = val;
                  });
                },
              ),
              onTap: () => _showEditRateDialog(index),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة عملة جديدة - قيد التطوير')),
          );
        },
        backgroundColor: ColorTokens.neutralInfo,
        icon: const Icon(Icons.add),
        label: const Text('إضافة عملة'),
      ),
    );
  }
}
