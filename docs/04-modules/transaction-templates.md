claude-sonnet-5-high
تصميم تعريفات القوالب (Transaction Templates)
المرحلة 1 — محرك توليد القيود من الأزرار
0. تصحيحات وإضافات ضرورية على المخطط السابق
قبل البدء، ظهرت أثناء التصميم حاجتان جوهريتان كان يجب حسمهما الآن لا لاحقًا:

0.1 تصحيح: علاقة transactions بـ journal_entries
العملية الواحدة (مثل "بيع تفصيلي") قد تُنتج أكثر من قيد مترابط (قيد الإيراد + قيد تكلفة البضاعة المباعة)، وهما غير قابلين للدمج في قيد واحد لأن مبلغيهما مختلفان بطبيعتهما (الإيراد ≠ التكلفة).

التصحيح:

يُحذف الحقل transactions.journal_entry_id (كان خطأ تصميميًا).
العلاقة تبقى من جهة journal_entries.source_transaction_id فقط، بحيث معاملة واحدة ← عدة قيود.
0.2 إضافة جدول jobs (الملفات/الزيارات/أوامر الشغل)
ضروري لتشغيل قوالب الخدمات (عيادة/ورشة/محاماة/مكتب خدمات):

الحقل	النوع	الوصف
id	UUID PK	
tenant_id	UUID FK	
job_type	VARCHAR(20)	visit / work_order / case / service_request
contact_id	UUID FK → contacts	المريض/العميل/الموكل
assigned_employee_id	UUID NULL FK → contacts	الطبيب/الفني المسؤول
title	VARCHAR(150)	وصف مختصر
status	VARCHAR(20)	open / in_progress / closed
opened_at / closed_at	TIMESTAMPTZ	
total_revenue_base_amount	DECIMAL(18,4)	مجمّع تلقائيًا من المعاملات المرتبطة
total_cost_base_amount	DECIMAL(18,4)	مجمّع تلقائيًا
notes	TEXT NULL	
+ الأعمدة القياسية		
jobs كيان غير مالي بذاته — لا يُنشئ قيدًا عند إنشائه، بل يُستخدم كمرجع (job_id) تربط به قوالب الإيراد والمصروف النيابي لاحقًا.

0.3 إضافة جدول template_registry (حوكمة القوالب)
نظير seed_version تمامًا، لإدارة نشر القوالب وتحديثها عن بُعد دون إصدار تطبيق جديد (Remote Config):

الحقل	النوع	الوصف
id	UUID PK	
template_code	VARCHAR(50)	
template_version	SMALLINT	
scope	JSONB	أنواع الأنشطة المطبَّق عليها
category	VARCHAR(30)	
definition_checksum	VARCHAR(64)	SHA-256 لمحتوى ملف القالب لضمان عدم التلاعب
is_active	BOOLEAN	
published_at	TIMESTAMPTZ	
1. العقد الرسمي لتعريف القالب (Meta-Schema)
JSON

{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "TransactionTemplate",
  "type": "object",
  "required": ["template_code", "template_version", "scope", "category", "ui", "fields", "journal_rules"],
  "properties": {
    "template_code": { "type": "string", "pattern": "^[a-z0-9_]+$" },
    "template_version": { "type": "integer", "minimum": 1 },
    "scope": {
      "type": "array",
      "items": { "enum": ["core", "retail", "clinic", "workshop", "law_office", "service_office"] }
    },
    "category": {
      "enum": ["purchases", "sales", "returns", "settlements", "damage", "opening_balance", "expenses", "owner", "services"]
    },
    "ui": {
      "type": "object",
      "required": ["button_group_ar", "display_name_ar", "description_ar", "icon", "sort_order"],
      "properties": {
        "button_group_ar": { "type": "string" },
        "display_name_ar": { "type": "string" },
        "description_ar": { "type": "string" },
        "icon": { "type": "string" },
        "sort_order": { "type": "integer" }
      }
    },
    "payment_mode": { "enum": ["cash", "credit", "partial", null] },
    "requires_contact": {
      "type": "object",
      "properties": {
        "required": { "type": "boolean" },
        "type": { "enum": ["customer", "supplier", "employee", "other", null] },
        "allow_quick_add": { "type": "boolean" }
      }
    },
    "inventory_effect": { "enum": ["none", "increase", "decrease"] },
    "allow_quick_mode": { "type": "boolean", "default": false },
    "allow_distribution": { "type": "boolean", "default": false },
    "is_system_generated": { "type": "boolean", "default": false },
    "one_time_only": { "type": "boolean", "default": false },
    "fields": { "type": "array", "items": { "$ref": "#/definitions/field" } },
    "journal_rules": { "type": "array", "items": { "$ref": "#/definitions/journalLineRule" } },
    "secondary_journal_rules": { "type": ["array", "null"], "items": { "$ref": "#/definitions/journalLineRule" } },
    "post_actions": { "type": "array", "items": { "type": "string" } },
    "golden_test_cases": { "type": "array" }
  },
  "definitions": {
    "field": {
      "type": "object",
      "required": ["key", "type", "label_ar", "required"],
      "properties": {
        "key": { "type": "string" },
        "type": {
          "enum": ["amount", "date", "number", "text", "contact_picker", "item_picker",
                   "distribution_table", "select", "currency_picker", "toggle"]
        },
        "label_ar": { "type": "string" },
        "required": { "type": "boolean" },
        "default": {},
        "options": { "type": ["array", "null"] },
        "options_source": { "type": ["string", "null"] },
        "visible_when": { "type": ["string", "null"] },
        "validation": { "type": ["string", "null"] }
      }
    },
    "journalLineRule": {
      "type": "object",
      "required": ["account_code_ref", "side", "amount_formula"],
      "properties": {
        "account_code_ref": { "type": "string" },
        "side": { "enum": ["debit", "credit"] },
        "amount_formula": { "type": "string" },
        "currency_ref": { "type": "string", "default": "{{currency_code}}" },
        "contact_ref": { "type": ["string", "null"] },
        "condition": { "type": ["string", "null"] },
        "memo_ar": { "type": ["string", "null"] },
        "repeat_for": { "type": ["string", "null"] }
      }
    }
  }
}
2. كتالوج أنواع الحقول (UI Field Types)
النوع	الاستخدام	ملاحظات تنفيذية
amount	مبلغ مالي	يعرض لوحة أرقام كبيرة، يدعم فواصل الآلاف
date	تاريخ	افتراضي "اليوم"، يدعم التقويم الهجري اختياريًا
number	عدد صحيح	لعدد الأيام مثلًا
text	نص حر	للبيان/الملاحظات
contact_picker	اختيار طرف	بحث فوري + إضافة سريعة inline إن allow_quick_add=true
item_picker	اختيار صنف/أصناف وكميات	يُستخدم في الوضع التفصيلي فقط
distribution_table	جدول توزيع مرن	يُستخدم في التالف والرصيد الافتتاحي
select	قائمة اختيار	تُغذّى بقيم ثابتة أو options_source ديناميكي
currency_picker	اختيار عملة	من tenant_currencies المفعّلة فقط
toggle	مفتاح تشغيل/إيقاف	مثل "وضع سريع/تفصيلي"
3. لغة الصيغ الحسابية (Expression Language)
لغة صغيرة آمنة (Safe DSL) وليست تنفيذ كود حر، لمنع أي ثغرة حقن. تُفسَّر عبر مفسّر محدود مسبقًا بقائمة دوال مغلقة.

