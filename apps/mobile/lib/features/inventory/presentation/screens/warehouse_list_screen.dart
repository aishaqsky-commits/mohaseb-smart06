import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class WarehouseListScreen extends StatelessWidget {
  const WarehouseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock warehouses
    final List<Map<String, dynamic>> warehouses = [
      {'id': '1', 'name': 'المخزن الرئيسي', 'type': 'مستمر', 'address': 'صنعاء - شارع الستين'},
      {'id': '2', 'name': 'فرع عدن', 'type': 'دوري', 'address': 'عدن - المنصورة'},
      {'id': '3', 'name': 'مستودع الأدوية', 'type': 'مستمر', 'address': 'صنعاء - حدة'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('الفروع والمخازن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('إضافة مخزن جديد - تحت التطوير')),
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: warehouses.length,
        itemBuilder: (context, index) {
          final warehouse = warehouses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: ColorTokens.background,
                child: Icon(Icons.warehouse, color: ColorTokens.neutralInfo),
              ),
              title: Text(warehouse['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${warehouse['address']} \nنوع الجرد: ${warehouse['type']}'),
              isThreeLine: true,
              trailing: IconButton(
                icon: const Icon(Icons.compare_arrows, color: ColorTokens.positive),
                onPressed: () {
                  context.push('/inventory/transfer', extra: {'from_warehouse_id': warehouse['id']});
                },
                tooltip: 'تحويل مخزني',
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/inventory/transfer');
        },
        backgroundColor: ColorTokens.positive,
        icon: const Icon(Icons.compare_arrows),
        label: const Text('تحويل بضاعة'),
      ),
    );
  }
}
