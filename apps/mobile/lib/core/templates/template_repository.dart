import 'dart:convert';
import 'package:flutter/services.dart';
import 'template_model.dart';

class TemplateRepository {
  final Map<String, TransactionTemplate> _cache = {};

  static const List<String> _directories = [
    '',
    'sales/',
    'purchases/',
    'returns/',
    'expenses/',
    'settlements/',
    'damage/',
    'owner/',
    'opening-balance/',
    'services/',
  ];

  /// Loads a template from assets across all subdirectories and caches it
  Future<TransactionTemplate> loadTemplate(String templateCode) async {
    if (_cache.containsKey(templateCode)) {
      return _cache[templateCode]!;
    }

    String? foundJson;
    for (final dir in _directories) {
      try {
        final path = 'assets/templates/$dir$templateCode.json';
        foundJson = await rootBundle.loadString(path);
        if (foundJson.isNotEmpty) break;
      } catch (_) {
        // Continue searching in next subdirectory
      }
    }

    if (foundJson != null && foundJson.isNotEmpty) {
      final Map<String, dynamic> jsonMap = json.decode(foundJson);
      final template = TransactionTemplate.fromJson(jsonMap);
      _cache[templateCode] = template;
      return template;
    }

    // Fallback template if file not found
    final fallbackTemplate = _createFallbackTemplate(templateCode);
    _cache[templateCode] = fallbackTemplate;
    return fallbackTemplate;
  }

  TransactionTemplate _createFallbackTemplate(String templateCode) {
    return TransactionTemplate(
      templateCode: templateCode,
      templateVersion: 1,
      category: _getCategory(templateCode),
      ui: TemplateUI(
        buttonGroupAr: _getCategory(templateCode),
        displayNameAr: _getArabicName(templateCode),
        descriptionAr: _getArabicDescription(templateCode),
        icon: _getIcon(templateCode),
        sortOrder: 1,
      ),
      fields: [
        TemplateField(
          key: 'amount',
          type: 'amount',
          labelAr: 'المبلغ الإجمالي',
          required: true,
        ),
        TemplateField(
          key: 'contact_id',
          type: 'contact_picker',
          labelAr: 'الطرف (عميل / مورد / موظف)',
          required: false,
        ),
        TemplateField(
          key: 'notes',
          type: 'text',
          labelAr: 'ملاحظات وبيان العملية',
          required: false,
        ),
      ],
      journalRules: const [],
    );
  }

  String _getCategory(String code) {
    if (code.startsWith('sale')) return 'المبيعات';
    if (code.startsWith('purchase')) return 'المشتريات';
    if (code.contains('expense')) return 'المصروفات';
    if (code.contains('damage')) return 'المخازن والتالف';
    if (code.contains('collection') || code.contains('payment')) return 'التحصيل والسداد';
    if (code.contains('owner') || code.contains('opening')) return 'المالك والتسويات';
    return 'العمليات العامة';
  }

  String _getArabicName(String code) {
    switch (code) {
      case 'sale_cash': return 'بيع نقدي';
      case 'sale_credit': return 'بيع آجل';
      case 'sale_partial': return 'بيع جزئي / دفعة';
      case 'sales_return': return 'مرتجع مبيعات';
      case 'purchase_cash': return 'شراء نقدي';
      case 'purchase_credit': return 'شراء آجل';
      case 'purchase_partial': return 'شراء جزئي / دفعة';
      case 'purchase_return': return 'مرتجع مشتريات';
      case 'customer_collection': return 'تحصيل دين من عميل';
      case 'supplier_payment': return 'سداد دفعة لمورد';
      case 'inventory_damage': return 'إتلاف بضاعة هالكة';
      case 'expense_daily': return 'مصروف يومي مباشر';
      case 'expense_period': return 'مصروف دوري (إيجار / موزع)';
      case 'expense_accrued': return 'مصروف مستحق';
      case 'accrued_expense_payment': return 'سداد مصروف مستحق';
      case 'opening_balance_wizard': return 'معالج الرصيد الافتتاحي';
      case 'owner_deposit': return 'إيداع رأس مال للمالك';
      case 'owner_withdrawal': return 'مسحوبات شخصية للمالك';
      case 'job_open': return 'فتح أمر شغل / خدمة';
      case 'service_revenue_cash': return 'أتعاب خدمة نقدية';
      case 'service_revenue_credit': return 'أتعاب خدمة آجلة';
      case 'job_expense_on_behalf': return 'مصروف بالنيابة عن عميل';
      case 'job_expense_recovery': return 'استرداد مصروف بالنيابة';
      default: return 'عملية مالية: $code';
    }
  }

  String _getArabicDescription(String code) {
    switch (code) {
      case 'sale_cash': return 'استلام نقدي فوري في الصندوق مقابل بضاعة';
      case 'sale_credit': return 'بيع على الحساب، صار دين عند العميل';
      case 'sale_partial': return 'استلام دفعة أولى نقدية والباقي دين على العميل';
      case 'sales_return': return 'إرجاع بضاعة من العميل وإعادة النقد أو إنقاص دينه';
      case 'purchase_cash': return 'شراء بضاعة ودفع قيمتها نقداً من الصندوق';
      case 'purchase_credit': return 'شراء بضاعة بالآجل وصار للمورد دين علينا';
      case 'purchase_partial': return 'دفع جزء نقداً للمورد وتسجيل الباقي كدين';
      case 'purchase_return': return 'إرجاع بضاعة للمورد واسترداد المبلغ أو إنقاص حسابه';
      case 'customer_collection': return 'قبض دفعة نقدية أو بنكية من عميل لتخفيض حسابه';
      case 'supplier_payment': return 'سداد دفعة من الدين للمورد نقداً أو بحوالة';
      case 'inventory_damage': return 'إثبات هالك أو منتهي وتوزيعه على المحل أو المورد';
      case 'expense_daily': return 'مصروف تشغيلي يومي (كهرباء، ماء، نظافة، أجور، إلخ)';
      case 'expense_period': return 'مصروف يوزع على فترة (إيجار شهر) لتحديد ربح اليوم بدقة';
      case 'owner_deposit': return 'ضخ أموال في النشاط لحساب رأس المال';
      case 'owner_withdrawal': return 'سحب مبالغ للاستخدام الشخصي للمالك';
      default: return 'تسجيل قيد محاسبي مزدوج ومتوازن للعملية';
    }
  }

  String _getIcon(String code) {
    if (code.startsWith('sale')) return '🛒';
    if (code.startsWith('purchase')) return '💵';
    if (code.contains('collection')) return '📥';
    if (code.contains('payment')) return '📤';
    if (code.contains('damage')) return '🗑️';
    if (code.contains('expense')) return '🧾';
    if (code.contains('owner')) return '💼';
    return '📝';
  }

  void clearCache() {
    _cache.clear();
  }
}