3.1 المتغيرات
الصيغة	المعنى
{{field_key}}	قيمة حقل أدخله المستخدم
{{tenant.base_currency}}	عملة المستأجر الأساسية
{{job.contact_id}}	قراءة حقل من سجل jobs المرتبط
{{distribution[i].amount}}	عنصر ضمن حلقة repeat_for
3.2 الدوال المدمجة (Whitelisted Functions)
الدالة	الوصف
remaining(total, paid)	total - paid
plug_balance()	يحسب الفرق الموازن تلقائيًا (رصيد افتتاحي)
total_or_items_sum()	المبلغ المباشر أو مجموع الأصناف حسب الوضع
cogs_amount()	يستدعي محرك تقييم المخزون (متوسط مرجّح) لحساب تكلفة المبيعات
items_cost_sum(items)	مجموع تكلفة الأصناف المحددة
sum(array.field)	مجموع عمود في جدول توزيع
map_target_to_account(target_type)	يحوّل نوع جهة التالف إلى كود حساب
apportion(total, percentage)	يحسب حصة من مبلغ حسب نسبة مئوية
3.3 قاعدة التقريب الإلزامية (Rounding Rule)
مشكلة حقيقية يجب حلها هندسيًا: توزيع 1000 على 3 أطراف بنسب متساوية (33.33%) ينتج 333.3+333.3+333.3 = 999.9 وليس 1000، فيختل توازن القيد.

الحل المعتمد: يُحسب كل سطر بالتقريب العادي عدا السطر الأخير في أي repeat_for، الذي يُحسب كـ:

text

last_line_amount = total_amount - sum(all_previous_lines_amounts)
هذا يضمن توازنًا رياضيًا مضبوطًا 100% دون أي استثناء، ويُطبَّق كقاعدة صارمة في محرك التنفيذ لا كخيار.

4. محرك تنفيذ القوالب (Execution Engine)
text

function executeTemplate(template_code, payload, context):
    template = resolveTemplate(template_code, context.tenant.business_type)   // من template_registry المحلي

    // 1) تحقق من صحة المدخلات
    validateFieldsAgainstSchema(payload, template.fields)
    validateBusinessRules(payload, template)   // مثل paid_amount <= total_amount

    // 2) بناء بنود القيد الأساسي
    primary_lines = buildJournalLines(template.journal_rules, payload, context)
    applyLastLineRoundingRule(primary_lines)
    assertBalanced(primary_lines)              // خط دفاع 1 (محلي قبل الإرسال)

    // 3) إنشاء المعاملة محليًا أولًا (Local-first)
    transaction = insertLocalTransaction(template_code, template.template_version, payload)

    // 4) ترحيل القيد الأساسي
    primary_entry = insertLocalJournalEntry(primary_lines, transaction.id)

    // 5) القيد الثانوي إن وُجد (مثل تكلفة البضاعة المباعة)
    if template.secondary_journal_rules and conditionsMet(payload):
        secondary_lines = buildJournalLines(template.secondary_journal_rules, payload, context)
        applyLastLineRoundingRule(secondary_lines)
        assertBalanced(secondary_lines)
        insertLocalJournalEntry(secondary_lines, transaction.id)

    // 6) تنفيذ الإجراءات اللاحقة
    runPostActions(template.post_actions, transaction, context)

    // 7) توليد الملخص المبسّط للعرض الفوري (قسم 8)
    simple_summary = renderSimpleSummary(template, primary_lines, payload)

    // 8) جدولة للمزامنة (غير معطّلة للواجهة)
    enqueueForSync(transaction, primary_entry)

    return { transaction, simple_summary }
ملاحظات حرجة للتنفيذ:

الخطوة (2) تُنفَّذ محليًا بالكامل دون اتصال.
assertBalanced يُنفَّذ مرتين: هنا (تطبيق) وعلى الخادم عند المزامنة (طبقة دفاع ثانية كما في تصميم journal_lines).
لا يُعرض القيد الفني للمستخدم افتراضيًا، بل simple_summary فقط.
5. معالجة التالف والتوزيع المرن (تفصيل منطقي)
target_type	الحساب المستهدف (map_target_to_account)	الأثر
shop_loss	5701 (تالف ومنتهي الصلاحية)	خسارة يتحملها المحل
supplier	2110 (الموردون) — مدين	يخفّض دين المورد القائم (تعويض)
other_receivable	1230 (ذمم مدينة أخرى)	يُحمَّل على جهة أخرى (موظف مثلًا)
قاعدة تحقق إلزامية: SUM(distribution[].percentage) == 100 قبل أي ترحيل، وإلا يُرفض الحفظ برسالة بسيطة: "مجموع التوزيع لازم يكون 100%".

