4. مواصفات API — المرحلة 0
4.1 القواعد العامة
البند	القيمة
Base URL	https://api.platform.ye/v1
Auth Scheme	Authorization: Bearer <access_token> (JWT، RS256، صلاحية 15 دقيقة)
Refresh	Refresh Token صلاحية 30 يوم، مربوط بـ device_id، دوّار (Rotation) عند كل استخدام
ترويسات إلزامية	X-Device-Id, Accept-Language: ar, Idempotency-Key (لكل عمليات الكتابة)
صيغة الاستجابة الناجحة	{ "data": {...}, "meta": {...} }
صيغة الخطأ	{ "error": { "code": "...", "message": "...", "details": [...] } }
الترقيم (Pagination)	?page=&limit= للقوائم العادية، Cursor-based (since_clock) لنقاط المزامنة
الأمان	TLS 1.2+ إلزامي، تشفير الحقول الحساسة في قاعدة البيانات (secrets)
4.2 رموز الأخطاء الموحّدة
الكود	الحالة HTTP	الوصف
VALIDATION_ERROR	422	فشل التحقق من الحقول
UNAUTHORIZED	401	توكن غير صالح/منتهٍ
FORBIDDEN	403	لا صلاحية
DEVICE_LIMIT_EXCEEDED	403	تجاوز عدد الأجهزة المسموح بالباقة
JOURNAL_UNBALANCED	422	القيد غير متوازن (لا يجب أن يصل هنا أصلًا لو التحقق المحلي سليم)
IDEMPOTENT_REPLAY	200	الطلب مكرر، أُعيد نفس النتيجة السابقة
CONFLICT	409	تعارض إصدار بيانات
RATE_LIMITED	429	تجاوز الحد المسموح من الطلبات
4.3 نقاط النهاية — المصادقة والهوية
POST /auth/register
إنشاء حساب مالك + منشأة جديدة (أول تسجيل، يتطلب اتصالًا دومًا).

Request:

JSON

{
  "full_name": "محمد علي أحمد",
  "phone": "7xxxxxxxx",
  "password": "********",
  "business_name": "بقالة الأمل",
  "business_type_code": "retail",
  "base_currency_code": "YER",
  "device": {
    "device_name": "هاتف المحل",
    "platform": "android",
    "app_version": "1.0.0"
  }
}
Response 201:

JSON

{
  "data": {
    "tenant": { "id": "uuid", "business_name": "بقالة الأمل", "onboarding_status": "pending" },
    "user": { "id": "uuid", "full_name": "محمد علي أحمد" },
    "device": { "id": "uuid", "is_active": true },
    "tokens": { "access_token": "...", "refresh_token": "...", "expires_in": 900 }
  }
}
POST /auth/login
JSON

{ "phone": "7xxxxxxxx", "password": "********", "device_id": "uuid-إن-وُجد-مسبقًا" }
إن كان device_id جديدًا، يُطبَّق فحص حد الأجهزة فورًا، ويُرجع DEVICE_LIMIT_EXCEEDED عند التجاوز مع اقتراح الترقية.

POST /auth/refresh
JSON

{ "refresh_token": "..." }
POST /auth/2fa/enable و POST /auth/2fa/verify
لتفعيل TOTP لحساب المالك والمدير (إلزامي لهما، اختياري للبقية).

ملاحظة تصميمية مهمة: الدخول بـ PIN لا يمر عبر API إطلاقًا — يُتحقَّق محليًا من pin_hash المخزَّن مشفّرًا على الجهاز نفسه، وهذا ما يحقق "مهلة الدخول دون نت المفتوحة".

4.4 نقاط النهاية — إدارة الأجهزة
Method	Path	الوصف
POST	/devices/register	تسجيل جهاز إضافي لحساب موجود (يتطلب نتًا مرة واحدة)
GET	/devices	قائمة أجهزة المنشأة
PATCH	/devices/{id}/revoke	إلغاء جهاز (صلاحية المالك فقط)
Response نموذج GET /devices:

JSON

