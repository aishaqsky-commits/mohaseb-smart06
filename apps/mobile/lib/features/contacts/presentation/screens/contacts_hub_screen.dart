import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../data/repositories/contact_repository.dart';

class ContactsHubScreen extends StatefulWidget {
  const ContactsHubScreen({super.key});

  @override
  State<ContactsHubScreen> createState() => _ContactsHubScreenState();
}

class _ContactsHubScreenState extends State<ContactsHubScreen> {
  int _selectedTabIndex = 0;
  final List<String> _tabs = ['عملاء', 'موردون', 'موظفون', 'أخرى'];

  final ContactRepository _repository = ContactRepository();
  List<Map<String, dynamic>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.getAllContacts();
      setState(() {
        _contacts = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _filterContacts(String query) async {
    setState(() => _isLoading = true);
    final data = await _repository.searchContacts(query);
    setState(() {
      _contacts = data;
      _isLoading = false;
    });
  }

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
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _contacts.isEmpty 
                  ? const Center(child: Text('لا توجد جهات اتصال'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _contacts.length,
                      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final contact = _contacts[index];
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
              onChanged: _filterContacts,
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
    final double balance = (contact['balance'] as num?)?.toDouble() ?? 0.0;
    // For simplicity: positive balance means they owe us (debit), negative means we owe them.
    final bool isDebit = balance > 0;
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
