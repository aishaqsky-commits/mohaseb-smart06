import 'package:flutter/material.dart';
import 'template_model.dart';
import '../widgets/amount_input_pad.dart';

class DynamicTemplateForm extends StatefulWidget {
  final TransactionTemplate template;
  final ValueChanged<Map<String, dynamic>> onDataChanged;

  const DynamicTemplateForm({
    super.key,
    required this.template,
    required this.onDataChanged,
  });

  @override
  State<DynamicTemplateForm> createState() => _DynamicTemplateFormState();
}

class _DynamicTemplateFormState extends State<DynamicTemplateForm> {
  final Map<String, dynamic> _formData = {};

  @override
  void initState() {
    super.initState();
    // Initialize default values
    for (var field in widget.template.fields) {
      if (field.defaultValue != null) {
        _formData[field.key] = field.defaultValue;
      }
    }
    // Defer the initial notification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onDataChanged(Map.unmodifiable(_formData));
    });
  }

  void _updateField(String key, dynamic value) {
    setState(() {
      _formData[key] = value;
    });
    widget.onDataChanged(Map.unmodifiable(_formData));
  }

  Widget _buildField(TemplateField field) {
    switch (field.type) {
      case 'amount':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(field.labelAr, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 8),
              AmountInputPad(
                initialAmount: (_formData[field.key] as num?)?.toDouble() ?? 0.0,
                onChanged: (val) => _updateField(field.key, val),
              ),
            ],
          ),
        );
      case 'text':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: TextFormField(
            initialValue: _formData[field.key]?.toString() ?? '',
            decoration: InputDecoration(
              labelText: field.labelAr,
              border: const OutlineInputBorder(),
            ),
            onChanged: (val) => _updateField(field.key, val),
          ),
        );
      // More field types (contact_picker, date, toggle) will be implemented here
      default:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Text('نوع الحقل غير مدعوم حالياً: ${field.type}'),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.template.ui.displayNameAr,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          widget.template.ui.descriptionAr,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 24),
        ...widget.template.fields.map(_buildField),
      ],
    );
  }
}