6. معالجة فروق العملة ضمن القوالب (Hook مستقبلي معرَّف الآن)
القوالب التي تتعامل مع تحصيل/سداد بعملة مختلفة عن عملة القيد الأصلي (supplier_payment, customer_collection) تحمل post_action: "apply_fx_gain_loss_if_needed":

text

function apply_fx_gain_loss_if_needed(transaction, context):
    settled_base_amount = amount_entered * exchange_rate_today
    original_base_amount = outstanding_balance_portion_being_settled   // بعملة الأساس وقت نشوء الدين
    diff = settled_base_amount - original_base_amount

    if diff != 0:
        account = diff > 0 ? "4900" : "5900"   // أرباح أو خسائر فروق عملة
        appendBalancingLine(transaction.primary_entry, account, abs(diff))
توصية: هذا المنطق يُجمَّد تفصيليًا عند بناء وحدة الذمم (AR/AP) الكاملة، لكن نقطة الربط (post_actions) يجب أن تكون موجودة في عقد القالب من الآن، تفاديًا لإعادة تصميم القوالب لاحقًا.

7. الكتالوج الرئيسي للقوالب (ملخص مرجعي)
الكود	الفئة	الزر	النمط	يؤثر على المخزون	يتطلب طرف
purchase_cash	مشتريات	اشتريت - نقدًا	cash	زيادة	لا
purchase_credit	مشتريات	اشتريت - أجل	credit	زيادة	نعم (مورد)
purchase_partial	مشتريات	اشتريت - جزئي	partial	زيادة	نعم (مورد)
sale_cash	مبيعات	بعت - نقدًا	cash	نقصان (اختياري)	لا
sale_credit	مبيعات	بعت - أجل	credit	نقصان (اختياري)	نعم (عميل)
sale_partial	مبيعات	بعت - جزئي	partial	نقصان (اختياري)	نعم (عميل)
sales_return	مرتجعات	مرتجع من عميل	—	زيادة	اختياري
purchase_return	مرتجعات	مرتجع للمورد	—	نقصان	اختياري
supplier_payment	سداد/تحصيل	سداد للمورد	—	—	نعم (مورد)
customer_collection	سداد/تحصيل	تحصيل من عميل	—	—	نعم (عميل)
inventory_damage	تالف	بضاعة تالفة	—	نقصان	اختياري (توزيع)
opening_balance_wizard	رصيد افتتاحي	رصيد افتتاحي	—	زيادة (إن وُجد)	اختياري
expense_daily	مصروفات	مصروف يومي	—	—	لا
expense_period	مصروفات	مصروف لفترة	—	—	لا
expense_accrued / accrued_expense_payment	مصروفات	مصروف مستحق	—	—	لا
owner_withdrawal	مالك	مسحوبات المالك	—	—	لا
owner_deposit	مالك	إيداع المالك	—	—	لا
job_open	خدمات	فتح ملف/زيارة (غير مالي)	—	—	نعم
service_revenue_cash / _credit	خدمات	تحصيل أتعاب/كشف	cash/credit	—	اختياري/نعم
job_expense_on_behalf	خدمات	مصروف نيابة عن العميل	—	—	عبر job
job_expense_recovery	خدمات	تحصيل مبلغ النيابة	—	—	عبر job
commission_expense	خدمات	عمولة طبيب/فني	—	—	لا
8. ملفات القوالب التفصيلية
8.1 المشتريات
JSON

{
  "template_code": "purchase_cash",
  "template_version": 1,
  "scope": ["retail", "clinic", "workshop", "service_office"],
  "category": "purchases",
  "ui": { "button_group_ar": "اشتريت", "display_name_ar": "شراء نقدًا", "icon": "cart_download",
          "description_ar": "اشتريت بضاعة أو مستلزمات ودفعت الفلوس كاش", "sort_order": 1 },
  "payment_mode": "cash",
  "requires_contact": { "required": false, "type": "supplier" },
  "inventory_effect": "increase",
  "allow_quick_mode": true,
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true, "default": "{{tenant.base_currency}}" },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "supplier_id", "type": "contact_picker", "label_ar": "المورد (اختياري)", "required": false },
    { "key": "note", "type": "text", "label_ar": "ملاحظة", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "1310", "side": "debit", "amount_formula": "{{total_amount}}", "memo_ar": "بضاعة مشتراة" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{total_amount}}", "memo_ar": "دفعت كاش" }
  ],
  "golden_test_cases": [
    { "payload": { "total_amount": 50000, "currency_code": "YER", "paid_from_account": "1101" },
      "expected_balanced": true, "expected_debit_total": 50000, "expected_credit_total": 50000 }
  ]
}
JSON

{
  "template_code": "purchase_credit",
  "template_version": 1,
  "scope": ["retail", "clinic", "workshop", "service_office"],
  "category": "purchases",
  "ui": { "button_group_ar": "اشتريت", "display_name_ar": "شراء آجل", "icon": "cart_clock",
          "description_ar": "اشتريت بضاعة وما دفعت، صارت دين عليك للمورد", "sort_order": 2 },
  "payment_mode": "credit",
  "requires_contact": { "required": true, "type": "supplier", "allow_quick_add": true },
  "inventory_effect": "increase",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "supplier_id", "type": "contact_picker", "label_ar": "المورد", "required": true },
    { "key": "due_date", "type": "date", "label_ar": "تاريخ السداد المتوقع", "required": false },
    { "key": "note", "type": "text", "label_ar": "ملاحظة", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "1310", "side": "debit", "amount_formula": "{{total_amount}}" },
    { "account_code_ref": "2110", "side": "credit", "amount_formula": "{{total_amount}}", "contact_ref": "{{supplier_id}}" }
  ]
}
JSON

