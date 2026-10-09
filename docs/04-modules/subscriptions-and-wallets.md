claude-sonnet-5-high
تصميم وحدة الاشتراكات والدفع عبر المحافظ الإلكترونية اليمنية
(Subscription & Yemeni Mobile Wallet Payment Module)
0. قرارات تصميمية وتصحيحات ضرورية قبل البدء
0.1 المشكلة الجوهرية: تعدد مزودي المحافظ وتفاوت نضج واجهاتهم البرمجية
السوق اليمني يضم عدة محافظ إلكترونية (كريمي، جوالي، فلوسك، جيب، ون كاش وغيرها) بمستويات تقنية متفاوتة — بعضها يوفر Webhook فوري، وبعضها لا يوفر سوى تحقق بالاستعلام عن رقم العملية (Reference Number) الذي يحصل عليه المستخدم من تطبيق المحفظة نفسه. تصميم يعتمد على Webhook فقط سيفشل مع بعض المزودين.

الحل المعتمد: طبقة تجريد Payment Provider Interface تدعم نمطين معًا:

النمط	الآلية	الاستخدام
Push (فوري)	المزود يرسل Webhook موقّعًا عند نجاح الدفع	المزودون ذوو API ناضج
Pull (تحقق بالمرجع)	التاجر يدفع عبر تطبيق محفظته، يُدخل رقم العملية في منصتنا، والخادم يستعلم عنه من API المزود للتحقق	المزودون محدودو التكامل، أو كخطة بديلة دائمًا
0.2 مبدأ أمني غير قابل للتفاوض (مكرر ومؤكد من تصميم API السابق)
لا تُفعَّل أي باقة بناءً على تأكيد من واجهة المستخدم فقط. التفعيل التلقائي المطلوب يعني "تلقائي بعد تحقق خادمي موثوق"، لا "فوري بلا تحقق". كل دفعة تمر بحالة pending حتى يُؤكِّدها الخادم عبر Webhook موقّع أو استعلام مباشر ناجح من API المزود.

0.3 تصميم قابل للتوسع الإقليمي من اليوم الأول
بما أن التوسع للوطن العربي "بحسب الطرق المعتادة" (بطاقات، Apple Pay، مدى...) مخطط له لاحقًا، فإن نفس واجهة PaymentProviderInterface يجب أن تستوعب مزودين مستقبليين (Stripe، Tap، PayTabs) دون أي تعديل في منطق الاشتراكات نفسه — الفرق فقط في "Adapter" التنفيذ.

0.4 إضافة ضرورية: ربط استهلاك الذكاء الاصطناعي بالباقة فعليًا
من النقاشات السابقة، كان "عداد استهلاك AI" مذكورًا نظريًا. هذه الوحدة تُفعِّله فعليًا كجزء لا يتجزأ من محرك الاشتراك.

1. مخطط العلاقات (ERD)
mermaid

