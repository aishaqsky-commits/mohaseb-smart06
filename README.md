# منصة المحاسب الذكي للتجار وأصحاب المهن الخدمية
### Smart Merchant Accounting Platform (Local-First FinTech Platform)

منصة محاسبية ذكية مصممة خصيصاً للتجار وأصحاب المهن الخدمية (عيادات، ورش صيانة، مكاتب محاماة، مكاتب خدمات عامة). تهدف لتمكين المستخدم غير المختص من إدارة عملياته المالية بدقة محاسبية صارمة (أساس الاستحقاق والقيد المزدوج) دون الحاجة لمعرفة مصطلحات "المدين والدائن".

المشروع مصمم لخدمة السوق اليمني كأولوية مع القابلية للتوسع في الوطن العربي، ومهيأ هندسياً لخدمة ما يصل إلى **5 ملايين مستخدم** بنمط العمل دون اتصال بالإنترنت (**Local-First**).

---

## 🏛️ الهيكل العام للمشروع (Project Structure)

تم تنظيم المشروع في مستودع موحد (**Monorepo**) مقسم وفق أفضل الممارسات الهندسية:

```
d:/mohaseb-smart06/
├── docs/                                  # التوثيق المعماري والهندسي الشامل
│   ├── 01-prd/
│   │   └── PRD-v1.0.md                    # وثيقة متطلبات المنتج الرسمية v1.0
│   ├── 02-architecture/
│   │   ├── system-overview.md             # المعمارية الشاملة والمكدس التقني
│   │   ├── local-first-and-sync.md        # معمارية العمل دون اتصال وسجل المزامنة
│   │   └── api-specifications.md          # مواصفات REST API الكاملة للمرحلة 0
│   ├── 03-database/
│   │   └── erd-and-data-models.md         # مخطط العلاقات وقواعد البيانات التفصيلي
│   ├── 04-modules/
│   │   ├── chart-of-accounts.md           # شجرة الحسابات، الأكواد، ومحرك الزرع
│   │   ├── transaction-templates.md       # محرك القوالب التشغيلية ولغة التعبيرات
│   │   ├── inventory-management.md        # وحدة المخزون، التكلفة، ودعم الصلاحية FEFO
│   │   ├── ar-ap-subledger.md             # وحدة الذمم، الفواتير المفتوحة، وأعمار الديون
│   │   ├── financial-reporting.md         # التقارير المالية ومحرك إقفال الفترات واليوم
│   │   └── subscriptions-and-wallets.md   # المحافظ اليمنية، باقات الاشتراك، والـ AI Quota
│   ├── 05-ui-ux/
│   │   ├── design-system.md               # نظام التصميم الموحد (Atomic Design & RTL)
│   │   └── wireframes-and-flows.md        # تخطيط الشاشات وتدفقات التفاعل
│   └── 06-strategy/
│       ├── yemeni-market-analysis.md      # خصوصيات وتحديات السوق اليمني
│       ├── mvp-critique-and-refinements.md# تصويب المسار وتلافي القصور المحاسبي
│       └── decisions-log.md               # سجل القرارات الهندسية وتطور الفكرة
│
├── database/                              # مخططات قواعد البيانات والتهجيرات (SQL)
│   ├── schemas/
│   │   ├── 001_phase0_core.sql            # الهوية، الصلاحيات، الحسابات، القيود، المزامنة
│   │   ├── 002_inventory.sql              # المخازن، الأصناف، الدفعات، الحركات، الجرد
│   │   ├── 003_ar_ap_subledger.sql        # الفواتير المفتوحة، التخصيصات، سقف الائتمان
│   │   ├── 004_reporting_closing.sql      # الفترات المحاسبية، الإقفال، الأرصدة التجميعية
│   │   └── 005_subscriptions_wallets.sql  # الباقات، المحافظ اليمنية، وسجل استهلاك الـ AI
│   └── sqlite/
│       └── local_schema.sql               # مخطط قاعدة SQLite المحلية المشفرة (SQLCipher)
│
├── packages/
│   ├── core-accounting/                   # حزمة النواة المحاسبية ومحرك القوالب (TypeScript)
│   │   ├── package.json
│   │   ├── tsconfig.json
│   │   ├── src/
│   │   │   ├── domain/                    # طبقة النطاق (Value Objects, Entities, Errors, Ports)
│   │   │   │   ├── value-objects/Money.ts # كائن القيمة المالي الدقيق (Decimal.js)
│   │   │   │   ├── entities/Account.ts
│   │   │   │   ├── entities/JournalLine.ts
│   │   │   │   ├── entities/JournalEntry.ts # Aggregate Root الحاكم لتوازن القيد
│   │   │   │   ├── errors/AccountingErrors.ts
│   │   │   │   └── ports/AccountRepository.ts & JournalRepository.ts
│   │   │   ├── application/               # طبقة التطبيق
│   │   │   │   └── JournalEngine.ts       # نقطة الدخول الذرية لترحيل وعكس القيود
│   │   │   ├── infrastructure/            # طبقة البنية التحتية
│   │   │   │   └── sqlite/                # تنفيذ المستودعات باستخدام better-sqlite3
│   │   │   └── templates/                 # محرك تنفيذ القوالب ومفسر الصيغ الآمن
│   │   │       ├── engine/Lexer.ts & Parser.ts & ExpressionEngine.ts & FunctionRegistry.ts
│   │   │       ├── validation/TemplateValidator.ts
│   │   │       ├── registry/TemplateRegistry.ts
│   │   │       └── TemplateExecutionEngine.ts
│   │   └── tests/                         # الاختبارات الشاملة (TDD & Golden Test Cases)
│   │       ├── Money.test.ts
│   │       ├── JournalEngine.test.ts
│   │       ├── golden-cases/rounding.fuzz.test.ts
│   │       └── templates/ExpressionEngine.test.ts & TemplateExecutionEngine.test.ts
│   │
│   ├── chart-of-accounts/                 # حزمة شجرة الحسابات وملفات الزرع (Seeds)
│   │   ├── package.json
│   │   ├── schema/seed.schema.json        # العقد القياسي (Meta-Schema)
│   │   └── seeds/
│   │       ├── core.seed.json             # الحسابات المشتركة لكل الأنشطة
│   │       ├── retail.seed.json           # إضافات نشاط التجزئة والتموينات
│   │       ├── clinic.seed.json           # إضافات العيادات والمراكز الطبية
│   │       ├── workshop.seed.json         # إضافات الورش الفنية وصيانة السيارات
│   │       ├── law_office.seed.json       # إضافات مكاتب المحاماة
│   │       └── service_office.seed.json   # إضافات مكاتب الخدمات والمعاملات
│   │
│   └── templates/                         # حزمة كتالوج القوالب التشغيلية الجاهزة (25 قالباً)
│       ├── package.json
│       ├── schema/template.schema.json    # العقد القياسي لتعريف القوالب
│       ├── purchases/                     # شراء نقدي، آجل، جزئي
│       ├── sales/                         # بيع نقدي، آجل، جزئي
│       ├── returns/                       # مردودات مبيعات ومشتريات
│       ├── settlements/                   # تحصيل ديون وسداد موردين
│       ├── damage/                        # إتلاف بضاعة مع توزيع مرن
│       ├── opening-balance/               # معالج الرصيد الافتتاحي
│       ├── expenses/                      # مصروفات يومية وموزعة ومستحقة
│       ├── owner/                         # مسحوبات وإيداعات المالك
│       └── services/                      # أوامر الشغل، تحصيل أتعاب، ومصروف بالنيابة
│
├── package.json                           # ملف تكوين مساحة العمل الرئيسية
├── .gitignore                             # قواعد التجاهل للمستودع
└── README.md                              # الدليل الرئيسي للمشروع
```