{
  "template_code": "purchase_partial",
  "template_version": 1,
  "scope": ["retail", "clinic", "workshop", "service_office"],
  "category": "purchases",
  "ui": { "button_group_ar": "اشتريت", "display_name_ar": "شراء جزئي", "icon": "cart_split",
          "description_ar": "دفعت جزء والباقي صار دين على المورد", "sort_order": 3 },
  "payment_mode": "partial",
  "requires_contact": { "required": true, "type": "supplier", "allow_quick_add": true },
  "inventory_effect": "increase",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ الكلي", "required": true },
    { "key": "paid_amount", "type": "amount", "label_ar": "دفعت الآن كم؟", "required": true, "validation": "paid_amount <= total_amount" },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "supplier_id", "type": "contact_picker", "label_ar": "المورد", "required": true }
  ],
  "journal_rules": [
    { "account_code_ref": "1310", "side": "debit", "amount_formula": "{{total_amount}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{paid_amount}}" },
    { "account_code_ref": "2110", "side": "credit", "amount_formula": "remaining({{total_amount}},{{paid_amount}})", "contact_ref": "{{supplier_id}}" }
  ]
}
8.2 المبيعات (مع القيد الثانوي لتكلفة البضاعة)
JSON

{
  "template_code": "sale_cash",
  "template_version": 1,
  "scope": ["retail", "workshop"],
  "category": "sales",
  "ui": { "button_group_ar": "بعت", "display_name_ar": "بيع نقدًا", "icon": "cash_register",
          "description_ar": "بعت وقبضت الفلوس كاش", "sort_order": 1 },
  "payment_mode": "cash",
  "requires_contact": { "required": false, "type": "customer" },
  "inventory_effect": "decrease",
  "allow_quick_mode": true,
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "inventory_mode", "type": "toggle", "label_ar": "وضع تفصيلي بالأصناف؟", "required": true, "default": false },
    { "key": "items", "type": "item_picker", "label_ar": "الأصناف", "required": false, "visible_when": "inventory_mode == true" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ", "required": true, "visible_when": "inventory_mode == false" },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "received_to_account", "type": "select", "label_ar": "استلمت الفلوس في؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل (اختياري)", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "{{received_to_account}}", "side": "debit", "amount_formula": "total_or_items_sum()" },
    { "account_code_ref": "4150", "side": "credit", "amount_formula": "total_or_items_sum()" }
  ],
  "secondary_journal_rules": [
    { "account_code_ref": "5110", "side": "debit", "amount_formula": "cogs_amount()", "condition": "inventory_mode == true" },
    { "account_code_ref": "1310", "side": "credit", "amount_formula": "cogs_amount()", "condition": "inventory_mode == true" }
  ]
}
JSON

{
  "template_code": "sale_credit",
  "template_version": 1,
  "scope": ["retail", "workshop"],
  "category": "sales",
  "ui": { "button_group_ar": "بعت", "display_name_ar": "بيع آجل", "icon": "cart_clock",
          "description_ar": "بعت وما قبضت، صار لك دين عند العميل", "sort_order": 2 },
  "payment_mode": "credit",
  "requires_contact": { "required": true, "type": "customer", "allow_quick_add": true },
  "inventory_effect": "decrease",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "inventory_mode", "type": "toggle", "label_ar": "وضع تفصيلي بالأصناف؟", "required": true, "default": false },
    { "key": "items", "type": "item_picker", "label_ar": "الأصناف", "required": false, "visible_when": "inventory_mode == true" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ", "required": true, "visible_when": "inventory_mode == false" },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل", "required": true }
  ],
  "journal_rules": [
    { "account_code_ref": "1210", "side": "debit", "amount_formula": "total_or_items_sum()", "contact_ref": "{{customer_id}}" },
    { "account_code_ref": "4150", "side": "credit", "amount_formula": "total_or_items_sum()" }
  ],
  "secondary_journal_rules": [
    { "account_code_ref": "5110", "side": "debit", "amount_formula": "cogs_amount()", "condition": "inventory_mode == true" },
    { "account_code_ref": "1310", "side": "credit", "amount_formula": "cogs_amount()", "condition": "inventory_mode == true" }
  ]
}
JSON

{
  "template_code": "sale_partial",
  "template_version": 1,
  "scope": ["retail", "workshop"],
  "category": "sales",
  "ui": { "button_group_ar": "بعت", "display_name_ar": "بيع جزئي", "icon": "cart_split",
          "description_ar": "قبضت جزء والباقي صار دين على العميل", "sort_order": 3 },
  "payment_mode": "partial",
  "requires_contact": { "required": true, "type": "customer", "allow_quick_add": true },
  "inventory_effect": "decrease",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ الكلي", "required": true },
    { "key": "received_amount", "type": "amount", "label_ar": "قبضت الآن كم؟", "required": true, "validation": "received_amount <= total_amount" },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "received_to_account", "type": "select", "label_ar": "استلمت في؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل", "required": true }
  ],
  "journal_rules": [
    { "account_code_ref": "{{received_to_account}}", "side": "debit", "amount_formula": "{{received_amount}}" },
    { "account_code_ref": "1210", "side": "debit", "amount_formula": "remaining({{total_amount}},{{received_amount}})", "contact_ref": "{{customer_id}}" },
    { "account_code_ref": "4150", "side": "credit", "amount_formula": "{{total_amount}}" }
  ]
}
8.3 المرتجعات
JSON

{
  "template_code": "sales_return",
  "template_version": 1,
  "scope": ["retail", "workshop"],
  "category": "returns",
  "ui": { "button_group_ar": "مرتجعات", "display_name_ar": "مرتجع من عميل", "icon": "undo",
          "description_ar": "العميل رجّع بضاعة كان اشتراها", "sort_order": 1 },
  "requires_contact": { "required": false, "type": "customer" },
  "inventory_effect": "increase",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "original_sale_ref", "type": "select", "label_ar": "الفاتورة الأصلية (اختياري)", "required": false, "options_source": "recent_sales({{customer_id}})" },
    { "key": "amount", "type": "amount", "label_ar": "قيمة المرتجع", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "refund_method", "type": "select", "label_ar": "كيف ترجع الفلوس؟", "required": true, "options": ["cash", "customer_balance"] },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "4200", "side": "debit", "amount_formula": "{{amount}}", "memo_ar": "مردودات مبيعات" },
    { "account_code_ref": "1101", "side": "credit", "amount_formula": "{{amount}}", "condition": "refund_method == 'cash'" },
    { "account_code_ref": "1210", "side": "credit", "amount_formula": "{{amount}}", "contact_ref": "{{customer_id}}", "condition": "refund_method == 'customer_balance'" }
  ],
  "secondary_journal_rules": [
    { "account_code_ref": "1310", "side": "debit", "amount_formula": "cogs_amount()", "condition": "original_sale_ref != null" },
    { "account_code_ref": "5110", "side": "credit", "amount_formula": "cogs_amount()", "condition": "original_sale_ref != null" }
  ]
}
JSON

