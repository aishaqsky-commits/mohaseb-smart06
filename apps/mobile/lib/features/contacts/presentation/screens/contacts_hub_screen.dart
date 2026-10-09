import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';

class ContactsHubScreen extends StatefulWidget {
  const ContactsHubScreen({super.key});

  @override
  State<ContactsHubScreen> createState() => _ContactsHubScreenState();
}

class _ContactsHubScreenState extends State<ContactsHubScreen> {
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['عملاء', 'موردون', 'موظفون', 'أخرى'];

  final List<Map<String, dynamic>> _dummyContacts = [
    {
      'name': 'أحمد سالم',
      'type': 'عميل',
      'balance': 25000.0,
      'isDebit': true, // عليه
      'lastAction': 'منذ يومين',
    },
    {
      'name': 'محل الأمانة',
      'type': 'مورد',
      'balance': 0.0,
      'isDebit': false,
      'lastAction': 'متزن',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جهات الاتصال'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedTabs(),
          _buildSearchAndFilter(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _dummyContacts.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final contact = _dummyContacts[index];
                return _buildContactCard(contact);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentedTabs() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(left: AppSpacing.sm),
            child: ChoiceChip(
              label: Text(_tabs[index]),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTabIndex = index);
                }
              },
              selectedColor: ColorTokens.neutralInfo.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? ColorTokens.neutralInfo : Colors.black87,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الهاتف',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {},
              tooltip: 'فرز: الأكثر مديونية',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    final bool isDebit = contact['isDebit'];
    final double balance = contact['balance'];
    final bool isZero = balance == 0;

    Color balanceColor = Colors.grey;
    if (!isZero) {
      balanceColor = isDebit ? ColorTokens.negative : ColorTokens.positive;
    } else {
      balanceColor = ColorTokens.positive; // متزن
    }

    return InkWell(
      onTap: () {
        // Navigate to contact details
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
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade100,
              child: const Icon(Icons.person, color: Colors.grey),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'],
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isZero ? 'متزن' : 'آخر عملية: ${contact['lastAction']}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 10,
                      color: balanceColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      balance.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: balanceColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
