claude-sonnet-5-high
مخطط قاعدة البيانات التفصيلي (ERD) ومواصفات API
المرحلة 0 — الأساس والبنية
0. معايير التصميم العامة (Design Conventions)
هذه القواعد تُطبَّق على كل الجداول ما لم يُذكر خلاف ذلك، وهي ضرورية لأن النظام يعمل بمبدأ Local-first (SQLite على الجهاز) مع مزامنة لاحقة إلى خادم مركزي (PostgreSQL).

0.1 الأعمدة القياسية (Standard Audit Columns)
تُضاف تلقائيًا لكل جدول "قابل للمزامنة" (أي كل الجداول عدا الجداول المرجعية الثابتة كـ currencies):

العمود	النوع	الوصف
id	UUID	يُولَّد على الجهاز نفسه (Client-generated UUIDv4) وليس من الخادم — ضرورة حتمية للعمل دون اتصال
tenant_id	UUID (FK)	عزل البيانات بين المستأجرين (Multi-tenancy)
created_at	TIMESTAMPTZ	وقت الإنشاء بساعة الجهاز المصدر
updated_at	TIMESTAMPTZ	آخر تعديل
created_by_user_id	UUID (FK users)	
updated_by_user_id	UUID (FK users)	
origin_device_id	UUID (FK devices)	الجهاز الذي أنشأ السجل أصلًا
lamport_clock	BIGINT	عداد منطقي تصاعدي لكل Tenant لحل ترتيب الأحداث عند تعارض المزامنة
is_deleted	BOOLEAN DEFAULT FALSE	حذف منطقي فقط (Soft Delete) — لا حذف فعلي أبدًا
sync_status	TEXT CHECK IN ('pending','synced','conflict')	حالة مزامنة السجل محليًا (موجود في نسخة SQLite فقط، لا يُرسَل للخادم)
0.2 قرارات تصميمية أساسية
القرار	السبب
UUID بدل Auto-Increment	يمنع تعارض المفاتيح عند الإنشاء من عدة أجهزة دون اتصال
لا حذف فعلي (Hard Delete) أبدًا للبيانات المالية	يحافظ على الأثر المحاسبي والتدقيق
كل مبلغ مالي = (قيمة + عملة + سعر صرف + معادل بالعملة الأساسية)	ضرورة فرضها هندسيًا منذ البداية بسبب تعدد العملات في اليمن
القيد (Journal) غير قابل للتعديل بعد الترحيل (Immutable)	التصحيح فقط عبر قيد عكسي مرتبط
فصل Transaction (واجهة سهلة) عن JournalEntry (قيد فني)	يتيح تبسيط الواجهة دون المساس بصحة المحاسبة
ENUM كجداول مرجعية أو CHECK constraints	SQLite لا يدعم ENUM أصلًا؛ الجدول المرجعي يسهّل الإضافة لاحقًا دون Migration


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
