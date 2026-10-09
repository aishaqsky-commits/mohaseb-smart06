import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/templates/template_repository.dart';
import '../../../../core/templates/template_model.dart';
import '../../../../core/widgets/amount_input_pad.dart';
import '../../../contacts/data/repositories/contact_repository.dart';
import '../../../journal/data/repositories/journal_repository.dart';
import 'package:go_router/go_router.dart';

class OperationFormScreen extends StatefulWidget {
  final String templateCode;

  const OperationFormScreen({
    super.key,
    required this.templateCode,
  });

  @override
  State<OperationFormScreen> createState() => _OperationFormScreenState();
}

class _OperationFormScreenState extends State<OperationFormScreen> {
  final TemplateRepository _templateRepo = TemplateRepository();
  final ContactRepository _contactRepo = ContactRepository();
  final JournalRepository _journalRepo = JournalRepository();

  TransactionTemplate? _template;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form Fields State
  DateTime _selectedDate = DateTime.now();
  double _amount = 0.0;
  String? _selectedContactId;
  String? _selectedContactName;
  String _paymentMethod = 'cash'; // 'cash', 'bank', 'credit'
  String _notes = '';

  // Specific Template Fields
  String _expenseCategory = 'أجور ورواتب';
  int _amortizationDays = 30; // For expense_period
  String _damageBearingParty = 'المحل (خسارة)'; // For inventory_damage
  double _downPayment = 0.0; // For partial transactions

  // Contact list cache
  List<Map<String, dynamic>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final template = await _templateRepo.loadTemplate(widget.templateCode);
      final contacts = await _contactRepo.getAllContacts();