{
  "template_code": "purchase_return",
  "template_version": 1,
  "scope": ["retail", "clinic", "workshop", "service_office"],
  "category": "returns",
  "ui": { "button_group_ar": "مرتجعات", "display_name_ar": "مرتجع للمورد", "icon": "undo",
          "description_ar": "رجّعت بضاعة كنت اشتريتها للمورد", "sort_order": 2 },
  "requires_contact": { "required": false, "type": "supplier" },
  "inventory_effect": "decrease",
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "amount", "type": "amount", "label_ar": "قيمة المرتجع", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "refund_method", "type": "select", "label_ar": "كيف استرجعت الفلوس؟", "required": true, "options": ["cash", "supplier_balance"] },
    { "key": "supplier_id", "type": "contact_picker", "label_ar": "المورد", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "1101", "side": "debit", "amount_formula": "{{amount}}", "condition": "refund_method == 'cash'" },
    { "account_code_ref": "2110", "side": "debit", "amount_formula": "{{amount}}", "contact_ref": "{{supplier_id}}", "condition": "refund_method == 'supplier_balance'" },
    { "account_code_ref": "1310", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
8.4 السداد والتحصيل
JSON

{
  "template_code": "customer_collection",
  "template_version": 1,
  "scope": ["core"],
  "category": "settlements",
  "ui": { "button_group_ar": "تحصيل من عميل", "display_name_ar": "تحصيل دين من عميل", "icon": "payment_receive",
          "description_ar": "قبضت فلوس من عميل كان له دين عندك", "sort_order": 1 },
  "requires_contact": { "required": true, "type": "customer" },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل", "required": true },
    { "key": "invoice_ref", "type": "select", "label_ar": "على فاتورة معينة؟ (اختياري)", "required": false, "options_source": "open_customer_invoices({{customer_id}})" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "received_to_account", "type": "select", "label_ar": "استلمت في؟", "required": true, "options": ["1101", "1110", "1120"] }
  ],
  "journal_rules": [
    { "account_code_ref": "{{received_to_account}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "1210", "side": "credit", "amount_formula": "{{amount}}", "contact_ref": "{{customer_id}}" }
  ],
  "post_actions": ["apply_fx_gain_loss_if_needed", "allocate_to_invoice({{invoice_ref}})"]
}
JSON

{
  "template_code": "supplier_payment",
  "template_version": 1,
  "scope": ["core"],
  "category": "settlements",
  "ui": { "button_group_ar": "سداد للمورد", "display_name_ar": "سداد دين لمورد", "icon": "payment_send",
          "description_ar": "دفعت فلوس لمورد كان له دين عندك", "sort_order": 2 },
  "requires_contact": { "required": true, "type": "supplier" },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "supplier_id", "type": "contact_picker", "label_ar": "المورد", "required": true },
    { "key": "invoice_ref", "type": "select", "label_ar": "على فاتورة معينة؟ (اختياري)", "required": false, "options_source": "open_supplier_invoices({{supplier_id}})" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] }
  ],
  "journal_rules": [
    { "account_code_ref": "2110", "side": "debit", "amount_formula": "{{amount}}", "contact_ref": "{{supplier_id}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ],
  "post_actions": ["apply_fx_gain_loss_if_needed", "allocate_to_invoice({{invoice_ref}})"]
}
8.5 التالف
JSON

{
  "template_code": "inventory_damage",
  "template_version": 1,
  "scope": ["retail", "workshop", "clinic", "service_office"],
  "category": "damage",
  "ui": { "button_group_ar": "تالف", "display_name_ar": "بضاعة تالفة", "icon": "broken_box",
          "description_ar": "سجّل بضاعة تلفت أو انتهت صلاحيتها ووزّع قيمتها", "sort_order": 1 },
  "requires_contact": { "required": false, "type": null },
  "inventory_effect": "decrease",
  "allow_distribution": true,
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "items", "type": "item_picker", "label_ar": "الأصناف التالفة", "required": true },
    { "key": "total_amount", "type": "amount", "label_ar": "القيمة الإجمالية", "required": true },
    { "key": "reason", "type": "select", "label_ar": "السبب", "required": true,
      "options": ["expired", "broken", "theft", "sample_gift", "other"] },
    { "key": "distribution", "type": "distribution_table", "label_ar": "على من توزّع الخسارة؟", "required": true,
      "validation": "sum(distribution[].percentage) == 100" }
  ],
  "journal_rules": [
    { "account_code_ref": "map_target_to_account({{distribution[i].target_type}})", "side": "debit",
      "amount_formula": "apportion({{total_amount}}, {{distribution[i].percentage}})",
      "contact_ref": "{{distribution[i].contact_id}}", "repeat_for": "distribution" },
    { "account_code_ref": "1310", "side": "credit", "amount_formula": "{{total_amount}}" }
  ]
}
8.6 الرصيد الافتتاحي (معالج مركّب)
JSON

