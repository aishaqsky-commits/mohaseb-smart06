claude-sonnet-5-high
تصميم ملفات Seed لشجرة الحسابات
(Chart of Accounts Seed Files) — بأفضل الممارسات
0. قرارات تصميمية أساسية قبل البدء
0.1 تعديل مطلوب على جدول accounts (إضافة حقول ضرورية)
أثناء تصميم Seed اتضحت الحاجة لحقول لم تُذكر سابقًا في جدول accounts — إضافتها الآن أوفر بكثير من إضافتها لاحقًا بعد دخول بيانات حقيقية:

الحقل الجديد	النوع	الوصف
is_header	BOOLEAN DEFAULT FALSE	حساب تجميعي (رأس) لا تُرحَّل عليه قيود مباشرة
is_postable	BOOLEAN DEFAULT TRUE	عكس is_header منطقيًا — يُفرض بقيد CHECK: is_header != is_postable
is_contra	BOOLEAN DEFAULT FALSE	حساب عكسي (مثل مجمع الإهلاك، مسحوبات المالك) — رصيده الطبيعي عكس نوع تصنيفه
linked_contact_type	VARCHAR(20) NULL	customer / supplier / employee — للحسابات المجمّعة (Control Accounts) فقط
is_user_modified	BOOLEAN DEFAULT FALSE	يمنع التحديثات المستقبلية للـ Seed من الكتابة فوق تعديل يدوي للتاجر
description_ar	TEXT NULL	شرح مبسّط يظهر كـ Tooltip لغير المحاسب
seed_version	SMALLINT NULL	رقم إصدار الـ Seed الذي أنشأ هذا الحساب (لإدارة الترقيات)
قيد إلزامي على مستوى قاعدة البيانات:

SQL

CHECK (is_header = TRUE OR is_postable = TRUE)  -- لا حساب بلا أي وظيفة
CHECK (NOT (is_header = TRUE AND is_postable = TRUE)) -- حصرية الدور
CHECK (linked_contact_type IS NULL OR is_control_account = TRUE)
0.2 منهجية الترقيم (Numbering Convention) — العمود الفقري للتوسع المستقبلي
القرار الأهم: تُحجز نطاقات أرقام فارغة لكل قسم منذ البداية، بحيث تُضاف حسابات جديدة لأي نشاط لاحقًا دون تعارض رقمي، وتُتيح مستقبلًا دمج نشاطين في تاجر واحد (مثال واقعي: عيادة بها صيدلية صغيرة تبيع للعامة → تحتاج Seed عيادة + Seed تجزئة معًا دون تصادم أكواد).

المستوى	النطاق	المعنى
1 رقم	1-5	نوع الحساب الرئيسي (أصول/خصوم/حقوق ملكية/إيرادات/مصروفات)
2 أرقام	X0	قسم رئيسي (رأس/Header)
3 أرقام	X01-X09	حسابات النواة المشتركة (Core) تحت كل قسم
4 أرقام فأكثر	X10, X20, X30...	حسابات خاصة بنوع نشاط معيّن (Retail/Clinic/...)، كل نشاط يأخذ حزمة عشرية مخصصة
جدول حجز الحزم لكل نشاط (لتفادي أي تصادم مستقبلي):

النشاط	الحزمة المحجوزة
تجزئة (Retail)	X10 – X19
عيادة (Clinic)	X20 – X29
ورشة (Workshop)	X30 – X39
مكتب محاماة (Law Office)	X40 – X49
مكتب خدمات (Service Office)	X50 – X59
محجوز للتوسع المستقبلي	X60 – X99
1. العقد الرسمي لملفات Seed — JSON Meta-Schema
مبدأ Contract-First: قبل كتابة أي ملف Seed، يُعتمَد هذا الـ Schema كمرجع للتحقق الآلي (عبر Ajv أو ما يماثله) في خط أنابيب CI/CD، بحيث يُرفض أي ملف Seed لا يطابقه قبل الدمج.

JSON