{
  "data": [
    { "id": "uuid", "device_name": "هاتف المحل", "last_seen_at": "...", "is_active": true },
    { "id": "uuid", "device_name": "هاتف المحاسب", "last_seen_at": "...", "is_active": true }
  ],
  "meta": { "max_devices": 3, "active_count": 2 }
}
4.5 نقاط النهاية — المستخدمون والصلاحيات
Method	Path	الوصف
POST	/tenant/users/invite	دعوة مستخدم برقم هاتف ودور
GET	/tenant/users	قائمة مستخدمي المنشأة وأدوارهم
PATCH	/tenant/users/{id}/role	تغيير الدور
DELETE	/tenant/users/{id}	إيقاف عضوية (ليس حذف المستخدم نفسه)
GET	/roles	الأدوار المتاحة (نظامية + مخصصة)
GET	/permissions	كل الصلاحيات المتاحة لبناء دور مخصص
4.6 نقاط النهاية — الإعداد الأول (Onboarding)
Method	Path	الوصف
GET	/business-types	القائمة: retail/clinic/workshop/law_office/service_office
POST	/onboarding/select-business-type	يُفعِّل Seed شجرة الحسابات المناسبة
POST	/onboarding/seed-chart-of-accounts	تنفيذ الزرع الفعلي للحسابات الافتراضية
POST	/onboarding/complete	إنهاء المعالج (onboarding_status = completed)
4.7 نقاط النهاية — العملات وسعر الصرف
Method	Path	الوصف
GET	/currencies	القائمة الثابتة (YER/SAR/USD)
GET	/tenant/currencies	العملات المفعّلة للمنشأة
POST	/tenant/currencies	تفعيل عملة إضافية (SAR أو USD)
PATCH	/tenant/currencies/{code}	تعطيل/تفعيل
GET	/exchange-rates/latest?currency=SAR	آخر سعر مُدخَل
POST	/exchange-rates	إدخال سعر يدوي ليوم محدد
Request نموذج POST /exchange-rates:

JSON

{
  "from_currency_code": "SAR",
  "to_currency_code": "YER",
  "rate": 135.50,
  "rate_date": "2025-01-15",
  "source": "manual"
}
المصدر المرجعي (API) الخارجي: يُضاف لاحقًا كـ source: "api" عبر Job مجدول على الخادم يملأ الجدول نفسه، دون تغيير في العقد (Contract) الظاهر للتطبيق — توافقًا مع مبدأ "الإضافة عند الحاجة" الذي حددته.

4.8 نقاط النهاية — شجرة الحسابات
Method	Path	الوصف
GET	/accounts?flat=false	شجرة هرمية (افتراضي)
GET	/accounts?flat=true&type=asset	قائمة مسطّحة مفلترة
POST	/accounts	إنشاء حساب (صلاحية المحاسب/المالك فقط)
PATCH	/accounts/{id}	تعديل اسم/حالة
DELETE	/accounts/{id}	حذف منطقي، مرفوض إن كان is_system_account=true أو له حركات
Response نموذج GET /accounts:

JSON

{
  "data": [
    {
      "id": "uuid", "code": "1000", "name_ar_simple": "الأصول", "account_type": "asset",
      "children": [
        { "id": "uuid", "code": "1010", "name_ar_simple": "الصندوق", "is_system_account": true },
        { "id": "uuid", "code": "1020", "name_ar_simple": "العملاء", "is_control_account": true }
      ]
    }
  ]
}
4.9 نقاط النهاية — محرك القيد (الجوهر)
POST /journal-entries
يُستخدم من المحاسب مباشرة (قيد يدوي)، أو داخليًا من محرك القوالب في المرحلة 1.

Request:

JSON

{
  "entry_date": "2025-01-15",
  "description_simple": "تسوية يدوية - تصحيح رصيد افتتاحي",
  "source_type": "manual",
  "lines": [
    {
      "account_id": "uuid-الصندوق",
      "debit_amount": 50000,
      "credit_amount": 0,
      "currency_code": "YER",
      "exchange_rate_used": 1
    },
    {
      "account_id": "uuid-رأس-المال",
      "debit_amount": 0,
      "credit_amount": 50000,
      "currency_code": "YER",
      "exchange_rate_used": 1
    }
  ]
}
التحقق قبل القبول (Server-side):

SUM(debit) == SUM(credit) بالعملة الأساسية → وإلا 422 JOURNAL_UNBALANCED.
كل account_id ينتمي لنفس tenant_id.
لا سطر فيه مدين ودائن معًا.
Response 201:

JSON

{ "data": { "id": "uuid", "entry_number_display": "JE-D1-000045", "status": "posted" } }
POST /journal-entries/{id}/reverse
JSON

{ "reason": "خطأ في المبلغ المُدخَل" }
ينشئ قيدًا جديدًا بعكس كل الأسطر، ويربطه بـ reversal_of_entry_id، ويضع is_reversed=true على الأصلي.

GET /journal-entries?date_from=&date_to=&account_id=
لعرض دفتر اليومية وكشف الحساب (أساس تقارير المرحلة لاحقًا).

4.10 نقاط النهاية — المزامنة (الأهم هندسيًا)
POST /sync/push
الجهاز يرسل كل الأحداث المتراكمة محليًا منذ آخر مزامنة ناجحة.

Request:

JSON

{
  "device_id": "uuid",
  "events": [
    {
      "event_id": "uuid-ثابت-من-الجهاز",
      "entity_type": "journal_entry",
      "entity_id": "uuid",
      "operation": "insert",
      "lamport_clock": 1023,
      "occurred_at": "2025-01-15T10:22:00Z",
      "payload": { "...الصف الكامل..." }
    }
  ]
}
معالجة الخادم (إلزامية الترتيب):