{
  "template_code": "opening_balance_wizard",
  "template_version": 1,
  "scope": ["core"],
  "category": "opening_balance",
  "ui": { "button_group_ar": "رصيد افتتاحي", "display_name_ar": "تسجيل الأرصدة الافتتاحية", "icon": "flag_start",
          "description_ar": "سجّل كل أرصدتك وبضاعتك وديونك قبل بدء الاستخدام - مرة واحدة فقط", "sort_order": 1 },
  "one_time_only": true,
  "fields": [
    { "key": "as_of_date", "type": "date", "label_ar": "تاريخ البداية", "required": true },
    { "key": "cash_balance", "type": "amount", "label_ar": "فلوس الصندوق", "required": false, "default": 0 },
    { "key": "bank_balance", "type": "amount", "label_ar": "رصيد البنك", "required": false, "default": 0 },
    { "key": "inventory_value", "type": "amount", "label_ar": "قيمة البضاعة الحالية", "required": false, "default": 0 },
    { "key": "fixed_assets_value", "type": "amount", "label_ar": "قيمة الأصول الثابتة", "required": false, "default": 0 },
    { "key": "customers", "type": "distribution_table", "label_ar": "عملاء لهم دين عندك", "required": false },
    { "key": "suppliers", "type": "distribution_table", "label_ar": "موردون لهم دين عندهم", "required": false },
    { "key": "loans_payable", "type": "amount", "label_ar": "قروض عليك", "required": false, "default": 0 }
  ],
  "journal_rules": [
    { "account_code_ref": "1101", "side": "debit", "amount_formula": "{{cash_balance}}", "condition": "cash_balance > 0" },
    { "account_code_ref": "1110", "side": "debit", "amount_formula": "{{bank_balance}}", "condition": "bank_balance > 0" },
    { "account_code_ref": "1310", "side": "debit", "amount_formula": "{{inventory_value}}", "condition": "inventory_value > 0" },
    { "account_code_ref": "1510", "side": "debit", "amount_formula": "{{fixed_assets_value}}", "condition": "fixed_assets_value > 0" },
    { "account_code_ref": "1210", "side": "debit", "amount_formula": "{{customers[i].amount}}", "contact_ref": "{{customers[i].contact_id}}", "repeat_for": "customers" },
    { "account_code_ref": "2110", "side": "credit", "amount_formula": "{{suppliers[i].amount}}", "contact_ref": "{{suppliers[i].contact_id}}", "repeat_for": "suppliers" },
    { "account_code_ref": "2210", "side": "credit", "amount_formula": "{{loans_payable}}", "condition": "loans_payable > 0" },
    { "account_code_ref": "3100", "side": "credit", "amount_formula": "plug_balance()", "memo_ar": "رأس المال (محسوب تلقائيًا)" }
  ],
  "post_actions": ["lock_template_after_first_use"]
}
8.7 المصروفات
JSON

{
  "template_code": "expense_daily",
  "template_version": 1,
  "scope": ["core"],
  "category": "expenses",
  "ui": { "button_group_ar": "مصروفات", "display_name_ar": "مصروف يومي", "icon": "receipt",
          "description_ar": "مصروف يخص اليوم بس", "sort_order": 1 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "expense_category", "type": "select", "label_ar": "نوع المصروف", "required": true,
      "options": [
        { "value": "5201", "label_ar": "أجور وراتب" },
        { "value": "5401", "label_ar": "كهرباء ومياه" },
        { "value": "5501", "label_ar": "نظافة" },
        { "value": "5601", "label_ar": "دعاية" },
        { "value": "5801", "label_ar": "أخرى" }
      ] },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "note", "type": "text", "label_ar": "بيان", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "{{expense_category}}", "side": "debit", "amount_formula": "{{amount}}", "memo_ar": "{{note}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
JSON

{
  "template_code": "expense_period",
  "template_version": 1,
  "scope": ["core"],
  "category": "expenses",
  "ui": { "button_group_ar": "مصروفات", "display_name_ar": "مصروف لفترة (موزّع)", "icon": "calendar_split",
          "description_ar": "مثل إيجار الشهر - يتوزع تلقائيًا على كل يوم", "sort_order": 2 },
  "fields": [
    { "key": "start_date", "type": "date", "label_ar": "تاريخ البداية", "required": true },
    { "key": "number_of_days", "type": "number", "label_ar": "عدد الأيام", "required": true },
    { "key": "expense_category", "type": "select", "label_ar": "نوع المصروف", "required": true, "options": ["5301", "5601", "5801"] },
    { "key": "total_amount", "type": "amount", "label_ar": "المبلغ الكلي", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] }
  ],
  "journal_rules": [
    { "account_code_ref": "1410", "side": "debit", "amount_formula": "{{total_amount}}", "memo_ar": "دفعة مقدمة تُستهلك يوميًا" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{total_amount}}" }
  ],
  "post_actions": ["create_amortization_schedule"]
}
JSON

{
  "template_code": "system_daily_amortization",
  "template_version": 1,
  "scope": ["core"],
  "category": "expenses",
  "is_system_generated": true,
  "ui": { "button_group_ar": null, "display_name_ar": "استهلاك يومي تلقائي", "icon": "clock",
          "description_ar": "توليد تلقائي من محرك التطبيق - لا يظهر للمستخدم", "sort_order": 99 },
  "fields": [],
  "journal_rules": [
    { "account_code_ref": "{{expense_category}}", "side": "debit", "amount_formula": "{{daily_share_amount}}" },
    { "account_code_ref": "1410", "side": "credit", "amount_formula": "{{daily_share_amount}}" }
  ]
}
تشغيل system_daily_amortization: عند فتح التطبيق يوميًا (أو عبر Job مجدول محليًا)، يفحص المحرك كل سجلات expense_period غير المكتملة الاستهلاك، ويُنشئ قيد اليوم الناقص تلقائيًا إن لم يكن موجودًا (Idempotent بمفتاح (schedule_id, date)).

JSON

{
  "template_code": "expense_accrued",
  "template_version": 1,
  "scope": ["core"],
  "category": "expenses",
  "ui": { "button_group_ar": "مصروفات", "display_name_ar": "مصروف مستحق (لم يُدفع)", "icon": "receipt_long",
          "description_ar": "مصروف استحق عليك ولسه ما دفعته (مثل راتب آخر الشهر)", "sort_order": 3 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "expense_category", "type": "select", "label_ar": "نوع المصروف", "required": true, "options": ["5201", "5801"] },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "employee_id", "type": "contact_picker", "label_ar": "الموظف (إن وُجد)", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "{{expense_category}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "2310", "side": "credit", "amount_formula": "{{amount}}", "contact_ref": "{{employee_id}}" }
  ]
}
JSON

