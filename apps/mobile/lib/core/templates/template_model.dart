class TemplateField {
  final String key;
  final String type;
  final String labelAr;
  final bool required;
  final dynamic defaultValue;
  final String? visibleWhen;
  final List<String>? options;

  TemplateField({
    required this.key,
    required this.type,
    required this.labelAr,
    required this.required,
    this.defaultValue,
    this.visibleWhen,
    this.options,
  });

  factory TemplateField.fromJson(Map<String, dynamic> json) {
    return TemplateField(
      key: json['key'] as String,
      type: json['type'] as String,
      labelAr: json['label_ar'] as String,
      required: json['required'] as bool? ?? false,
      defaultValue: json['default'],
      visibleWhen: json['visible_when'] as String?,
      options: (json['options'] as List?)?.map((e) => e.toString()).toList(),
    );
  }
}

class TemplateUI {
  final String buttonGroupAr;
  final String displayNameAr;
  final String descriptionAr;
  final String icon;
  final int sortOrder;

  TemplateUI({
    required this.buttonGroupAr,
    required this.displayNameAr,
    required this.descriptionAr,
    required this.icon,
    required this.sortOrder,
  });

  factory TemplateUI.fromJson(Map<String, dynamic> json) {
    return TemplateUI(
      buttonGroupAr: json['button_group_ar'] as String,
      displayNameAr: json['display_name_ar'] as String,
      descriptionAr: json['description_ar'] as String,
      icon: json['icon'] as String,
      sortOrder: json['sort_order'] as int,
    );
  }
}

class JournalRule {
  final String accountCodeRef;
  final String side;
  final String amountFormula;
  final String? condition;

  JournalRule({
    required this.accountCodeRef,
    required this.side,
    required this.amountFormula,
    this.condition,
  });

  factory JournalRule.fromJson(Map<String, dynamic> json) {
    return JournalRule(
      accountCodeRef: json['account_code_ref'] as String,
      side: json['side'] as String,
      amountFormula: json['amount_formula'] as String,
      condition: json['condition'] as String?,
    );
  }
}

class TransactionTemplate {
  final String templateCode;
  final int templateVersion;
  final String category;
  final TemplateUI ui;
  final List<TemplateField> fields;
  final List<JournalRule> journalRules;
  final List<JournalRule> secondaryJournalRules;

  TransactionTemplate({
    required this.templateCode,
    required this.templateVersion,
    required this.category,
    required this.ui,
    required this.fields,
    this.journalRules = const [],
    this.secondaryJournalRules = const [],
  });

  factory TransactionTemplate.fromJson(Map<String, dynamic> json) {
    var fieldsList = json['fields'] as List? ?? [];
    var jrList = json['journal_rules'] as List? ?? [];
    var sjrList = json['secondary_journal_rules'] as List? ?? [];
    return TransactionTemplate(
      templateCode: json['template_code'] as String,
      templateVersion: json['template_version'] as int,
      category: json['category'] as String,
      ui: TemplateUI.fromJson(json['ui'] as Map<String, dynamic>),
      fields: fieldsList.map((f) => TemplateField.fromJson(f as Map<String, dynamic>)).toList(),
      journalRules: jrList.map((r) => JournalRule.fromJson(r as Map<String, dynamic>)).toList(),
      secondaryJournalRules: sjrList.map((r) => JournalRule.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}
