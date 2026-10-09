1. مخطط العلاقات (ERD) — Mermaid
1.1 نطاق الهوية والصلاحيات (Identity & Access)
mermaid

erDiagram
    TENANTS ||--o{ TENANT_USERS : "has"
    USERS ||--o{ TENANT_USERS : "belongs_to"
    ROLES ||--o{ TENANT_USERS : "assigned_via"
    ROLES ||--o{ ROLE_PERMISSIONS : "has"
    PERMISSIONS ||--o{ ROLE_PERMISSIONS : "granted_in"
    TENANTS ||--o{ DEVICES : "owns"
    USERS ||--o{ DEVICES : "registers"
    USERS ||--o{ AUTH_SESSIONS : "has"
    DEVICES ||--o{ AUTH_SESSIONS : "bound_to"
1.2 نطاق المحاسبة الجوهري (Accounting Core)
mermaid

erDiagram
    TENANTS ||--o{ ACCOUNTS : "has"
    ACCOUNT_TYPES ||--o{ ACCOUNTS : "classifies"
    ACCOUNTS ||--o{ ACCOUNTS : "parent_of"
    TENANTS ||--o{ CONTACTS : "has"
    CONTACTS ||--o| ACCOUNTS : "linked_control_account"
    TENANTS ||--o{ JOURNAL_ENTRIES : "has"
    JOURNAL_ENTRIES ||--|{ JOURNAL_LINES : "contains"
    ACCOUNTS ||--o{ JOURNAL_LINES : "affected"
    CONTACTS ||--o{ JOURNAL_LINES : "affected"
    JOURNAL_ENTRIES ||--o| JOURNAL_ENTRIES : "reversal_of"
1.3 نطاق العملات (Multi-Currency)
mermaid

erDiagram
    TENANTS ||--o{ TENANT_CURRENCIES : "enables"
    CURRENCIES ||--o{ TENANT_CURRENCIES : "used_in"
    TENANTS ||--o{ EXCHANGE_RATES : "sets"
    CURRENCIES ||--o{ EXCHANGE_RATES : "from_currency"
    CURRENCIES ||--o{ EXCHANGE_RATES : "to_currency"
    JOURNAL_LINES }o--|| CURRENCIES : "denominated_in"
1.4 نطاق النظام والمزامنة (System & Sync)
mermaid

erDiagram
    TENANTS ||--o{ EVENT_LOG : "generates"
    DEVICES ||--o{ EVENT_LOG : "originates"
    TENANTS ||--o{ AUDIT_LOG : "generates"
    USERS ||--o{ AUDIT_LOG : "performs"
    TENANTS ||--o{ SUBSCRIPTIONS : "has"
    SUBSCRIPTION_PLANS ||--o{ SUBSCRIPTIONS : "defines"
2. تفصيل الجداول حقلًا حقلًا
علّامة المرحلة: 🟢 = نشط وظيفيًا في المرحلة 0 | 🟡 = الجدول يُنشأ في المرحلة 0 لكن الاستخدام الكامل يبدأ بالمرحلة 1 (لتفادي إعادة التصميم لاحقًا).

2.1 🟢 tenants — المنشأة/الحساب التجاري
الحقل	النوع	القيود	الوصف
id	UUID	PK	
business_name	VARCHAR(150)	NOT NULL	اسم النشاط
business_type_code	VARCHAR(30)	FK → business_types.code	retail / clinic / workshop / law_office / service_office
base_currency_code	VARCHAR(3)	FK → currencies.code	العملة الأساسية (افتراضي YER)
country_code	VARCHAR(2)	DEFAULT 'YE'	
timezone	VARCHAR(50)	DEFAULT 'Asia/Aden'	
fiscal_year_start_month	SMALLINT	DEFAULT 1	
owner_user_id	UUID	FK → users.id	مالك الحساب
phone	VARCHAR(20)		
address	TEXT	NULL	
logo_url	TEXT	NULL	
onboarding_status	VARCHAR(20)	DEFAULT 'pending'	pending / in_progress / completed
settings	JSONB	DEFAULT '{}'	إعدادات مرنة (وضع مبسّط/احترافي، إلخ)
is_active	BOOLEAN	DEFAULT TRUE	يُستخدم للإيقاف من لوحة المنصة
+ الأعمدة القياسية			
فهارس: UNIQUE(phone), INDEX(business_type_code)

2.2 🟢 users — المستخدمون (عبر كل المنصة)
الحقل	النوع	القيود	الوصف
id	UUID	PK	
full_name	VARCHAR(150)	NOT NULL	
phone	VARCHAR(20)	UNIQUE NOT NULL	أساس تسجيل الدخول في اليمن
email	VARCHAR(150)	NULL UNIQUE	اختياري
password_hash	VARCHAR(255)	NOT NULL	Argon2id
pin_hash	VARCHAR(255)	NULL	للدخول السريع دون اتصال على الجهاز
is_platform_admin	BOOLEAN	DEFAULT FALSE	مالك المنصة/فريقها
two_fa_enabled	BOOLEAN	DEFAULT FALSE	
two_fa_secret	VARCHAR(255)	NULL، مشفّر	TOTP Secret
locale	VARCHAR(10)	DEFAULT 'ar-YE'	
last_login_at	TIMESTAMPTZ	NULL	
is_active	BOOLEAN	DEFAULT TRUE	
+ الأعمدة القياسية (عدا tenant_id)			المستخدم عابر للمستأجرين
2.3 🟢 tenant_users — ربط المستخدم بالمنشأة والدور
الحقل	النوع	القيود
id	UUID	PK
tenant_id	UUID	FK
user_id	UUID	FK
role_id	UUID	FK → roles.id
status	VARCHAR(20)	invited / active / suspended
invited_by_user_id	UUID	NULL
joined_at	TIMESTAMPTZ	NULL
+ الأعمدة القياسية		
فهارس: UNIQUE(tenant_id, user_id)

2.4 🟢 roles و permissions و role_permissions
roles

الحقل	النوع	ملاحظات
id	UUID	PK
tenant_id	UUID	NULL للأدوار النظامية الافتراضية (مشتركة)
name	VARCHAR(50)	مالك، مدير، محاسب، بائع، أمين مخزن، أمين صندوق
is_system_role	BOOLEAN	أدوار افتراضية لا تُحذف
+ الأعمدة القياسية		
permissions (جدول مرجعي ثابت يُزرع عبر Seed، لا يُنشأ من التطبيق)

الحقل	النوع	مثال
id	UUID	PK
code	VARCHAR(100) UNIQUE	journal.create_manual, accounts.manage, reports.view_profit, devices.revoke
module	VARCHAR(50)	accounting / inventory / reports / settings
description_ar	TEXT	
role_permissions

| role_id | permission_id | (PK مركّب) |

2.5 🟢 devices — إدارة الأجهزة
الحقل	النوع	القيود	الوصف
id	UUID	PK	بصمة الجهاز (Device Fingerprint)
tenant_id	UUID	FK	
registered_by_user_id	UUID	FK	
device_name	VARCHAR(100)		"هاتف المحل - سامسونج"
platform	VARCHAR(20)	DEFAULT 'android'	
app_version	VARCHAR(20)		
push_token	TEXT	NULL	FCM Token
first_registered_at	TIMESTAMPTZ	NOT NULL	يتطلب اتصالًا بالإنترنت
last_seen_at	TIMESTAMPTZ		
last_sync_at	TIMESTAMPTZ	NULL	
is_active	BOOLEAN	DEFAULT TRUE	يُستخدم لإلغاء جهاز مفقود
revoked_at	TIMESTAMPTZ	NULL	
revoked_by_user_id	UUID	NULL	
قيد منطقي (Application-level): عدد devices النشطة لكل tenant_id ≤ max_devices في باقته.

2.6 🟢 auth_sessions — جلسات الدخول (Refresh Tokens)
الحقل	النوع	ملاحظات
id	UUID	PK
user_id	UUID	FK
device_id	UUID	FK
refresh_token_hash	VARCHAR(255)	مخزّن مُجزّأ (hashed) لا نصًا صريحًا
access_token_jti	VARCHAR(100)	لإبطال التوكنات عند الحاجة
expires_at	TIMESTAMPTZ	
revoked_at	TIMESTAMPTZ	NULL
created_at	TIMESTAMPTZ	
2.7 🟢 currencies (جدول مرجعي ثابت)
الحقل	النوع
code	VARCHAR(3) PK — YER, SAR, USD
name_ar	VARCHAR(50)
symbol	VARCHAR(10)
decimal_places	SMALLINT DEFAULT 2
2.8 🟢 tenant_currencies
الحقل	النوع	ملاحظات
id	UUID	PK
tenant_id	UUID	FK
currency_code	VARCHAR(3)	FK
is_base	BOOLEAN	عملة أساسية واحدة فقط لكل Tenant
is_enabled	BOOLEAN	DEFAULT TRUE
enabled_by_user_id	UUID	
قيد: UNIQUE(tenant_id, currency_code) و Trigger يضمن is_base = TRUE لسجل واحد فقط لكل Tenant.

2.9 🟢 exchange_rates
الحقل	النوع	ملاحظات
id	UUID	PK
tenant_id	UUID	FK
from_currency_code	VARCHAR(3)	
to_currency_code	VARCHAR(3)	غالبًا = العملة الأساسية
rate	DECIMAL(18,6)	NOT NULL، > 0
rate_date	DATE	NOT NULL
source	VARCHAR(20)	manual | api
created_by_user_id	UUID	
+ الأعمدة القياسية		
فهرس: UNIQUE(tenant_id, from_currency_code, to_currency_code, rate_date)
منطق التطبيق: عند عدم وجود سعر لليوم، يُستخدم آخر سعر مُدخَل سابقًا (Last Known Rate)، مع تنبيه للمستخدم أنه سعر قديم.

2.10 🟢 account_types (جدول مرجعي ثابت)
الحقل	النوع
id	SMALLINT PK
code	VARCHAR(20) — asset, liability, equity, revenue, expense
name_ar	VARCHAR(50)
normal_balance	VARCHAR(10) — debit | credit
2.11 🟢 accounts — شجرة الحسابات
الحقل	النوع	القيود	الوصف
id	UUID	PK	
tenant_id	UUID	FK	
parent_account_id	UUID	FK → accounts.id، NULL	للتسلسل الهرمي
account_type_id	SMALLINT	FK	
code	VARCHAR(20)	NOT NULL	رقم الحساب (يُولَّد تلقائيًا حسب نمط الشجرة)
name_ar_simple	VARCHAR(100)	NOT NULL	الاسم المبسّط المعروض لغير المحاسب ("الصندوق")
name_technical	VARCHAR(150)	NULL	الاسم الفني ("النقدية بالصندوق الرئيسي")
is_system_account	BOOLEAN	DEFAULT FALSE	لا يُحذف (الصندوق الرئيسي، رأس المال...)
is_control_account	BOOLEAN	DEFAULT FALSE	حساب مجمّع (مثل "العملاء") له حسابات مساعدة عبر contacts
linked_contact_id	UUID	FK → contacts.id، NULL	الحساب المساعد الفردي
currency_code	VARCHAR(3)	NULL	إن كان الحساب مرتبطًا بعملة محددة (بنك دولاري مثلًا)
is_active	BOOLEAN	DEFAULT TRUE	
+ الأعمدة القياسية			
فهارس: UNIQUE(tenant_id, code)، INDEX(tenant_id, parent_account_id)

2.12 🟡 contacts — الأطراف (عملاء/موردون/موظفون) — جدول أساسي يُنشأ الآن، CRUD الكامل في المرحلة 1
الحقل	النوع	ملاحظات
id	UUID	PK
tenant_id	UUID	FK
contact_type	VARCHAR(20)	customer | supplier | employee | other
full_name	VARCHAR(150)	NOT NULL (ثلاثي)
phone	VARCHAR(20)	NULL
address	TEXT	NULL
credit_limit_amount	DECIMAL(18,4)	NULL
credit_limit_currency	VARCHAR(3)	NULL
linked_account_id	UUID	FK → accounts.id — يُنشأ تلقائيًا حساب مساعد عند إنشاء الطرف
opening_balance_amount	DECIMAL(18,4)	DEFAULT 0
opening_balance_side	VARCHAR(10)	debit | credit
notes	TEXT	NULL
is_active	BOOLEAN	DEFAULT TRUE
+ الأعمدة القياسية		
2.13 🟢 journal_entries — رأس القيد
الحقل	النوع	القيود	الوصف
id	UUID	PK	
tenant_id	UUID	FK	
entry_number_display	VARCHAR(30)		رقم عرضي يُشكَّل بعد المزامنة (بادئة جهاز + تسلسل)
entry_date	DATE	NOT NULL	
description_simple	TEXT	NOT NULL	الوصف المبسّط ("بعت للعميل أحمد")
source_type	VARCHAR(30)	NOT NULL	manual / sale / purchase... (يتسع في المرحلة 1)
source_transaction_id	UUID	NULL	FK → transactions.id (🟡 يُفعَّل بالمرحلة 1)
reversal_of_entry_id	UUID	NULL، FK self	للقيود العكسية
is_reversed	BOOLEAN	DEFAULT FALSE	
status	VARCHAR(20)	DEFAULT 'posted'	posted دائمًا فور الإنشاء (لا Draft في القيد الفني)
base_currency_code	VARCHAR(3)	NOT NULL	عملة الـ Tenant وقت الترحيل
is_locked	BOOLEAN	DEFAULT FALSE	بعد إقفال الفترة (مرحلة لاحقة)
+ الأعمدة القياسية			
فهارس: INDEX(tenant_id, entry_date)، UNIQUE(tenant_id, entry_number_display) (تُبنى بعد المزامنة فقط)

2.14 🟢 journal_lines — بنود القيد
الحقل	النوع	القيود	الوصف
id	UUID	PK	
journal_entry_id	UUID	FK NOT NULL	
account_id	UUID	FK NOT NULL	
contact_id	UUID	NULL، FK	ربط مباشر بحساب مساعد
debit_amount	DECIMAL(18,4)	DEFAULT 0، ≥ 0	بعملة السطر
credit_amount	DECIMAL(18,4)	DEFAULT 0، ≥ 0	
currency_code	VARCHAR(3)	NOT NULL	
exchange_rate_used	DECIMAL(18,6)	NOT NULL	سعر الصرف وقت الإنشاء (مثبّت)
base_debit_amount	DECIMAL(18,4)	محسوب	= debit × rate
base_credit_amount	DECIMAL(18,4)	محسوب	= credit × rate
line_order	SMALLINT		
memo	TEXT	NULL	
قيود إلزامية (DB-level):

SQL

CHECK (NOT (debit_amount > 0 AND credit_amount > 0))  -- السطر إما مدين أو دائن لا الاثنان
قيد على مستوى القيد الكامل (Trigger مؤجَّل - Deferred Constraint في Postgres):

SQL

-- بعد كل إدراج/تعديل على journal_lines ضمن نفس المعاملة:
ASSERT SUM(base_debit_amount) = SUM(base_credit_amount)
WHERE journal_entry_id = :id
-- يُنفَّذ عند COMMIT، لا عند كل سطر منفرد
هذا هو القيد الأهم في كامل النظام ويجب تطبيقه في طبقتين: (1) التطبيق قبل الإرسال، (2) قاعدة البيانات كخط دفاع أخير.

2.15 🟡 business_types (جدول مرجعي ثابت)
الحقل	النوع	مثال
code	VARCHAR(30) PK	retail, clinic, workshop, law_office, service_office
name_ar	VARCHAR(50)	
default_accounts_seed_key	VARCHAR(50)	يشير لملف Seed محدد لشجرة الحسابات الافتراضية
2.16 🟡 transactions (يُفعَّل كامل منطقه بالمرحلة 1، الجدول يُنشأ الآن)
الحقل	النوع	ملاحظات
id	UUID	PK
tenant_id	UUID	FK
template_code	VARCHAR(50)	sale_cash, purchase_credit...
transaction_date	DATE	
amount	DECIMAL(18,4)	
currency_code	VARCHAR(3)	
contact_id	UUID	NULL
status	VARCHAR(20)	draft / confirmed / reversed
payload	JSONB	كل حقول القالب كما أدخلها المستخدم
journal_entry_id	UUID	FK → journal_entries.id
+ الأعمدة القياسية		
2.17 🟢 audit_log
الحقل	النوع
id	UUID PK
tenant_id	UUID
user_id	UUID
device_id	UUID
entity_type	VARCHAR(50)
entity_id	UUID
action	VARCHAR(30) — create/update/reverse/login/revoke_device
old_value	JSONB NULL
new_value	JSONB NULL
created_at	TIMESTAMPTZ
قيد: الجدول Append-only، لا UPDATE ولا DELETE مسموح على الإطلاق (يُفرض بصلاحيات قاعدة البيانات نفسها).

2.18 🟢 event_log — سجل أحداث المزامنة
الحقل	النوع	ملاحظات
id	UUID	PK = نفس event_id من الجهاز
tenant_id	UUID	
device_id	UUID	
entity_type	VARCHAR(50)	
entity_id	UUID	
operation	VARCHAR(10)	insert/update (لا delete فعلي)
payload	JSONB	كامل الصف بعد التغيير
lamport_clock	BIGINT	
occurred_at	TIMESTAMPTZ	وقت الجهاز
server_received_at	TIMESTAMPTZ	وقت الخادم
sync_status	VARCHAR(20)	synced/conflict
2.19 🟡 subscription_plans و subscriptions
subscription_plans (مرجعي، Seed يدوي من لوحة المنصة)

| id, code (free/plus/pro), name_ar, max_devices, ai_monthly_quota, price_amount, price_currency, features (JSONB) |

subscriptions

| id, tenant_id, plan_id, status (trial/active/expired/suspended), trial_ends_at, current_period_end, + الأعمدة القياسية |

تفصيل تكامل الدفع عبر المحافظ يُؤجَّل لمواصفات API المرحلة 3، لكن الجدول يُنشأ الآن حتى يكون tenant.subscription_plan_id متاحًا منذ البداية (باقة free افتراضية لكل حساب جديد).

3. الفهارس والقيود الموصى بها (أداء احترافي)
الجدول	الفهرس	السبب
journal_lines	INDEX(account_id, tenant_id)	تسريع كشف الحساب
journal_entries	INDEX(tenant_id, entry_date DESC)	تسريع تقارير الفترات
event_log	INDEX(tenant_id, lamport_clock)	أساس عملية Pull للمزامنة
event_log	INDEX(device_id, occurred_at)	تتبع نشاط الجهاز
accounts	INDEX(tenant_id, account_type_id)	بناء التقارير المالية
contacts	INDEX(tenant_id, contact_type, phone)	البحث السريع عند الإضافة من شاشة الشراء/البيع
توصية للتوسع (5 مليون مستخدم):

تقسيم (Partitioning) جدولي journal_lines وevent_log في PostgreSQL بحسب created_at (شهريًا) لأنهما الأسرع نموًا.
عزل منطقي صارم بـ tenant_id في كل استعلام (Row-Level Security في PostgreSQL) كخط دفاع إضافي ضد تسرب بيانات بين التجار.