{
  "template_code": "accrued_expense_payment",
  "template_version": 1,
  "scope": ["core"],
  "category": "expenses",
  "ui": { "button_group_ar": "مصروفات", "display_name_ar": "سداد مصروف مستحق", "icon": "payment_send",
          "description_ar": "دفعت مصروف كان مسجل عليك من قبل", "sort_order": 4 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "employee_id", "type": "contact_picker", "label_ar": "الموظف (إن وُجد)", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "2310", "side": "debit", "amount_formula": "{{amount}}", "contact_ref": "{{employee_id}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
8.8 مسحوبات وإيداعات المالك
JSON

{
  "template_code": "owner_withdrawal",
  "template_version": 1,
  "scope": ["core"],
  "category": "owner",
  "ui": { "button_group_ar": "المالك", "display_name_ar": "مسحوبات المالك", "icon": "wallet_out",
          "description_ar": "سحبت فلوس من المحل لنفسك", "sort_order": 1 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "من وين سحبت؟", "required": true, "options": ["1101", "1110"] }
  ],
  "journal_rules": [
    { "account_code_ref": "3200", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
JSON

{
  "template_code": "owner_deposit",
  "template_version": 1,
  "scope": ["core"],
  "category": "owner",
  "ui": { "button_group_ar": "المالك", "display_name_ar": "إيداع المالك", "icon": "wallet_in",
          "description_ar": "حطيت فلوس من جيبك في المحل", "sort_order": 2 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "deposit_to_account", "type": "select", "label_ar": "حطيتها وين؟", "required": true, "options": ["1101", "1110"] }
  ],
  "journal_rules": [
    { "account_code_ref": "{{deposit_to_account}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "3100", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
8.9 قوالب الخدمات (عيادة / ورشة / محاماة / مكتب خدمات)
JSON

{
  "template_code": "job_open",
  "template_version": 1,
  "scope": ["clinic", "workshop", "law_office", "service_office"],
  "category": "services",
  "ui": { "button_group_ar": "فتح ملف", "display_name_ar": "فتح ملف/زيارة جديدة", "icon": "folder_add",
          "description_ar": "سجّل مريض جديد أو أمر صيانة أو قضية أو معاملة", "sort_order": 1 },
  "is_financial": false,
  "requires_contact": { "required": true, "type": "customer", "allow_quick_add": true },
  "fields": [
    { "key": "job_type", "type": "select", "label_ar": "نوع الملف", "required": true,
      "options": ["visit", "work_order", "case", "service_request"] },
    { "key": "contact_id", "type": "contact_picker", "label_ar": "المريض/العميل/الموكل", "required": true },
    { "key": "assigned_employee_id", "type": "contact_picker", "label_ar": "الطبيب/الفني المسؤول", "required": false },
    { "key": "title", "type": "text", "label_ar": "وصف مختصر", "required": false }
  ],
  "entity_action": "create_job_record"
}
JSON

{
  "template_code": "service_revenue_cash",
  "template_version": 1,
  "scope": ["clinic", "workshop", "law_office", "service_office"],
  "category": "services",
  "ui": { "button_group_ar": "تحصيل أتعاب", "display_name_ar": "تحصيل نقدًا", "icon": "cash_register",
          "description_ar": "قبضت قيمة الخدمة كاش", "sort_order": 2 },
  "payment_mode": "cash",
  "requires_contact": { "required": false, "type": "customer" },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "job_id", "type": "select", "label_ar": "مرتبط بملف؟ (اختياري)", "required": false, "options_source": "open_jobs()" },
    { "key": "revenue_account", "type": "select", "label_ar": "نوع الإيراد", "required": true,
      "options_source": "revenue_accounts_for_scope()" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "received_to_account", "type": "select", "label_ar": "استلمت في؟", "required": true, "options": ["1101", "1110", "1120"] },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل/المريض/الموكل", "required": false }
  ],
  "journal_rules": [
    { "account_code_ref": "{{received_to_account}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "{{revenue_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
JSON

{
  "template_code": "service_revenue_credit",
  "template_version": 1,
  "scope": ["clinic", "workshop", "law_office", "service_office"],
  "category": "services",
  "ui": { "button_group_ar": "تحصيل أتعاب", "display_name_ar": "أتعاب آجلة", "icon": "cart_clock",
          "description_ar": "سجّل الأتعاب على ذمة العميل", "sort_order": 3 },
  "payment_mode": "credit",
  "requires_contact": { "required": true, "type": "customer", "allow_quick_add": true },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "job_id", "type": "select", "label_ar": "مرتبط بملف؟", "required": false, "options_source": "open_jobs()" },
    { "key": "revenue_account", "type": "select", "label_ar": "نوع الإيراد", "required": true, "options_source": "revenue_accounts_for_scope()" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "customer_id", "type": "contact_picker", "label_ar": "العميل/الموكل", "required": true }
  ],
  "journal_rules": [
    { "account_code_ref": "1210", "side": "debit", "amount_formula": "{{amount}}", "contact_ref": "{{customer_id}}" },
    { "account_code_ref": "{{revenue_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
JSON

{
  "template_code": "job_expense_on_behalf",
  "template_version": 1,
  "scope": ["law_office", "service_office"],
  "category": "services",
  "ui": { "button_group_ar": "نيابة عن العميل", "display_name_ar": "دفعت نيابة عن العميل", "icon": "receipt_send",
          "description_ar": "رسوم محكمة/حكومية دفعتها نيابة عن الموكل وسترجعها منه", "sort_order": 4 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "job_id", "type": "select", "label_ar": "الملف/القضية", "required": true, "options_source": "open_jobs()" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": true, "options": ["1101", "1110"] },
    { "key": "receivable_account", "type": "select", "label_ar": "نوع الذمة", "required": true, "options": ["1640", "1650"] }
  ],
  "journal_rules": [
    { "account_code_ref": "{{receivable_account}}", "side": "debit", "amount_formula": "{{amount}}", "contact_ref": "{{job.contact_id}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}" }
  ]
}
JSON

{
  "template_code": "job_expense_recovery",
  "template_version": 1,
  "scope": ["law_office", "service_office"],
  "category": "services",
  "ui": { "button_group_ar": "نيابة عن العميل", "display_name_ar": "تحصيل مبلغ النيابة", "icon": "payment_receive",
          "description_ar": "استرجعت من العميل مبلغ كنت دفعته نيابة عنه", "sort_order": 5 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "job_id", "type": "select", "label_ar": "الملف/القضية", "required": true, "options_source": "open_jobs()" },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "received_to_account", "type": "select", "label_ar": "استلمت في؟", "required": true, "options": ["1101", "1110"] },
    { "key": "receivable_account", "type": "select", "label_ar": "نوع الذمة", "required": true, "options": ["1640", "1650"] }
  ],
  "journal_rules": [
    { "account_code_ref": "{{received_to_account}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "{{receivable_account}}", "side": "credit", "amount_formula": "{{amount}}", "contact_ref": "{{job.contact_id}}" }
  ]
}
JSON

{
  "template_code": "commission_expense",
  "template_version": 1,
  "scope": ["clinic", "workshop"],
  "category": "services",
  "ui": { "button_group_ar": "عمولات", "display_name_ar": "عمولة طبيب/فني", "icon": "percent",
          "description_ar": "حصة الطبيب أو الفني من الإيراد", "sort_order": 6 },
  "fields": [
    { "key": "transaction_date", "type": "date", "label_ar": "التاريخ", "required": true, "default": "today" },
    { "key": "job_id", "type": "select", "label_ar": "مرتبط بملف؟", "required": false, "options_source": "open_jobs()" },
    { "key": "commission_expense_account", "type": "select", "label_ar": "نوع العمولة", "required": true, "options": ["5220", "5230"] },
    { "key": "amount", "type": "amount", "label_ar": "المبلغ", "required": true },
    { "key": "currency_code", "type": "currency_picker", "label_ar": "العملة", "required": true },
    { "key": "pay_now", "type": "toggle", "label_ar": "دفعتها الآن؟", "required": true, "default": false },
    { "key": "paid_from_account", "type": "select", "label_ar": "دفعت من وين؟", "required": false, "visible_when": "pay_now == true", "options": ["1101", "1110"] },
    { "key": "accrued_account", "type": "select", "label_ar": "حساب الاستحقاق", "required": false, "visible_when": "pay_now == false", "options": ["2620", "2630"] },
    { "key": "employee_id", "type": "contact_picker", "label_ar": "الطبيب/الفني", "required": true }
  ],
  "journal_rules": [
    { "account_code_ref": "{{commission_expense_account}}", "side": "debit", "amount_formula": "{{amount}}" },
    { "account_code_ref": "{{paid_from_account}}", "side": "credit", "amount_formula": "{{amount}}", "condition": "pay_now == true" },
    { "account_code_ref": "{{accrued_account}}", "side": "credit", "amount_formula": "{{amount}}", "contact_ref": "{{employee_id}}", "condition": "pay_now == false" }
  ]
}
9. مترجم الملخص المبسّط (Simple Summary Renderer)
يحقق فلسفة "لا مصطلحات محاسبية" من النقاشات السابقة.

text

function renderSimpleSummary(template, lines, payload):
    sentences = []
    for line in lines:
        account = getAccount(line.account_code_ref)
        direction_verb = (line.side == "debit" && account.normal_balance == "debit") 
                          || (line.side == "credit" && account.normal_balance == "credit")
                          ? "يزيد" : "ينقص"
        sentences.append(f"{account.name_ar_simple} {direction_verb} {formatMoney(line.amount, line.currency_code)}")
    return join(sentences, " · ")
مثال فعلي لمخرجات sale_credit:

"العميل أحمد يزيد 15,000 ريال · إيراد المبيعات يزيد 15,000 ريال"

مع زر منفصل "عرض القيد المحاسبي" يعرض lines الفعلية بمصطلحات مدين/دائن للمحاسب فقط.

10. الحوكمة والاختبارات (CI/CD)
القاعدة	الآلية
كل قالب يجب أن يحتوي golden_test_cases واحدًا على الأقل	فحص آلي عند Pull Request
كل Golden Test يُنفَّذ عبر المحرك الفعلي ويُتحقق من التوازن	Unit Test تلقائي
اختبار Fuzz: توليد 1000 قيمة عشوائية لكل قالب يحتوي partial/distribution والتحقق من التوازن دومًا	يكشف أخطاء التقريب مبكرًا
account_code_ref يجب أن يطابق حسابًا فعليًا بـ is_postable=true في ملفات Seed المدموجة لنفس scope	تحقق متقاطع بين مستودعي Seed والقوالب
أي تعديل على journal_rules يرفع template_version إلزاميًا	Git Hook / Lint Rule
القوالب تُنشر عبر template_registry مع definition_checksum	يمنع تنفيذ قالب مُعدَّل دون توثيق
11. خلاصة وتوصيات
هذا الكتالوج هو العقل التنفيذي للتطبيق — واجهة المستخدم (الأزرار) تُبنى آليًا من حقل ui في كل قالب، لا تُكتب يدويًا لكل شاشة، مما يسمح بإضافة زر جديد بالكامل عبر ملف JSON فقط.
ابدأ تطوير الواجهة بمحرك "عارض قوالب عام" (Generic Template Renderer) يقرأ fields ويولّد النموذج تلقائيًا، بدل بناء شاشة منفصلة لكل زر — يختصر وقت التطوير بشكل كبير ويضمن اتساق التجربة.
قاعدة التقريب (القسم 3.3) غير قابلة للتفاوض — أي قالب توزيع لاحق (حتى خارج هذه القائمة) يجب أن يلتزم بها لمنع كسر توازن القيود.
اربط cogs_amount() بمحرك تقييم مخزون فعلي قبل تفعيل الوضع التفصيلي للبيع — حتى ذلك الحين، يُفعَّل "الوضع السريع" فقط افتراضيًا لتفادي قيود تكلفة خاطئة.
راجع قوالب الخدمات (خاصة job_expense_on_behalf وcommission_expense) مع محامٍ وطبيب فعليين قبل الإطلاق، لأن دقة هذه السيناريوهات أهم من سرعتها في هذين القطاعين تحديدًا.
الخطوة التالية المقترحة: تصميم وحدة المخزون التفصيلية (جدول items, batches, محرك التكلفة بالمتوسط المرجّح الذي تعتمد عليه cogs_amount())، أو الانتقال لتصميم Wireframes الشاشات التي تستهلك هذه القوالب فعليًا. أيهما تفضل؟




نعم بأفضل الأساليب والوسائل وبأداء احترافي