التحقق من Idempotency: إن كان event_id موجودًا مسبقًا → تجاهل بأمان وأعد النتيجة السابقة.
تطبيق التحقق من توازن القيد إن كان entity_type = journal_entry.
تخزين الحدث في event_log وتحديث الجدول الفعلي (journal_entries/journal_lines/إلخ) ضمن معاملة واحدة (Transaction).
تحديث last_sync_at وlast_seen_at للجهاز.
Response:

JSON

{
  "data": {
    "accepted": ["event_id_1"],
    "rejected": [],
    "server_lamport_clock": 5421
  }
}
GET /sync/pull?since_clock=1020&limit=500
الجهاز يطلب كل ما استجد من الأجهزة الأخرى لنفس الحساب.

Response:

JSON

{
  "data": {
    "events": [ { "event_id": "...", "entity_type": "...", "payload": {...} } ],
    "next_since_clock": 1540,
    "has_more": false
  }
}
لماذا Push/Pull منفصلان لا Full Sync؟ لأن الحجم ينمو مع الوقت؛ الفصل يتيح مزامنة تفاضلية خفيفة تناسب جودة الإنترنت المتذبذبة في اليمن ويقلل استهلاك الباقة.

4.11 نقاط النهاية — سجل التدقيق
Method	Path	الوصف
GET	/audit-logs?entity_type=&entity_id=&date_from=&date_to=	قراءة فقط، صلاحية المالك/المحاسب
4.12 نقاط النهاية — لوحة مالك المنصة (نطاق منفصل)
Method	Path	الوصف
GET	/admin/tenants?status=	قائمة كل المنشآت
PATCH	/admin/tenants/{id}/suspend	إيقاف منشأة
GET	/admin/tenants/{id}	تفاصيل ومقاييس استخدام
تُخدَم عبر Base URL منفصل منطقيًا /admin/v1 بصلاحيات is_platform_admin=true فقط، وبـ 2FA إلزامي دون استثناء.

5. تسلسل تنفيذي نموذجي (Sequence) — للتوثيق الهندسي
سيناريو: تسجيل دخول تاجر على جهاز ثانٍ لأول مرة

POST /auth/login (يتطلب نتًا) → الخادم يتحقق من كلمة المرور.
الخادم يتحقق: عدد الأجهزة النشطة الحالي < max_devices في subscriptions.plan؟
نعم → POST /devices/register ضمنيًا، يُعاد tokens.
لا → 403 DEVICE_LIMIT_EXCEEDED مع رابط ترقية الباقة.
التطبيق يحفظ access_token/refresh_token ويُنشئ pin_hash محليًا لدخول لاحق دون نت.
التطبيق يستدعي GET /sync/pull?since_clock=0 لتحميل كامل بيانات الحساب للمرة الأولى.
من الآن فصاعدًا: الدخول اليومي عبر PIN محلي بلا أي استدعاء شبكة.
6. خلاصة وتوصيات هذه المرحلة
ابدأ ببناء وباختبار محرك journal_lines balance constraint قبل أي واجهة — هو نقطة الفشل الأخطر ماليًا إن أُهملت.
اختبر sync/push وsync/pull بسيناريوهات فوضوية فعلية (انقطاع منتصف الإرسال، إعادة إرسال نفس الحدث، ساعتان مختلفتا الإعدادات بين جهازين) قبل الانتقال للمرحلة 1.
لا تؤجل tenant_currencies وexchange_rates رغم أن الاستخدام الفعلي المكثف يبدأ بالمرحلة 1 — ربطهما ببنية journal_lines منذ الآن يوفر إعادة تصميم مكلفة لاحقًا.
أنشئ جداول contacts, transactions, business_types, subscriptions الآن فارغة الوظيفة لكن جاهزة البنية — هذا "Forward-Compatible Schema" يسرّع المرحلة 1 بشكل كبير.
اعتمد Row-Level Security في PostgreSQL على tenant_id من اليوم الأول كخط دفاع إضافي، لا تتركه لمراجعة لاحقة.
اكتب Seed Data script لكل business_type (شجرة حسابات افتراضية مختلفة قليلًا لكل من: تجزئة، عيادة، ورشة، محاماة، مكتب خدمات) كملفات JSON منفصلة عن الكود — يسهّل التعديل دون نشر إصدار جديد.
الخطوة التالية المقترحة: تصميم ملفات Seed لشجرة الحسابات الافتراضية لكل نوع نشاط (5 ملفات JSON)، أو الانتقال لتصميم Wireframes شاشات المرحلة 0 (تسجيل الدخول، معالج الإعداد الأول، شاشة شجرة الحسابات) — حدد أيهما تريد أولًا.




البدء بتصميم مخطط قاعدة البيانات التفصيلي (ERD كامل بالحقول) ومواصفات API للمرحلة 0، وبأفضل الممارسات والأساليب وبأداء احترافي بجودة عالية.