      setState(() {
        _template = template;
        _contacts = contacts;
        _isLoading = false;

        // Auto select first contact if available
        if (contacts.isNotEmpty) {
          _selectedContactId = contacts.first['id'];
          _selectedContactName = contacts.first['name'];
        }

        // Set initial payment method according to template
        if (widget.templateCode.contains('credit')) {
          _paymentMethod = 'credit';
        } else if (widget.templateCode.contains('cash')) {
          _paymentMethod = 'cash';
        }
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showQuickAddContactDialog() {
    String newName = '';
    String newPhone = '';
    String newType = widget.templateCode.contains('purchase') ? 'مورد' : 'عميل';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('إضافة $newType جديد سريعاً'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'الاسم الثلاثي لـ $newType *',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.person),
              ),
              onChanged: (v) => newName = v,
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'رقم الهاتف (اختياري)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              onChanged: (v) => newPhone = v,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () async {
              if (newName.trim().isNotEmpty) {
                final id = await _contactRepo.addContact(
                  name: newName.trim(),
                  type: newType,
                  phone: newPhone.trim(),
                );
                final updatedContacts = await _contactRepo.getAllContacts();
                if (!ctx.mounted) return;
                Navigator.pop(ctx);
                setState(() {
                  _contacts = updatedContacts;
                  _selectedContactId = id;
                  _selectedContactName = newName.trim();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('تمت إضافة $newName وتحديده كطرف للعملية.')),
                  );
                }
              }
            },
            child: const Text('حفظ واختيار'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى إدخال مبلغ صحيح أكبر من الصفر!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Calculate Ledger & Impact
      final List<Map<String, dynamic>> ledgerEntries = [];
      final List<String> impactLines = [];

      String debitAccount = 'default_cash';
      String creditAccount = 'sales_revenue';

      if (widget.templateCode.startsWith('sale')) {
        creditAccount = 'إيراد المبيعات (4101)';
        if (_paymentMethod == 'cash') {
          debitAccount = 'الصندوق الرئيسي (1101)';
          impactLines.add('🟢 زاد الصندوق بمبلغ ${_amount.toStringAsFixed(0)} ريال');
          impactLines.add('🟢 زادت المبيعات بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        } else {
          debitAccount = 'العملاء (${_selectedContactName ?? 'آجل'})';
          impactLines.add('🔴 زاد دين العميل ${_selectedContactName ?? ''} بمبلغ ${_amount.toStringAsFixed(0)} ريال');
          impactLines.add('🟢 زادت المبيعات بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        }
      } else if (widget.templateCode.startsWith('purchase')) {
        debitAccount = 'المشتريات / المخزون (1201)';
        if (_paymentMethod == 'cash') {
          creditAccount = 'الصندوق الرئيسي (1101)';
          impactLines.add('🟢 زاد المخزون بمبلغ ${_amount.toStringAsFixed(0)} ريال');
          impactLines.add('🔴 نقص الصندوق بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        } else {
          creditAccount = 'الموردين (${_selectedContactName ?? 'آجل'})';
          impactLines.add('🟢 زاد المخزون بمبلغ ${_amount.toStringAsFixed(0)} ريال');
          impactLines.add('🔴 زاد التزام المورد ${_selectedContactName ?? ''} بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        }
      } else if (widget.templateCode == 'customer_collection') {
        debitAccount = 'الصندوق الرئيسي (1101)';
        creditAccount = 'العملاء (${_selectedContactName ?? 'عميل'})';
        impactLines.add('🟢 زاد الصندوق بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        impactLines.add('🟢 انخفض دين العميل ${_selectedContactName ?? ''} بمبلغ ${_amount.toStringAsFixed(0)} ريال');
      } else if (widget.templateCode == 'supplier_payment') {
        debitAccount = 'الموردين (${_selectedContactName ?? 'مورد'})';
        creditAccount = 'الصندوق الرئيسي (1101)';
        impactLines.add('🟢 انخفض التزام المورد ${_selectedContactName ?? ''} بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        impactLines.add('🔴 نقص الصندوق بمبلغ ${_amount.toStringAsFixed(0)} ريال');
      } else if (widget.templateCode == 'inventory_damage') {
        debitAccount = 'خسائر تلف وهالك بضاعة (5301)';
        creditAccount = 'المخزون (1201)';
        impactLines.add('🔴 خسارة تالف بضاعة بمبلغ ${_amount.toStringAsFixed(0)} ريال محملة على: $_damageBearingParty');
        impactLines.add('🔴 انخفض المخزون بمبلغ ${_amount.toStringAsFixed(0)} ريال');
      } else if (widget.templateCode.startsWith('expense')) {
        debitAccount = 'مصروفات تشغيلية: $_expenseCategory';
        creditAccount = 'الصندوق الرئيسي (1101)';
        if (widget.templateCode == 'expense_period') {
          final dailyShare = _amount / _amortizationDays;
          impactLines.add('📊 إجمالي المصروف الدوري: ${_amount.toStringAsFixed(0)} ريال موزع على $_amortizationDays يوماً');
          impactLines.add('💡 حصة اليوم التشغيلية: ${dailyShare.toStringAsFixed(1)} ريال تخصم من ربح اليوم');
        } else {
          impactLines.add('🔴 مصروف تشغيلي بمبلغ ${_amount.toStringAsFixed(0)} ريال ($_expenseCategory)');
          impactLines.add('🔴 نقص الصندوق بمبلغ ${_amount.toStringAsFixed(0)} ريال');
        }
      } else {
        debitAccount = 'الصندوق / الحساب المعني';
        creditAccount = 'الحساب المقابل';
        impactLines.add('🟢 تم تسجيل الأثر المالي للقيد بمبلغ ${_amount.toStringAsFixed(0)} ريال');
      }

      ledgerEntries.add({
        'account_id': debitAccount,
        'is_debit': true,
        'amount': _amount,
      });
      ledgerEntries.add({
        'account_id': creditAccount,
        'is_debit': false,
        'amount': _amount,
      });

      // 2. Save via Journal Repository
      await _journalRepo.saveJournalEntry(
        templateId: widget.templateCode,
        totalAmount: _amount,
        ledgerEntries: ledgerEntries,
        description: _notes.isNotEmpty ? _notes : (_template?.ui.displayNameAr ?? 'عملية مالية'),
      );

      if (mounted) {
        setState(() => _isSaving = false);
        context.pushReplacement(
          '/operations/summary',
          extra: {
            'title': '✅ تم تنفيذ ${_template?.ui.displayNameAr ?? 'العملية'} بنجاح',
            'amount': _amount,
            'contactName': _selectedContactName,
            'templateCode': widget.templateCode,
            'impactLines': impactLines,
            'description': _notes,
            'debitAccount': debitAccount,
            'creditAccount': creditAccount,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في حفظ العملية: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final templateName = _template?.ui.displayNameAr ?? 'عملية مالية';
    final templateDesc = _template?.ui.descriptionAr ?? '';
    final isDamage = widget.templateCode == 'inventory_damage';
    final isExpense = widget.templateCode.startsWith('expense');
    final isPeriodExpense = widget.templateCode == 'expense_period';
    final isPartial = widget.templateCode.contains('partial');
    final requiresContact = widget.templateCode.contains('credit') ||
        widget.templateCode.contains('collection') ||
        widget.templateCode.contains('payment') ||
        widget.templateCode.contains('return') ||
        isPartial;

    return Scaffold(
      appBar: AppBar(
        title: Text(templateName),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Description Banner
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: ColorTokens.neutralInfo),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        templateDesc,
                        style: TextStyle(color: Colors.blue.shade900, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Date Picker Field
              Text('التاريخ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Amount Input Field with AmountInputPad
              Text('المبلغ الإجمالي (ريال) *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              AmountInputPad(
                initialAmount: _amount,
                onChanged: (val) => setState(() => _amount = val),
              ),

              // Partial down-payment field if partial
              if (isPartial) ...[
                const SizedBox(height: AppSpacing.md),
                Text('الدفعة النقدية المقدمة الآن', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'أدخل الدفعة المستلمة نقداً',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  onChanged: (v) => setState(() => _downPayment = double.tryParse(v) ?? 0.0),
                ),
                if (_amount > _downPayment)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'المتبقي آجل كدين: ${(_amount - _downPayment).toStringAsFixed(0)} ريال',
                      style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Contact Selector with Quick Add (for Credit, Collections, Payments, etc.)
              if (requiresContact) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('الطرف (عميل / مورد) *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: _showQuickAddContactDialog,
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('إضافة طرف جديد +', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                DropdownButtonFormField<String>(
                  initialValue: _selectedContactId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.people_outline),
                    hintText: 'اختر العميل أو المورد',
                  ),
                  items: _contacts.map((c) {
                    return DropdownMenuItem(
                      value: c['id'] as String,
                      child: Text('${c['name']} (${c['type']})'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      final item = _contacts.firstWhere((c) => c['id'] == val);
                      setState(() {
                        _selectedContactId = val;
                        _selectedContactName = item['name'];
                      });
                    }
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Expense Specific Fields
              if (isExpense) ...[
                Text('تصنيف المصروف *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _expenseCategory,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.category)),
                  items: const [
                    DropdownMenuItem(value: 'أجور ورواتب', child: Text('أجور ورواتب للموظفين')),
                    DropdownMenuItem(value: 'إيجارات', child: Text('إيجارات محلات ومستودعات')),
                    DropdownMenuItem(value: 'كهرباء ومياه', child: Text('فواتير كهرباء ومياه')),
                    DropdownMenuItem(value: 'نظافة وصيانة', child: Text('نظافة وصيانة دورية')),
                    DropdownMenuItem(value: 'دعاية وإعلان', child: Text('مواد دعاية وتسويق')),
                    DropdownMenuItem(value: 'مشتريات عامة ونثريات', child: Text('مشتريات عامة ونثريات')),
                    DropdownMenuItem(value: 'أخرى', child: Text('مصروفات أخرى (توضح بالبيان)')),
                  ],
                  onChanged: (v) => setState(() => _expenseCategory = v ?? _expenseCategory),
                ),
                const SizedBox(height: AppSpacing.lg),

                if (isPeriodExpense) ...[
                  Text('فترة التوزيع (لحساب تكلفة نشاط اليوم) *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextFormField(
                    initialValue: _amortizationDays.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد الأيام الموزع عليها (مثال: 30 يوماً لشهر)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timer),
                    ),
                    onChanged: (v) => setState(() => _amortizationDays = int.tryParse(v) ?? 30),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ],

              // Damage Specific Fields
              if (isDamage) ...[
                Text('جهة تحمل التالف *', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _damageBearingParty,
                  decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.delete_sweep)),
                  items: const [
                    DropdownMenuItem(value: 'المحل (خسارة)', child: Text('المحل (خسارة أرباح وتشغيل)')),
                    DropdownMenuItem(value: 'المورد (خصم من حسابه)', child: Text('المورد (خصم من رصيد المورد)')),
                    DropdownMenuItem(value: 'جهة أخرى / موظف', child: Text('جهة أخرى أو موظف مسؤول')),
                  ],
                  onChanged: (v) => setState(() => _damageBearingParty = v ?? _damageBearingParty),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // Notes / البيان
              Text('البيان / الملاحظات', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'وصف أو ملاحظات إضافية حول العملية...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                ),
                onChanged: (v) => _notes = v,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'جاري الحفظ...' : 'حفظ العملية الآن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorTokens.positive,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