erDiagram
    SUBSCRIPTION_PLANS ||--o{ SUBSCRIPTIONS : "defines"
    TENANTS ||--o{ SUBSCRIPTIONS : "has"
    SUBSCRIPTIONS ||--o{ SUBSCRIPTION_EVENTS : "logs"
    PAYMENT_PROVIDERS ||--o{ PAYMENT_TRANSACTIONS : "processes"
    TENANTS ||--o{ PAYMENT_TRANSACTIONS : "initiates"
    SUBSCRIPTIONS ||--o{ PAYMENT_TRANSACTIONS : "paid_via"
    PAYMENT_TRANSACTIONS ||--o{ PAYMENT_WEBHOOK_LOGS : "receives"
    TENANTS ||--o{ AI_USAGE_LOG : "consumes"
    TENANTS ||--o{ AI_PROVIDER_CONFIGS : "configures"
    PLATFORM_AI_PROVIDERS ||--o{ AI_PROVIDER_CONFIGS : "based_on"
2. تفصيل الجداول حقلًا حقلًا
2.1 🟢 subscription_plans (تطوير على التصميم السابق)
الحقل	النوع	القيود	الوصف
code	VARCHAR(20)	UNIQUE	free / plus / pro
name_ar	VARCHAR(50)		
max_devices	SMALLINT	NOT NULL	1 / 3 / 10
ai_monthly_quota	INTEGER	NULL = غير محدود	عدد طلبات الذكاء الاصطناعي شهريًا
advanced_reports_enabled	BOOLEAN		يتحكم بظهور تقارير category=financial المتقدمة
price_amount	DECIMAL(10,2)		
price_currency	VARCHAR(3)	DEFAULT 'YER'	
billing_cycle	VARCHAR(10)	DEFAULT 'monthly'	monthly / yearly (خصم للسنوي لاحقًا)
trial_days	SMALLINT	DEFAULT 0	7-14 لباقة pro فقط
sort_order	SMALLINT		
is_active	BOOLEAN	DEFAULT TRUE	يسمح بإخفاء باقة دون حذفها
2.2 🟢 subscriptions
الحقل	النوع	القيود	الوصف
tenant_id	UUID	FK UNIQUE	اشتراك واحد نشط لكل Tenant
plan_id	UUID	FK NOT NULL	
status	VARCHAR(20)	NOT NULL	انظر آلة الحالات (قسم 4)
trial_ends_at	TIMESTAMPTZ	NULL	
current_period_start	DATE	NOT NULL	
current_period_end	DATE	NOT NULL	
grace_period_ends_at	TIMESTAMPTZ	NULL	مهلة بعد الانتهاء قبل التجميد الكامل
pending_plan_id	UUID	FK NULL	ترقية/تخفيض مجدول لبداية الفترة القادمة
auto_renew	BOOLEAN	DEFAULT TRUE	
cancelled_at	TIMESTAMPTZ	NULL	
cancellation_reason	TEXT	NULL	
فهرس: UNIQUE(tenant_id) — تحقيقًا لمبدأ اشتراك واحد نشط فقط.

2.3 subscription_events — سجل تدقيق دورة حياة الاشتراك
الحقل	النوع	الوصف
subscription_id	UUID FK	
event_type	VARCHAR(30)	trial_started / activated / upgraded / downgraded / renewed / payment_failed / suspended / cancelled / reopened
from_plan_code	VARCHAR(20)	NULL
to_plan_code	VARCHAR(20)	NULL
triggered_by	VARCHAR(20)	system / user / platform_admin
metadata	JSONB	
2.4 🟢 payment_providers — إعدادات مزودي الدفع (مستوى المنصة)
الحقل	النوع	الوصف
code	VARCHAR(30) UNIQUE	kuraimi, jawali, floosak, jaib, onecash...
display_name_ar	VARCHAR(50)	
country_code	VARCHAR(2)	YE (ويتوسع لاحقًا)
integration_mode	VARCHAR(10)	push (Webhook) | pull (تحقق بالمرجع) | hybrid
adapter_class	VARCHAR(100)	اسم الكلاس المنفِّذ لـ PaymentProviderInterface
config_schema	JSONB	الحقول المطلوبة لهذا المزود (رقم حساب الاستلام، مفتاح API...)
credentials_encrypted	TEXT	مشفّرة عبر KMS (كما مفاتيح AI)
receiving_account_number	VARCHAR(50)	رقم محفظة/حساب المنصة لاستقبال التحويلات
is_active	BOOLEAN	تحكم فوري بالتفعيل/الإيقاف من لوحة المنصة
sort_order	SMALLINT	ترتيب العرض للتاجر
2.5 🟢 payment_transactions — جوهر عمليات الدفع
الحقل	النوع	القيود	الوصف
tenant_id	UUID	FK	
subscription_id	UUID	FK	
provider_id	UUID	FK → payment_providers	
target_plan_id	UUID	FK	الباقة المطلوب التفعيل لها
amount	DECIMAL(10,2)		
currency_code	VARCHAR(3)		
status	VARCHAR(20)	NOT NULL	initiated / pending_verification / paid / failed / expired / refunded
provider_reference_number	VARCHAR(100)	NULL	رقم العملية الذي أدخله التاجر (نمط Pull)
provider_transaction_id	VARCHAR(100)	NULL	معرّف من المزود نفسه (نمط Push)
idempotency_key	VARCHAR(100)	UNIQUE NOT NULL	يُولَّد من التطبيق لمنع الدفع المكرر
initiated_at	TIMESTAMPTZ		
verified_at	TIMESTAMPTZ	NULL	
expires_at	TIMESTAMPTZ	NOT NULL	مهلة انتظار الدفع (مثال: 30 دقيقة)
failure_reason	TEXT	NULL	
فهارس:

SQL

UNIQUE(idempotency_key)
INDEX(tenant_id, status)
INDEX(provider_reference_number)  -- للاستعلام السريع عند التحقق اليدوي
2.6 payment_webhook_logs — سجل خام لكل Webhook وارد (تدقيق وأمان)
الحقل	النوع	الوصف
provider_id	UUID FK	
raw_payload	JSONB	المحتوى الكامل كما ورد
signature_valid	BOOLEAN	نتيجة التحقق من التوقيع
processed	BOOLEAN	
related_transaction_id	UUID FK NULL	
received_at	TIMESTAMPTZ	
Append-only بلا استثناء — أساس أي تحقيق مستقبلي في نزاع دفع.

2.7 🟢 ai_usage_log وai_provider_configs
ai_usage_log

الحقل	النوع	الوصف
tenant_id	UUID FK	
user_id	UUID FK	
request_type	VARCHAR(20)	text / voice
tokens_used	INTEGER	NULL
billing_period_key	VARCHAR(10)	"2025-01" لتسريع التجميع الشهري
created_at	TIMESTAMPTZ	
فهرس: INDEX(tenant_id, billing_period_key) — أساس فحص الحصة الشهرية بسرعة.

ai_provider_configs (مستوى المنصة + تخصيص التاجر)

الحقل	النوع	الوصف
tenant_id	UUID NULL	NULL = إعداد افتراضي للمنصة
provider_code	VARCHAR(30)	openai, anthropic, google...
model_name	VARCHAR(50)	
api_key_encrypted	TEXT	عبر KMS، كما حُدِّد سابقًا
is_tenant_owned_key	BOOLEAN	true إن أدخله التاجر بنفسه
is_active	BOOLEAN	
3. طبقة تجريد مزودي الدفع (Payment Provider Interface)
3.1 العقد الموحّد (كل Adapter يلتزم به)
TypeScript

interface PaymentProviderAdapter {
  initiatePayment(request: InitiatePaymentRequest): Promise<InitiatePaymentResult>
  verifyByReference(referenceNumber: string, config: ProviderConfig): Promise<VerificationResult>
  validateWebhookSignature(rawPayload: object, headers: object, config: ProviderConfig): boolean
  parseWebhookPayload(rawPayload: object): NormalizedPaymentEvent
}

interface NormalizedPaymentEvent {
  provider_transaction_id: string
  reference_number: string | null
  amount: number
  currency: string
  status: 'paid' | 'failed'
  paid_at: string
}
السبب الهندسي: إضافة محفظة يمنية جديدة أو بوابة عربية مستقبلية = كتابة Adapter جديد ينفّذ هذا العقد فقط، بلا لمس محرك الاشتراكات أو قاعدة البيانات.

3.2 تدفق الدفع — النمط Push (Webhook)
mermaid

sequenceDiagram
    participant App as تطبيق التاجر
    participant API as خادم المنصة
    participant Wallet as محفظة إلكترونية

    App->>API: POST /subscriptions/checkout (plan, provider)
    API->>API: إنشاء payment_transaction (status=initiated)
    API-->>App: رابط/تعليمات الدفع + idempotency_key
    App->>Wallet: التاجر يدفع عبر تطبيق المحفظة
    Wallet->>API: Webhook موقّع (نجاح الدفع)
    API->>API: التحقق من التوقيع + idempotency
    API->>API: تفعيل الاشتراك (atomic)
    API-->>App: Push Notification "تم تفعيل باقتك"
3.3 تدفق الدفع — النمط Pull (تحقق بالمرجع) — الأكثر واقعية في اليمن حاليًا
mermaid

sequenceDiagram
    participant App as تطبيق التاجر
    participant API as خادم المنصة
    participant Wallet as محفظة إلكترونية

    App->>API: POST /subscriptions/checkout (plan, provider)
    API-->>App: "حوّل إلى الرقم X وأدخل رقم العملية"
    App->>Wallet: التاجر يحوّل يدويًا عبر تطبيق محفظته
    Wallet-->>App: التاجر يحصل على رقم العملية من محفظته
    App->>API: POST /payment-transactions/{id}/submit-reference
    API->>Wallet: استعلام API: verifyByReference(ref)
    Wallet-->>API: تأكيد المبلغ والحالة
    API->>API: تفعيل الاشتراك إن تطابق المبلغ تمامًا
    API-->>App: "تم تفعيل باقتك فورًا"
3.4 خوارزمية معالجة الدفع (موحّدة لكلا النمطين)
text

function processPaymentConfirmation(transaction_id, verification_data, context):
    atomic_transaction:
        tx = getPaymentTransaction(transaction_id)
        
        // حماية Idempotency: رفض أي معالجة مكررة
        IF tx.status IN ['paid', 'failed']:
            RETURN tx  // لا تكرار المعالجة

        // تحقق صارم من تطابق المبلغ (يمنع تفعيل باقة أغلى بمبلغ أقل)
        ASSERT verification_data.amount == tx.amount
        ASSERT verification_data.currency == tx.currency_code

        IF verification_data.status == 'paid':
            markTransactionPaid(tx.id, verification_data)
            activateSubscription(tx.tenant_id, tx.target_plan_id, context)
            logSubscriptionEvent(tx.subscription_id, 'activated', triggered_by='system')
            sendNotification(tx.tenant_id, "تم تفعيل باقتك بنجاح")
        ELSE:
            markTransactionFailed(tx.id, verification_data.failure_reason)

    RETURN tx
3.5 مهمة التوفيق الدوري (Reconciliation Job) — خط دفاع إضافي
text

// تعمل كل 5 دقائق لمعالجة أي معاملة "عالقة" في pending_verification
function reconcilePendingTransactions():
    stuck_transactions = getTransactions(status='pending_verification', older_than='10 minutes')
    
    FOR tx IN stuck_transactions:
        IF tx.provider.integration_mode IN ['pull','hybrid']:
            result = tx.provider.adapter.verifyByReference(tx.provider_reference_number)
            processPaymentConfirmation(tx.id, result, context=system)
        
        IF tx.expires_at < now() AND tx.status == 'initiated':
            markTransactionExpired(tx.id)
أهمية هذه المهمة: تحمي من فشل Webhook (شائع مع عدم استقرار الإنترنت في اليمن) عبر إعادة المحاولة التلقائية، وتحقق فعليًا هدف "التفعيل التلقائي" المطلوب دون تدخل يدوي من فريق الدعم.

4. آلة حالات الاشتراك (Subscription State Machine)
mermaid

stateDiagram-v2
    [*] --> trial: تسجيل جديد
    trial --> active: دفع ناجح قبل انتهاء التجربة
    trial --> free_downgraded: انتهاء التجربة بلا دفع
    active --> active: تجديد تلقائي ناجح
    active --> grace_period: فشل التجديد
    grace_period --> active: دفع متأخر ناجح
    grace_period --> suspended: انتهاء مهلة السماح
    suspended --> active: دفع لاحق
    active --> cancelled: إلغاء من التاجر
    cancelled --> free_downgraded: نهاية الفترة المدفوعة
    suspended --> free_downgraded: بعد مهلة إضافية طويلة
4.1 منطق كل حالة على تجربة المستخدم
الحالة	الوصول للتطبيق	ملاحظة
trial	كامل (كل مزايا pro)	عدّاد أيام متبقية ظاهر في الإعدادات
active	كامل حسب حدود الباقة	
grace_period	كامل مؤقتًا (3-5 أيام) مع تنبيه بارز	يمنع إغلاق التاجر المفاجئ لمشكلة دفع بسيطة
suspended	قراءة فقط — عرض البيانات دون إدخال عمليات جديدة	لا حذف بيانات أبدًا
free_downgraded	يعمل كباقة free تلقائيًا (جهاز واحد)	إن تجاوز max_devices الجديد، يُطلب اختيار جهاز واحد للاستمرار
4.2 خوارزمية الترقية والتخفيض
text

function changePlan(tenant_id, new_plan_id, context):
    current_sub = getActiveSubscription(tenant_id)
    new_plan = getPlan(new_plan_id)
    
    IF new_plan.price_amount > current_plan.price_amount:  // ترقية
        // فوري: يُنشأ payment_transaction، والتفعيل فور الدفع (القسم 3.4)
        RETURN initiateCheckout(tenant_id, new_plan_id, context)
    ELSE:  // تخفيض
        // يُجدوَل لنهاية الفترة الحالية، لا استرداد جزئي (تبسيطًا للسوق المستهدف)
        updateSubscription(current_sub.id, pending_plan_id = new_plan_id)
        logSubscriptionEvent(current_sub.id, 'downgraded', metadata={effective_at: current_sub.current_period_end})
        RETURN { message: "سيتم تطبيق التخفيض بداية الفترة القادمة" }
4.3 مهمة التجديد الدوري (يومية)
text

function processRenewals():
    due_subscriptions = getSubscriptions(current_period_end <= today, auto_renew=true, status='active')
    
    FOR sub IN due_subscriptions:
        IF sub.pending_plan_id is not null:
            applyPendingPlanChange(sub)  // تطبيق التخفيض المجدول
        
        charge_result = attemptAutoCharge(sub)  // إن كان المزود يدعم شحن تلقائي (نادر حاليًا في اليمن)
        
        IF charge_result.success:
            extendSubscriptionPeriod(sub)
        ELSE:
            // الأغلب في اليمن: لا شحن تلقائي، يُطلب من التاجر الدفع يدويًا
            moveToGracePeriod(sub)
            sendNotification(sub.tenant_id, "اشتراكك ينتهي، جدّد الآن لتفادي توقف الخدمة")
ملاحظة واقعية مهمة: معظم المحافظ اليمنية لا تدعم الخصم التلقائي المتكرر (Recurring Charge) كبطاقات الائتمان العالمية. لذا attemptAutoCharge سيفشل غالبًا، والمسار الطبيعي هو إشعار استباقي قبل الانتهاء بـ 3 أيام يدفع التاجر للتجديد اليدوي الاستباقي، مع grace_period سخية لتفادي انزعاج التجربة.

5. محرك قياس استهلاك الذكاء الاصطناعي (AI Quota Engine)
text

function checkAndConsumeAiQuota(tenant_id, request_type):
    subscription = getActiveSubscription(tenant_id)
    plan = subscription.plan
    
    IF plan.ai_monthly_quota is null:
        RETURN { allowed: true }  // باقة غير محدودة (pro مثلًا)
    
    tenant_ai_config = getAiProviderConfig(tenant_id)
    IF tenant_ai_config.is_tenant_owned_key:
        RETURN { allowed: true }  // مفتاح التاجر الخاص لا يُحتسب من حصة المنصة
    
    current_period_key = formatPeriodKey(today)
    used_count = countAiUsage(tenant_id, current_period_key)
    
    IF used_count >= plan.ai_monthly_quota:
        RETURN { 
            allowed: false, 
            message_ar: "استهلكت حصتك من الذكاء الاصطناعي هذا الشهر (" + plan.ai_monthly_quota + " طلب). رقّي باقتك أو أضف مفتاحك الخاص."
        }
    
    RETURN { allowed: true, remaining: plan.ai_monthly_quota - used_count - 1 }
نقطة تكامل إلزامية: هذا الفحص يُستدعى قبل أي استدعاء فعلي لـ AI Gateway المصمَّم في المرحلة 4 سابقًا — طبقة حماية من تجاوز التكلفة قبل الوصول للمزود الخارجي أصلًا.

6. مواصفات API
6.1 الاشتراكات (جهة التاجر)
Method	Path	الوصف
GET	/subscription-plans	عرض الباقات المتاحة للمقارنة
GET	/subscription/current	حالة اشتراك التاجر الحالي + استهلاك AI المتبقي
POST	/subscription/checkout	بدء عملية دفع لترقية/تجديد
POST	/subscription/change-plan	تخفيض مجدول أو ترقية
POST	/subscription/cancel	إلغاء التجديد التلقائي
نموذج Response لـ GET /subscription/current:

JSON

{
  "data": {
    "plan": { "code": "plus", "name_ar": "الباقة المتوسطة" },
    "status": "active",
    "current_period_end": "2025-02-15",
    "devices": { "used": 2, "max": 3 },
    "ai_usage": { "used": 34, "quota": 100, "resets_at": "2025-02-01" }
  }
}
6.2 الدفع
Method	Path	الوصف
GET	/payment-providers	المحافظ المفعّلة من المنصة لاختيار التاجر
POST	/payment-transactions	إنشاء معاملة دفع (ينتج تعليمات أو رابط)
POST	/payment-transactions/{id}/submit-reference	إدخال رقم العملية (نمط Pull)
GET	/payment-transactions/{id}/status	استعلام فوري عن الحالة (Polling من التطبيق)
POST	/webhooks/payments/{provider_code}	نقطة استقبال Webhook (عامة، بتوقيع إلزامي)
نموذج Request لـ POST /payment-transactions:

JSON

{ "target_plan_code": "pro", "provider_code": "kuraimi", "currency_code": "YER" }
نموذج Response (نمط Pull):

JSON

{
  "data": {
    "transaction_id": "uuid",
    "amount": 15000,
    "currency": "YER",
    "instructions_ar": "حوّل المبلغ عبر تطبيق كريمي إلى الرقم 7xxxxxxxx ثم أدخل رقم العملية هنا",
    "receiving_account_number": "7xxxxxxxx",
    "expires_at": "2025-01-15T11:00:00Z"
  }
}
6.3 لوحة مالك المنصة
Method	Path	الوصف
GET	/admin/payment-providers	إدارة المزودين (تفعيل/تعطيل)
POST	/admin/payment-providers/{code}/credentials	إدخال/تحديث بيانات الاعتماد (مشفّرة)
GET	/admin/subscriptions?status=&plan=	عرض كل الاشتراكات
PATCH	/admin/tenants/{id}/subscription/override	تفعيل يدوي استثنائي (دعم فني موثّق بسبب إلزامي)
GET	/admin/ai-providers	إدارة مزودي ونماذج AI على مستوى المنصة
PATCH	/admin/tenants/{id}/ai-access	تفعيل/إيقاف وصول AI لتاجر محدد
7. الأمان (طبقات حرجة لا تفاوض عليها)
الإجراء	التطبيق
التحقق من توقيع كل Webhook	HMAC-SHA256 بمفتاح سري خاص بكل مزود، رفض أي حمولة توقيعها غير صالح فورًا مع تسجيلها في payment_webhook_logs
Idempotency صارم	idempotency_key فريد لكل محاولة دفع من التطبيق؛ إعادة إرسال نفس الطلب (بسبب انقطاع شبكة) لا تُنشئ معاملة مكررة
تحقق المبلغ الحرفي	لا تفعيل باقة إلا بتطابق تام للمبلغ والعملة (القسم 3.4) — يمنع استغلال فروق تقريب
تشفير بيانات اعتماد المزودين	عبر KMS، بنفس آلية مفاتيح AI المعتمدة سابقًا، لا نص صريح في قاعدة البيانات مطلقًا
التفعيل اليدوي الاستثنائي مُسجَّل بالكامل	أي admin/override يُسجَّل في audit_log مع هوية الموظف وسبب التفعيل اليدوي
حد أقصى لمحاولات إدخال رقم مرجعي خاطئ	Rate limiting على submit-reference لمنع تخمين أرقام عمليات آخرين
8. معالجة الحالات الخاصة (Edge Cases)
الحالة	المعالجة
تاجر يدفع قيمة أعلى من الباقة المطلوبة خطأ	تُسجَّل الزيادة كـ"رصيد دائن للتاجر" (مشابه لمنطق Overpayment في وحدة الذمم) يُستخدم تلقائيًا عند التجديد القادم
فشل Webhook وصول بينما الدفع نجح فعليًا	يُعالَج عبر reconcilePendingTransactions (القسم 3.5) خلال دقائق
تاجر في suspended يحاول فتح التطبيق دون نت	يُسمح بالدخول وعرض البيانات (Local-first)، لكن تُعرض لافتة تنبيه دائمة، ولا تُسمح عمليات جديدة حتى تزامن يؤكد الحالة
إلغاء الاشتراك مع وجود أجهزة متعددة تتجاوز حد free	عند free_downgraded، يُطلب من المالك اختيار جهاز واحد يبقى نشطًا، والبقية تُعلَّق (لا تُحذف بياناتها)
مزود دفع يُعطَّل من المنصة بينما لتاجر معاملة قيد الانتظار معه	reconcilePendingTransactions تستمر بمعالجة المعاملات القائمة حتى لو عُطِّل المزود لاحقًا عن استقبال معاملات جديدة
9. حوكمة واختبارات الجودة
القاعدة	الآلية
لا تفعيل اشتراك دون payment_transaction.status = 'paid' موثّق	قيد منطقي صارم + Integration Test
كل Webhook بتوقيع غير صالح يُرفض ويُسجَّل، ولا يصل لمنطق الأعمال إطلاقًا	Unit Test لكل Adapter
اختبار Idempotency: إرسال نفس طلب الدفع 3 مرات ينتج معاملة واحدة فقط	اختبار إلزامي قبل الإطلاق
اختبار انتهاء الصلاحية: معاملة pending تتجاوز expires_at تُعلَّم expired تلقائيًا ولا تُفعَّل متأخرًا	Scheduled Job Test
اختبار التوفيق: محاكاة فشل Webhook وتأكيد نجاح reconcilePendingTransactions في اكتشاف الدفعة لاحقًا	أولوية قصوى نظرًا لواقع الإنترنت اليمني
اختبار حصة AI: تجاوز الحصة يمنع الاستدعاء الفعلي للمزود الخارجي (لا تكلفة غير محسوبة على المنصة)	Integration Test
10. خلاصة وتوصيات
ابدأ بتفعيل نمط Pull (التحقق بالمرجع) كأساس للإطلاق الأول، لأنه لا يعتمد على نضج تقني من جهة المحافظ اليمنية، ثم أضف نمط Push تدريجيًا مع كل مزود يوفره فعليًا — هذا يضمن إطلاقًا عمليًا دون انتظار تكاملات معقدة.
مهمة التوفيق الدوري (Reconciliation Job) ليست ميزة إضافية بل ضرورة بنيوية في بيئة إنترنت متذبذبة كاليمن — دونها، ستتراكم شكاوى "دفعت ولم يُفعَّل حسابي" بسرعة وتضر بثقة المستخدم بالمنصة بأكملها.
لا تعتمد على الخصم التلقائي المتكرر كافتراض أساسي — صمم تجربة التجديد حول "تذكير استباقي + دفع يدوي سريع بنقرتين" بدل نموذج الاشتراكات الغربي القائم على بطاقات محفوظة.
اجعل grace_period سخية (3-5 أيام) افتراضيًا — انقطاع خدمة مفاجئ لتاجر بسبب تأخر يوم في الدفع يضر بالاحتفاظ بالمستخدمين أكثر مما يحمي الإيرادات.
وثّق كل تفعيل يدوي من لوحة المنصة (admin/override) بصرامة — هذه النقطة الوحيدة التي تتجاوز الفحص الآلي، وتحتاج رقابة تدقيق صارمة لمنع إساءة الاستخدام الداخلي.
اختبر طبقة PaymentProviderInterface بمزوّد وهمي (Mock Adapter) أولًا قبل التكامل الفعلي مع أي محفظة حقيقية — يسرّع تطوير واختبار محرك الاشتراك بأكمله بمعزل عن تعقيدات التكامل الخارجي.
بهذا تكتمل تصميم كل الوحدات الأساسية الست المخطط لها: المحاسبة الجوهرية، المخزون، الذمم (AR/AP)، التقارير المالية، الواجهات (Wireframes)، والاشتراكات/الدفع. هذا يُشكِّل حزمة تصميم تقني متكاملة وجاهزة للبدء الفعلي في التطوير للمرحلتين 0 و1 كما حُدِّدتا في خارطة الطريق الأصلية.

التوصية الختامية للخطوة التالية: الانتقال الآن من التصميم إلى إعداد خطة Sprint تنفيذية فعلية (توزيع هذه الوحدات على دورات تطوير أسبوعية/أسبوعين مع تبعياتها الصحيحة)، أو البدء الفعلي في كتابة الكود بدءًا بـJournal Engine كما أوصينا مرارًا. هل ترغب بإعداد خطة الـ Sprints التنفيذية؟




نعم بأفضل الأساليب والوسائل وبأداء احترافي
