import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class ChecksListScreen extends StatefulWidget {
  const ChecksListScreen({super.key});

  @override
  State<ChecksListScreen> createState() => _ChecksListScreenState();
}

class _ChecksListScreenState extends State<ChecksListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _receivables = [
    {
      'id': '1',
      'contact_name': 'شركة الوحدة للتجارة',
      'amount': 500000.0,
      'currency': 'YER',
      'due_date': '2026-11-15',
      'check_number': '100234',
      'status': 'معلق',
    },
    {
      'id': '2',
      'contact_name': 'محلات سعيد للصرافة',
      'amount': 2000.0,
      'currency': 'SAR',
      'due_date': '2026-10-15',
      'check_number': '99381',
      'status': 'مستحق',
    }
  ];

  final List<Map<String, dynamic>> _payables = [
    {
      'id': '3',
      'contact_name': 'مؤسسة إخوان ثابت',
      'amount': 1500000.0,
      'currency': 'YER',
      'due_date': '2026-12-01',
      'check_number': '54123',
      'status': 'معلق',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'مستحق': return ColorTokens.negative;
      case 'محصل': return ColorTokens.positive;
      case 'معلق': return ColorTokens.warning;
      default: return ColorTokens.neutralInfo;
    }
  }

  Widget _buildCheckList(List<Map<String, dynamic>> checks, bool isReceivable) {
    if (checks.isEmpty) {
      return const Center(child: Text('لا توجد شيكات'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: checks.length,
      itemBuilder: (context, index) {
        final check = checks[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () {
              // Navigate to details
              context.push('/checks/details', extra: check);
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        check['contact_name'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(check['status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _getStatusColor(check['status']).withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          check['status'],
                          style: TextStyle(
                            color: _getStatusColor(check['status']),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      )
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('رقم الشيك: ${check['check_number']}', style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('تاريخ الاستحقاق: ${check['due_date']}', style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Text(
                        '${check['amount']} ${check['currency']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الشيكات وأوراق القبض/الدفع'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          indicatorColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'أوراق القبض (شيكات واردة)'),
            Tab(text: 'أوراق الدفع (شيكات صادرة)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckList(_receivables, true),
          _buildCheckList(_payables, false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open add check modal or screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('إضافة شيك جديد - قيد التطوير')),
          );
        },
        backgroundColor: ColorTokens.positive,
        child: const Icon(Icons.add),
      ),
    );
  }
}