{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "ChartOfAccountsSeedFile",
  "type": "object",
  "required": ["seed_meta", "accounts"],
  "properties": {
    "seed_meta": {
      "type": "object",
      "required": ["seed_version", "scope", "extends", "description_ar"],
      "properties": {
        "seed_version": { "type": "integer", "minimum": 1 },
        "scope": { "type": "string", "enum": ["core", "retail", "clinic", "workshop", "law_office", "service_office"] },
        "extends": { "type": ["string", "null"] },
        "description_ar": { "type": "string" }
      }
    },
    "accounts": {
      "type": "array",
      "items": {
        "type": "object",
        "required": [
          "code", "parent_code", "account_type", "name_ar_simple",
          "is_header", "is_postable", "sort_order"
        ],
        "properties": {
          "code": { "type": "string", "pattern": "^[0-9]{4,6}$" },
          "parent_code": { "type": ["string", "null"] },
          "account_type": { "type": "string", "enum": ["asset", "liability", "equity", "revenue", "expense"] },
          "name_ar_simple": { "type": "string", "maxLength": 100 },
          "name_technical": { "type": ["string", "null"] },
          "description_ar": { "type": ["string", "null"] },
          "is_header": { "type": "boolean" },
          "is_postable": { "type": "boolean" },
          "is_system_account": { "type": "boolean", "default": false },
          "is_control_account": { "type": "boolean", "default": false },
          "linked_contact_type": { "type": ["string", "null"], "enum": ["customer", "supplier", "employee", null] },
          "is_contra": { "type": "boolean", "default": false },
          "allow_multi_currency": { "type": "boolean", "default": false },
          "sort_order": { "type": "integer" }
        }
      }
    }
  }
}
2. ملف النواة المشتركة — core.seed.json
يُحمَّل لكل تاجر دون استثناء، بغض النظر عن نوع نشاطه، ثم تُضاف فوقه حزمة النشاط الخاصة.

JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "core",
    "extends": null,
    "description_ar": "شجرة الحسابات الأساسية المشتركة لكل الأنشطة"
  },
  "accounts": [
    { "code": "1000", "parent_code": null, "account_type": "asset", "name_ar_simple": "الأصول", "is_header": true, "is_postable": false, "sort_order": 10 },

    { "code": "1100", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "النقدية وما يعادلها", "is_header": true, "is_postable": false, "sort_order": 11 },
    { "code": "1101", "parent_code": "1100", "account_type": "asset", "name_ar_simple": "الصندوق الرئيسي", "name_technical": "النقدية بالصندوق - العملة الأساسية", "description_ar": "فلوسك الكاش في المحل", "is_header": false, "is_postable": true, "is_system_account": true, "allow_multi_currency": true, "sort_order": 1 },
    { "code": "1110", "parent_code": "1100", "account_type": "asset", "name_ar_simple": "البنك", "description_ar": "رصيدك في الحساب البنكي", "is_header": false, "is_postable": true, "allow_multi_currency": true, "sort_order": 2 },
    { "code": "1120", "parent_code": "1100", "account_type": "asset", "name_ar_simple": "محافظ إلكترونية", "description_ar": "جوالي، كريمي، فلوسك وغيرها", "is_header": false, "is_postable": true, "allow_multi_currency": true, "sort_order": 3 },

    { "code": "1200", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "المدينون", "is_header": true, "is_postable": false, "sort_order": 12 },
    { "code": "1210", "parent_code": "1200", "account_type": "asset", "name_ar_simple": "العملاء", "description_ar": "الفلوس اللي عند الناس (آجل)", "is_header": false, "is_postable": true, "is_system_account": true, "is_control_account": true, "linked_contact_type": "customer", "sort_order": 1 },
    { "code": "1220", "parent_code": "1200", "account_type": "asset", "name_ar_simple": "سلف الموظفين", "is_header": false, "is_postable": true, "is_control_account": true, "linked_contact_type": "employee", "sort_order": 2 },
    { "code": "1230", "parent_code": "1200", "account_type": "asset", "name_ar_simple": "ذمم مدينة أخرى", "is_header": false, "is_postable": true, "sort_order": 3 },

    { "code": "1300", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "المخزون", "is_header": true, "is_postable": false, "sort_order": 13 },

    { "code": "1400", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "مصروفات مدفوعة مقدمًا", "is_header": true, "is_postable": false, "sort_order": 14 },
    { "code": "1410", "parent_code": "1400", "account_type": "asset", "name_ar_simple": "إيجار مدفوع مقدمًا", "description_ar": "إيجار دفعته مقدم لفترة قادمة", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "1420", "parent_code": "1400", "account_type": "asset", "name_ar_simple": "مصروفات مقدمة أخرى", "is_header": false, "is_postable": true, "sort_order": 2 },

    { "code": "1500", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "الأصول الثابتة", "is_header": true, "is_postable": false, "sort_order": 15 },
    { "code": "1510", "parent_code": "1500", "account_type": "asset", "name_ar_simple": "أثاث ومعدات", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "1520", "parent_code": "1500", "account_type": "asset", "name_ar_simple": "سيارات ووسائل نقل", "is_header": false, "is_postable": true, "sort_order": 2 },
    { "code": "1590", "parent_code": "1500", "account_type": "asset", "name_ar_simple": "مجمع إهلاك الأصول الثابتة", "is_header": false, "is_postable": true, "is_contra": true, "sort_order": 9 },

    { "code": "1600", "parent_code": "1000", "account_type": "asset", "name_ar_simple": "أصول أخرى", "is_header": true, "is_postable": false, "sort_order": 16 },

    { "code": "2000", "parent_code": null, "account_type": "liability", "name_ar_simple": "الخصوم", "is_header": true, "is_postable": false, "sort_order": 20 },

    { "code": "2100", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "الموردون", "is_header": true, "is_postable": false, "sort_order": 21 },
    { "code": "2110", "parent_code": "2100", "account_type": "liability", "name_ar_simple": "الموردون", "description_ar": "الفلوس اللي عليك للناس (آجل)", "is_header": false, "is_postable": true, "is_system_account": true, "is_control_account": true, "linked_contact_type": "supplier", "sort_order": 1 },

    { "code": "2200", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "القروض", "is_header": true, "is_postable": false, "sort_order": 22 },
    { "code": "2210", "parent_code": "2200", "account_type": "liability", "name_ar_simple": "قروض قصيرة الأجل", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "2220", "parent_code": "2200", "account_type": "liability", "name_ar_simple": "قروض طويلة الأجل", "is_header": false, "is_postable": true, "sort_order": 2 },

    { "code": "2300", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "مستحقات", "is_header": true, "is_postable": false, "sort_order": 23 },
    { "code": "2310", "parent_code": "2300", "account_type": "liability", "name_ar_simple": "رواتب مستحقة", "description_ar": "رواتب موظفين لسه ما انصرفت", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "2320", "parent_code": "2300", "account_type": "liability", "name_ar_simple": "مصروفات مستحقة أخرى", "is_header": false, "is_postable": true, "sort_order": 2 },

    { "code": "2400", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "دفعات مقدمة من عملاء", "description_ar": "عميل دفع لك مقدم قبل التسليم", "is_header": false, "is_postable": true, "sort_order": 24 },
    { "code": "2500", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "ضرائب مستحقة", "is_header": false, "is_postable": true, "sort_order": 25 },
    { "code": "2600", "parent_code": "2000", "account_type": "liability", "name_ar_simple": "خصوم أخرى", "is_header": true, "is_postable": false, "sort_order": 26 },

    { "code": "3000", "parent_code": null, "account_type": "equity", "name_ar_simple": "حقوق الملكية", "is_header": true, "is_postable": false, "sort_order": 30 },
    { "code": "3100", "parent_code": "3000", "account_type": "equity", "name_ar_simple": "رأس المال", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 1 },
    { "code": "3200", "parent_code": "3000", "account_type": "equity", "name_ar_simple": "مسحوبات المالك", "description_ar": "الفلوس اللي سحبتها لنفسك من المحل", "is_header": false, "is_postable": true, "is_system_account": true, "is_contra": true, "sort_order": 2 },
    { "code": "3300", "parent_code": "3000", "account_type": "equity", "name_ar_simple": "أرباح مرحّلة", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 3 },

    { "code": "4000", "parent_code": null, "account_type": "revenue", "name_ar_simple": "الإيرادات", "is_header": true, "is_postable": false, "sort_order": 40 },
    { "code": "4100", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات أخرى", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "4200", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "مردودات ومسموحات", "description_ar": "قيمة المرتجعات والخصومات الممنوحة", "is_header": false, "is_postable": true, "is_contra": true, "sort_order": 2 },
    { "code": "4900", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "أرباح فروق العملة", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 9 },

    { "code": "5000", "parent_code": null, "account_type": "expense", "name_ar_simple": "المصروفات", "is_header": true, "is_postable": false, "sort_order": 50 },
    { "code": "5100", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "تكلفة المبيعات/الخدمات", "is_header": true, "is_postable": false, "sort_order": 1 },

    { "code": "5200", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "الرواتب والأجور", "is_header": true, "is_postable": false, "sort_order": 2 },
    { "code": "5201", "parent_code": "5200", "account_type": "expense", "name_ar_simple": "رواتب وأجور الموظفين", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5300", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "الإيجارات", "is_header": true, "is_postable": false, "sort_order": 3 },
    { "code": "5301", "parent_code": "5300", "account_type": "expense", "name_ar_simple": "إيجار المحل/المكتب", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5400", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "كهرباء ومياه", "is_header": true, "is_postable": false, "sort_order": 4 },
    { "code": "5401", "parent_code": "5400", "account_type": "expense", "name_ar_simple": "فاتورة الكهرباء والمياه", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5500", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "النظافة", "is_header": true, "is_postable": false, "sort_order": 5 },
    { "code": "5501", "parent_code": "5500", "account_type": "expense", "name_ar_simple": "مصروفات النظافة", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5600", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "الدعاية والتسويق", "is_header": true, "is_postable": false, "sort_order": 6 },
    { "code": "5601", "parent_code": "5600", "account_type": "expense", "name_ar_simple": "مواد دعائية وإعلانات", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5700", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "التالف والخسائر", "is_header": true, "is_postable": false, "sort_order": 7 },
    { "code": "5701", "parent_code": "5700", "account_type": "expense", "name_ar_simple": "تالف ومنتهي الصلاحية", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5800", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "مصروفات عمومية أخرى", "is_header": true, "is_postable": false, "sort_order": 8 },
    { "code": "5801", "parent_code": "5800", "account_type": "expense", "name_ar_simple": "مصروفات متنوعة", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "5900", "parent_code": "5000", "account_type": "expense", "name_ar_simple": "خسائر فروق العملة", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 9 }
  ]
}
ملاحظة تطبيقية مهمة (لا تُدرَج في Seed): عند تفعيل التاجر لعملة إضافية (SAR أو USD) من tenant_currencies، يُنفَّذ منطق تلقائي في التطبيق (لا في Seed الثابت) لإنشاء حسابات فرعية تلقائية بنفس النمط: 1101-SAR, 1101-USD تحت نفس الأب 1101، وكذلك 1110 و1120. هذا يُبقي ملفات Seed ثابتة ونظيفة بينما يبقى دعم العملات ديناميكيًا.

3. ملفات التوسع الخاصة بكل نشاط
3.1 retail.seed.json — تجزئة
JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "retail",
    "extends": "core",
    "description_ar": "إضافات شجرة الحسابات لنشاط التجزئة (بقالة، ملابس، مواد غذائية...)"
  },
  "accounts": [
    { "code": "1310", "parent_code": "1300", "account_type": "asset", "name_ar_simple": "مخزون البضاعة", "description_ar": "قيمة البضاعة الموجودة بالمحل", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 1 },

    { "code": "4150", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات المبيعات", "description_ar": "كل فلوس المبيعات", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 10 },

    { "code": "5110", "parent_code": "5100", "account_type": "expense", "name_ar_simple": "تكلفة البضاعة المباعة", "description_ar": "تكلفة الأصناف اللي بعتها فعلًا", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 10 }
  ]
}
3.2 clinic.seed.json — عيادة (طبية/أسنان/بيطرية)
JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "clinic",
    "extends": "core",
    "description_ar": "إضافات شجرة الحسابات للعيادات"
  },
  "accounts": [
    { "code": "1320", "parent_code": "1300", "account_type": "asset", "name_ar_simple": "مخزون الأدوية والمستلزمات", "description_ar": "الأدوية والمستلزمات الطبية بالعيادة", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "2620", "parent_code": "2600", "account_type": "liability", "name_ar_simple": "عمولات أطباء مستحقة", "description_ar": "نصيب الطبيب من الكشف لسه ما انصرف", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "4160", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات الكشف الطبي", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 20 },
    { "code": "4161", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات الإجراءات والعمليات", "is_header": false, "is_postable": true, "sort_order": 21 },

    { "code": "5120", "parent_code": "5100", "account_type": "expense", "name_ar_simple": "تكلفة الأدوية والمستلزمات المستخدمة", "is_header": false, "is_postable": true, "sort_order": 20 },
    { "code": "5220", "parent_code": "5200", "account_type": "expense", "name_ar_simple": "عمولات ومكافآت الأطباء", "is_header": false, "is_postable": true, "sort_order": 10 }
  ]
}
3.3 workshop.seed.json — ورشة (سيارات/كهرباء/حدادة)
JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "workshop",
    "extends": "core",
    "description_ar": "إضافات شجرة الحسابات للورش الفنية"
  },
  "accounts": [
    { "code": "1330", "parent_code": "1300", "account_type": "asset", "name_ar_simple": "مخزون قطع الغيار", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "2630", "parent_code": "2600", "account_type": "liability", "name_ar_simple": "عمولات فنيين مستحقة", "is_header": false, "is_postable": true, "sort_order": 1 },

    { "code": "4170", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات أجرة الصنعة", "description_ar": "أجرة الشغل بدون قطع الغيار", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 30 },
    { "code": "4171", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات بيع قطع الغيار", "is_header": false, "is_postable": true, "sort_order": 31 },

    { "code": "5130", "parent_code": "5100", "account_type": "expense", "name_ar_simple": "تكلفة قطع الغيار المستخدمة", "is_header": false, "is_postable": true, "sort_order": 30 },
    { "code": "5230", "parent_code": "5200", "account_type": "expense", "name_ar_simple": "عمولات الفنيين", "is_header": false, "is_postable": true, "sort_order": 20 }
  ]
}
3.4 law_office.seed.json — مكتب محاماة
JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "law_office",
    "extends": "core",
    "description_ar": "إضافات شجرة الحسابات لمكاتب المحاماة"
  },
  "accounts": [
    { "code": "1640", "parent_code": "1600", "account_type": "asset", "name_ar_simple": "ذمم نيابة عن الموكلين", "description_ar": "رسوم محاكم ومصاريف دفعتها نيابة عن الموكل وسترجعها منه", "is_header": false, "is_postable": true, "is_system_account": true, "is_control_account": true, "linked_contact_type": "customer", "sort_order": 1 },

    { "code": "4180", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات الأتعاب القانونية", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 40 },
    { "code": "4181", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات الاستشارات القانونية", "is_header": false, "is_postable": true, "sort_order": 41 },

    { "code": "5140", "parent_code": "5100", "account_type": "expense", "name_ar_simple": "رسوم ومصاريف قضائية غير مستردة", "description_ar": "مصاريف دفعتها نيابة عن الموكل ولم تسترجعها", "is_header": false, "is_postable": true, "sort_order": 40 }
  ]
}
3.5 service_office.seed.json — مكتب خدمات (معاملات حكومية/طباعة)
JSON

{
  "seed_meta": {
    "seed_version": 1,
    "scope": "service_office",
    "extends": "core",
    "description_ar": "إضافات شجرة الحسابات لمكاتب الخدمات العامة"
  },
  "accounts": [
    { "code": "1340", "parent_code": "1300", "account_type": "asset", "name_ar_simple": "مخزون مستلزمات الطباعة", "is_header": false, "is_postable": true, "sort_order": 1 },
    { "code": "1650", "parent_code": "1600", "account_type": "asset", "name_ar_simple": "ذمم نيابة عن العملاء", "description_ar": "رسوم حكومية دفعتها نيابة عن العميل وسترجعها منه", "is_header": false, "is_postable": true, "is_system_account": true, "is_control_account": true, "linked_contact_type": "customer", "sort_order": 2 },

    { "code": "4190", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات عمولة الخدمات", "description_ar": "ربحك من إنجاز المعاملة", "is_header": false, "is_postable": true, "is_system_account": true, "sort_order": 50 },
    { "code": "4191", "parent_code": "4000", "account_type": "revenue", "name_ar_simple": "إيرادات الطباعة والتصوير", "is_header": false, "is_postable": true, "sort_order": 51 },

    { "code": "5150", "parent_code": "5100", "account_type": "expense", "name_ar_simple": "تكلفة مستلزمات الطباعة", "is_header": false, "is_postable": true, "sort_order": 50 }
  ]
}
4. محرك الزرع (Seeding Engine) — خوارزمية التنفيذ
4.1 المبادئ الإلزامية
Idempotent دائمًا: تشغيل السكربت 10 مرات ينتج نفس النتيجة بالضبط (لا تكرار، لا تضارب).
Upsert بالمفتاح المركّب (tenant_id, code) لا بـ id.
لا يُكتب فوق تعديل يدوي للتاجر (is_user_modified = true يوقف التحديث التلقائي لاسم ذلك الحساب تحديدًا مستقبلًا).
بناء على مرحلتين لضمان حل parent_code → parent_account_id بشكل صحيح بغض النظر عن ترتيب الصفوف في الملف.
4.2 الخوارزمية (Pseudocode)
text

function seedChartOfAccounts(tenant_id, business_type_code):
    core_file   = loadSeedFile("core.seed.json")
    type_file   = loadSeedFile(business_type_code + ".seed.json")

    validateAgainstJsonSchema(core_file)
    validateAgainstJsonSchema(type_file)

    merged_accounts = core_file.accounts + type_file.accounts

    validateNoDuplicateCodes(merged_accounts)
    validateAllParentCodesExist(merged_accounts)
    validateHeaderPostableConsistency(merged_accounts)
    validateControlAccountsHaveContactType(merged_accounts)

    // المرحلة 1: إدراج/تحديث كل الحسابات بدون ربط الأب بعد
    code_to_id_map = {}
    for account in sortByCodeLength(merged_accounts):  // الآباء أولًا دائمًا بسبب طول الكود
        existing = findAccount(tenant_id, account.code)
        if existing exists:
            if NOT existing.is_user_modified:
                updateAccountFieldsExceptId(existing, account)
            code_to_id_map[account.code] = existing.id
        else:
            new_id = generateUUID()
            insertAccount(tenant_id, new_id, account, seed_version)
            code_to_id_map[account.code] = new_id

    // المرحلة 2: ربط parent_account_id بعد ضمان وجود كل السجلات
    for account in merged_accounts:
        if account.parent_code is not null:
            parent_id = code_to_id_map[account.parent_code]
            setParentAccountId(code_to_id_map[account.code], parent_id)

    logSeedExecution(tenant_id, business_type_code, seed_version, timestamp)
4.3 قواعد التحقق قبل الاعتماد (Pre-merge Validation Rules)
#	القاعدة	طريقة التحقق
1	لا تكرار في code داخل نفس الدمج (core + نوع النشاط)	فحص برمجي بسيط على مصفوفة الأكواد
2	كل parent_code يشير لحساب موجود فعليًا ضمن الدمج	بناء شجرة والتحقق من عدم وجود عقدة يتيمة
3	is_header = true لا يملك is_postable = true وبالعكس	تحقق مباشر من الحقلين
4	كل حساب is_header = true يجب أن يملك ابنًا واحدًا على الأقل	فحص بعد بناء الشجرة الكاملة
5	is_control_account = true يجب أن يرافقه linked_contact_type غير فارغ	تحقق مباشر
6	أكواد كل ملف نشاط تقع ضمن النطاق العشري المخصص له (جدول القسم 0.2)	Regex/Range check آلي
7	كل حساب account_type يطابق نوع والده	تحقق تسلسلي أثناء بناء الشجرة
توصية CI/CD: تُدمَج هذه التحققات في Pipeline تلقائي (GitHub Actions مثلًا) يرفض أي Pull Request يعدّل ملفات Seed دون اجتياز كل القواعد أعلاه — لا تُراجَع هذه الملفات بالعين البشرية فقط.

5. إدارة الإصدارات والترقية المستقبلية (Seed Versioning)
السيناريو	المعالجة
إضافة حساب جديد لنوع نشاط بعد انتشار التطبيق	زيادة seed_version، تشغيل seedChartOfAccounts على كل Tenant من نفس النوع عبر Job مجدول (upsert يضيف فقط الحساب الجديد، لا يمس الموجود)
تاجر غيّر اسم حساب افتراضي بنفسه	is_user_modified = true يُحيّد تحديث name_ar_simple فقط لذلك الحساب تحديدًا مستقبلًا، بينما يستمر النظام بإضافة حسابات جديدة أخرى بأمان
حذف حساب افتراضي من Seed مستقبلًا	ممنوع فعليًا إن وُجدت عليه حركات (يُطبَّق نفس قيد الحذف العادي في API)، وإلا يُعطَّل (is_active=false) لا يُحذف من الملف لتجنب كسر تجار قدامى
نشاط هجين (مثال: عيادة بها صيدلية بيع عام)	تحميل core + clinic + retail معًا — ممكن بفضل حصرية النطاقات العشرية المذكورة في القسم 0.2
6. خلاصة وتوصيات
هذه الملفات هي "دستور" التطبيق المحاسبي — أي خطأ في الترقيم أو العلاقات الهرمية هنا ينعكس على كل تاجر يُسجَّل لاحقًا؛ يجب أن تخضع لمراجعة محاسب معتمد فعليًا قبل الاعتماد النهائي، بالتحديد الحسابات الخاصة بكل نشاط (العمولات، الذمم النيابية).
لا تبدأ التطوير الفعلي لمحرك القوالب (المرحلة 1) قبل تجميد نسخة seed_version: 1 من كل الملفات الستة (Core + 5 أنشطة)، لأن القوالب (شراء/بيع/تالف...) ستُشير مباشرة إلى هذه الأكواد (account_code لا account_id في تعريف القالب نفسه، ليبقى القالب محمولًا بين كل التجار).
استخدم الأكواد (code) لا المعرفات (id) كمرجع داخل تعريفات القوالب (المرحلة 1) — هذا ما يُمكِّن القوالب من العمل بشكل موحّد عبر ملايين المستأجرين رغم اختلاف id الفعلي لكل حساب.
اختبر فعليًا تحميل نشاط هجين (عيادة + تجزئة) كحالة اختبار قبول (Acceptance Test) واحدة على الأقل، للتأكد عمليًا أن نظام حجز النطاقات يعمل كما خُطِّط له، حتى لو لم تُطلَق هذه الميزة فورًا للمستخدمين.
وثّق هذا الملف كمرجع حي (Living Document) في مستودع الكود، بحيث أي إضافة حساب جديد تمر عبر نفس خط تحقق CI/CD، لا تعديل يدوي مباشر في قاعدة بيانات الإنتاج أبدًا.
الخطوة التالية المقترحة: تصميم تعريفات القوالب (Transaction Templates) للمرحلة 1 — أي ملف templates/sale_cash.json, templates/purchase_credit.json... إلخ، التي تستخدم أكواد الحسابات المعرَّفة هنا بالضبط لإنتاج القيود تلقائيًا. هل تريد البدء بها؟




الأول تصميم ملفات Seed... بأفضل الممارسات والأساليب وبأداء احترافي
