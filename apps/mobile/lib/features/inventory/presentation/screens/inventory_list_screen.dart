import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  final List<Map<String, dynamic>> _dummyItems = [
    {
      'name': 'بيبسي كبير',
      'quantity': 45,
      'value': 5400.0,
      'isLowStock': true,
      'isExpired': false,
    },
    {
      'name': 'باراسيتامول 500مل',
      'quantity': 12,
      'value': 1020.0,
      'isLowStock': false,
      'isExpired': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('المخزون'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _dummyItems.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final item = _dummyItems[index];
                return _buildItemCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'ابحث عن صنف',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('المورد ▾'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('الصلاحية ▾'),
                const SizedBox(width: AppSpacing.sm),
                _buildFilterChip('الفرع ▾'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {},
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        // Navigate to Item Details
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item['name'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'الكمية: ${item['quantity']} · القيمة: ${item['value'].toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                if (item['isLowStock'])
                  _buildBadge('⚠ منخفض', ColorTokens.warning),
                if (!item['isLowStock'] && !item['isExpired'])
                  _buildBadge('متوفر', ColorTokens.positive),
                const SizedBox(width: AppSpacing.sm),
                if (item['isExpired'])
                  _buildBadge('🔴 منتهي الصلاحية', ColorTokens.negative)
                else
                  _buildBadge('🟢 صلاحية سليمة', ColorTokens.positive),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
