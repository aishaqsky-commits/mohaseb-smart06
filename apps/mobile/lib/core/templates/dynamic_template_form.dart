import 'package:flutter/material.dart';
import 'template_model.dart';
import '../widgets/amount_input_pad.dart';
import 'expression_evaluator.dart';
import '../theme/app_spacing.dart';
import '../theme/color_tokens.dart';

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
    for (var field in widget.template.fields) {
      if (field.defaultValue != null) {
        _formData[field.key] = field.defaultValue;
      } else if (field.type == 'toggle') {
        _formData[field.key] = false;
      }
    }
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
    // Check visibility based on the expression engine
    if (field.visibleWhen != null && field.visibleWhen!.isNotEmpty) {
      final isVisible = ExpressionEvaluatorService.evaluateCondition(
          field.visibleWhen!, _formData);
      if (!isVisible) return const SizedBox.shrink();
    }

    Widget content;
    switch (field.type) {
      case 'amount':
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(field.labelAr, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            AmountInputPad(
              initialAmount: (_formData[field.key] as num?)?.toDouble() ?? 0.0,
              onChanged: (val) => _updateField(field.key, val),
            ),
          ],
        );
        break;
      case 'text':
      case 'date':
      case 'contact_picker':
      case 'item_picker':
      case 'currency_picker':
        content = TextFormField(
          initialValue: _formData[field.key]?.toString() ?? '',
          decoration: InputDecoration(
            labelText: field.labelAr,
            border: const OutlineInputBorder(),
            prefixIcon: field.type == 'date'
                ? const Icon(Icons.calendar_today)
                : field.type == 'contact_picker'
                    ? const Icon(Icons.person)
                    : null,
          ),
          readOnly: field.type == 'date',
          onChanged: (val) => _updateField(field.key, val),
          onTap: field.type == 'date'
              ? () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    _updateField(field.key, date.toIso8601String().split('T')[0]);
                  }
                }
              : null,
        );
        break;
      case 'select':
        content = DropdownButtonFormField<String>(
          initialValue: _formData[field.key]?.toString(),
          decoration: InputDecoration(
            labelText: field.labelAr,
            border: const OutlineInputBorder(),
          ),
          items: (field.options ?? [])
              .map((opt) => DropdownMenuItem(value: opt, child: Text(opt)))
              .toList(),
          onChanged: (val) {
            if (val != null) _updateField(field.key, val);
          },
        );
        break;
      case 'toggle':
        content = SwitchListTile(
          title: Text(field.labelAr),
          value: _formData[field.key] == true,
          onChanged: (val) => _updateField(field.key, val),
          contentPadding: EdgeInsets.zero,
          activeTrackColor: ColorTokens.positive.withValues(alpha: 0.5),
          activeThumbColor: ColorTokens.positive,
        );
        break;
      default:
        content = Text('نوع الحقل غير مدعوم حالياً: ${field.type}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: content,
    );
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
        const SizedBox(height: AppSpacing.xl),
        ...widget.template.fields.map(_buildField),
      ],
    );
  }
}