---

## 🚀 التقنيات والمعايير الهندسية (Technology Stack)

* **لغة البرمجة الأساسية:** TypeScript (Target: ES2022)
* **معمارية الكود:** Clean Architecture / Hexagonal Architecture مع تطبيق نمط التطوير الموجه باختبارات (TDD)
* **الحسابات المالية الدقيقة:** `Decimal.js` (حظر كامل لنوع `number` الافتراضي في جافاسكريبت لمنع أخطاء الفاصلة العائمة)
* **قاعدة البيانات المحلية:** SQLite مشفرة (`SQLCipher` / `better-sqlite3`)
* **قاعدة بيانات الخادم:** PostgreSQL (للمزامنة والنسخ السحابي)
* **مفسر الصيغ الحسابية والقوالب:** Safe Expression Engine مبني خصيصاً (Lexer + Parser AST + Whitelist Functions) دون استخدام `eval()` لحماية النظام من ثغرات الحقن
* **المزامنة والنسخ:** نموذج Local-First مع سجل أحداث متسلسل (`Event Sourcing`) وساعات منطقية تصاعدية (`Lamport Clocks`) ومفاتيح فريدة `UUIDv4` مولدة محلياً

---

## 🧪 تشغيل الاختبارات والمراجعة (Testing & Verification)

للتأكد من سلامة وصحة النواة المحاسبية ومحرك القوالب:

```bash
# تثبيت التبعيات
npm install

# بناء الحزم البرمجية
npm run build

# تشغيل اختبارات الوحدة واختبارات التكامل والحالات الذهبية
npm test
```

جميع الاختبارات تغطي:
1. `Money.test.ts`: اختبار دقة العمليات الحسابية وتطابق العملات والتقريب المالي.
2. `JournalEngine.test.ts`: اختبار فرض توازن القيود، القيود البسيطة والمركبة، والقيود العكسية (Reversing Entries).
3. `rounding.fuzz.test.ts`: اختبارات عشوائية (Fuzz Testing) للتأكد من توازن القيد عند توزيع المبالغ بنسب مئوية.
4. `ExpressionEngine.test.ts`: اختبار التحليل النحوي والمفاضلة المنطقية والصيغ الرياضية المعقدة.
5. `TemplateExecutionEngine.test.ts`: اختبار تكامل شامل لتحويل مدخلات واجهة المستخدم إلى قيود محاسبية فعلية متوازنة ومرحلة بنجاح.

---

## 📌 الخطوات التالية (Next Steps)

1. مراجعة التوثيق المعماري ومخططات قواعد البيانات في مجلد `docs/`.
2. تثبيت الحزم وتشغيل اختبارات Jest الآلية في `packages/core-accounting/`.
3. البدء في تطوير واجهات التطبيق للهواتف الذكية (Flutter / Android) استناداً لنظام التصميم الموجود في `docs/05-ui-ux/`.
4. ربط وتفعيل محولات المحافظ الإلكترونية اليمنية (Adapters) بحسب العقد الموحد في `docs/04-modules/subscriptions-and-wallets.md`.
