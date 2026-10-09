import 'package:flutter/material.dart';
import '../../../../core/templates/template_model.dart';
import '../../../../core/templates/dynamic_template_form.dart';
import '../../data/repositories/journal_repository.dart';

class JournalEntryScreen extends StatefulWidget {
  final TransactionTemplate template;
  final Map<String, dynamic>? initialData;

  const JournalEntryScreen({
    super.key,
    required this.template,
    this.initialData,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final JournalRepository _repository = JournalRepository();
  Map<String, dynamic> _currentData = {};
  bool _isSaving = false;

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    try {
      // 1. Build Ledger Entries based on rules
      List<Map<String, dynamic>> ledgerEntries = [];
      double totalAmount = double.tryParse(_currentData['amount']?.toString() ?? '0') ?? 0;
      
      ledgerEntries.add({
        'account_id': _currentData['contact_id'] ?? 'default_cash',
        'is_debit': true,
        'amount': totalAmount,
      });

      ledgerEntries.add({
        'account_id': 'sales_revenue',
        'is_debit': false,
        'amount': totalAmount,
      });

      // 2. Save using Repository
      await _repository.saveJournalEntry(
        templateId: widget.template.templateCode,
        totalAmount: totalAmount,
        ledgerEntries: ledgerEntries,
        description: 'عملية مسجلة من القالب: ${widget.template.ui.displayNameAr}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم الحفظ بنجاح!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.template.ui.displayNameAr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DynamicTemplateForm(
              template: widget.template,
              onDataChanged: (data) {
                _currentData = data;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleSave,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('حفظ العملية'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

