claude-sonnet-5-high
تصميم وحدة الذمم المدينة والدائنة التفصيلية
(AR/AP Sub-Ledger & Aging Engine) — بأفضل الممارسات
0. قرارات تصميمية وتصحيحات ضرورية قبل البدء
0.1 المشكلة الجوهرية التي تحل هذه الوحدة
حتى الآن، journal_lines.contact_id يُسجّل أن "العميل أحمد مدين بـ 15,000"، لكن عندما يدفع أحمد 5,000 لاحقًا، لا توجد آلية تربط هذا السداد بفاتورة محددة. هذا يجعل حساب "أعمار الديون" (كم من الدين عمره 30 يومًا وكم عمره 90 يومًا) مستحيلًا حسابيًا بدون هذه الوحدة، لأن النظام يعرف الرصيد الإجمالي فقط لا تفاصيله.

0.2 المبدأ المعماري: نمط "الفاتورة المفتوحة" (Open Item Accounting)
هذا هو المعيار المحاسبي الصناعي (يُستخدم في SAP وQuickBooks وكل ERP احترافي): كل عملية تُنشئ رصيدًا (بيع آجل) تُسجَّل كـ "بند مفتوح" (Open Item)، وكل عملية تُسوّي رصيدًا (تحصيل) يجب أن تُخصَّص لبند مفتوح محدد أو أكثر. الفرق بين "إجمالي الدين" و"الفاتورة المفتوحة غير المسددة" هو جوهر هذه الوحدة.

0.3 تصحيح على journal_lines من التصميم السابق
إضافة حقل واحد ضروري:

الحقل الجديد	النوع	الوصف
open_item_id	UUID NULL FK → ar_ap_open_items.id	يربط سطر القيد الفعلي بالبند المفتوح الذي أنشأه أو سوّاه
0.4 لماذا جدول منفصل (ar_ap_open_items) لا الاعتماد على transactions مباشرة؟
لأن:

فاتورة واحدة قد تُسوَّى على دفعات متعددة (تحصيل جزئي 3 مرات) — نحتاج تتبع الرصيد المتبقي لكل بند بمعزل عن القيد الأصلي.
التسوية الواحدة (تحصيل 10,000) قد تُغطي عدة فواتير دفعة واحدة — علاقة Many-to-Many تتطلب جدول ربط مستقل.
فروق العملة والخصومات المسموح بها يجب أن تُحسب عند التسوية لا عند الإنشاء، فتحتاج سجلًا حيًا قابلًا للتحديث (الرصيد المتبقي)، بعكس journal_entries الثابتة (Immutable) بتصميمنا السابق.
1. مخطط العلاقات (ERD)
mermaid

erDiagram
    CONTACTS ||--o{ AR_AP_OPEN_ITEMS : "owns"
    TRANSACTIONS ||--o| AR_AP_OPEN_ITEMS : "creates"
    AR_AP_OPEN_ITEMS ||--o{ AR_AP_ALLOCATIONS : "settled_via"
    TRANSACTIONS ||--o{ AR_AP_ALLOCATIONS : "settlement_source"
    AR_AP_ALLOCATIONS }o--|| JOURNAL_ENTRIES : "fx_gain_loss_entry"
    CONTACTS ||--o{ CONTACT_CREDIT_HOLDS : "may_have"
    AR_AP_OPEN_ITEMS ||--o{ AR_AP_REMINDERS : "triggers"
2. تفصيل الجداول حقلًا حقلًا
جميع الجداول تحمل الأعمدة القياسية المعتمدة سابقًا.

2.1 🟢 ar_ap_open_items — البنود المفتوحة (جوهر الوحدة)
الحقل	النوع	القيود	الوصف
contact_id	UUID	FK NOT NULL	العميل أو المورد
item_category	VARCHAR(10)	NOT NULL	AR (مدين لنا) | AP (دائن علينا)
source_transaction_id	UUID	FK → transactions NOT NULL	الفاتورة الأصلية (بيع آجل/شراء آجل)
source_journal_entry_id	UUID	FK → journal_entries NOT NULL	القيد الذي أنشأ هذا البند
document_date	DATE	NOT NULL	تاريخ الفاتورة (أساس حساب العمر)
due_date	DATE	NULL	تاريخ الاستحقاق المتوقع (إن أُدخل)
original_amount	DECIMAL(18,4)	NOT NULL, > 0	المبلغ الأصلي بعملة الفاتورة
currency_code	VARCHAR(3)	NOT NULL	عملة الفاتورة الأصلية
exchange_rate_at_creation	DECIMAL(18,6)	NOT NULL	مثبّت وقت الإنشاء
original_amount_base	DECIMAL(18,4)	محسوب	= original_amount × rate
remaining_amount	DECIMAL(18,4)	NOT NULL	الحقل الأهم — يُحدَّث تدريجيًا عند كل تخصيص
remaining_amount_base	DECIMAL(18,4)	محسوب ومحدَّث	بعملة الأساس بسعر الصرف وقت آخر تحديث
status	VARCHAR(20)	DEFAULT 'open'	open / partially_settled / settled / written_off
write_off_reason	TEXT	NULL	عند الشطب (ديون معدومة)
قيد إلزامي (Trigger):

SQL

CHECK (remaining_amount >= 0 AND remaining_amount <= original_amount)
فهارس حرجة:

SQL

INDEX(tenant_id, contact_id, status)              -- كشف حساب العميل
INDEX(tenant_id, item_category, status, due_date) -- أعمار الديون
INDEX(tenant_id, source_transaction_id)           -- ربط عكسي للفاتورة
2.2 🟢 ar_ap_allocations — التخصيصات (ربط التسوية بالفاتورة)
الحقل	النوع	القيود	الوصف
open_item_id	UUID	FK NOT NULL	البند المفتوح المُسوَّى
settlement_transaction_id	UUID	FK → transactions NOT NULL	معاملة التحصيل/السداد
allocated_amount	DECIMAL(18,4)	NOT NULL, > 0	المبلغ المخصَّص لهذه الفاتورة تحديدًا (بعملة الفاتورة)
allocated_amount_base	DECIMAL(18,4)	محسوب	بعملة الأساس بسعر صرف يوم التسوية
fx_gain_loss_amount	DECIMAL(18,4)	DEFAULT 0	الفرق الناتج عن تغيّر سعر الصرف بين الإنشاء والتسوية
fx_gain_loss_journal_entry_id	UUID	FK NULL	القيد التلقائي لفرق العملة (إن وُجد)
discount_given_amount	DECIMAL(18,4)	DEFAULT 0	خصم مسموح به عند التحصيل المبكر
allocation_date	DATE	NOT NULL	
قيد إلزامي:

SQL

CHECK (allocated_amount + discount_given_amount <= (SELECT original_amount FROM ar_ap_open_items WHERE id = open_item_id))
ملاحظة تصميمية: تخصيص واحد (allocation) يرتبط ببند مفتوح واحد. تحصيل يُغطي 3 فواتير = 3 سجلات allocation بنفس settlement_transaction_id. هذا يحقق علاقة Many-to-Many بشكل نظيف وقابل للاستعلام.

2.3 contact_credit_holds — سقف الائتمان والتجميد
الحقل	النوع	الوصف
contact_id	UUID FK	
credit_limit_amount	DECIMAL(18,4)	(مكرر منطقيًا من contacts لكن قابل للتعديل بشكل مستقل مع سجل تاريخي)
is_on_hold	BOOLEAN	تجميد يدوي كامل بغض النظر عن السقف
hold_reason	TEXT	
set_by_user_id	UUID	
2.4 ar_ap_reminders — سجل التذكيرات المُرسَلة
الحقل	النوع	الوصف
contact_id	UUID FK	
open_item_id	UUID FK NULL	تذكير بفاتورة محددة أو برصيد إجمالي
channel	VARCHAR(20)	whatsapp / sms (مستقبلًا)
message_sent	TEXT	
sent_at	TIMESTAMPTZ	
sent_by_user_id	UUID	
2.5 🟡 جدول تجميعي: contact_balances (أداء)
نظير stock_balances تمامًا — رصيد محسوب مسبقًا بدل جمع ar_ap_open_items.remaining_amount في كل استعلام.

الحقل	النوع
contact_id	UUID FK
currency_code	VARCHAR(3)
total_outstanding_amount	DECIMAL(18,4)
total_outstanding_base	DECIMAL(18,4)
open_items_count	INTEGER
oldest_due_date	DATE
last_activity_at	TIMESTAMPTZ
يُحدَّث ضمن نفس Transaction الذرية عند أي إنشاء/تخصيص على ar_ap_open_items.

3. محرك التخصيص (Allocation Engine)
3.1 إنشاء بند مفتوح (عند تنفيذ قالب بيع/شراء آجل)
text

function createOpenItem(transaction, journal_entry, context):
    item_category = transaction.template_code.startsWith('sale') ? 'AR' : 'AP'
    
    open_item = insert(ar_ap_open_items, {
        contact_id: transaction.contact_id,
        item_category: item_category,
        source_transaction_id: transaction.id,
        source_journal_entry_id: journal_entry.id,
        document_date: transaction.transaction_date,
        due_date: transaction.payload.due_date ?? null,
        original_amount: transaction.amount,
        currency_code: transaction.currency_code,
        exchange_rate_at_creation: getCurrentRate(transaction.currency_code, context.tenant),
        remaining_amount: transaction.amount,
        status: 'open'
    })
    
    updateContactBalanceAggregate(transaction.contact_id, delta = +open_item.remaining_amount_base)
    return open_item
يُستدعى هذا تلقائيًا كـ post_action من قوالب sale_credit, sale_partial, purchase_credit, purchase_partial, service_revenue_credit.

3.2 التخصيص عند التحصيل/السداد — خوارزمية FIFO ذكية مع مرونة يدوية
text

function allocatePayment(settlement_transaction, target_open_item_id_optional, context):
    atomic_transaction:
        remaining_to_allocate = settlement_transaction.amount
        allocations_created = []

        if target_open_item_id_optional is not null:
            // المستخدم اختار فاتورة محددة (من حقل invoice_ref في القالب)
            open_items_queue = [getOpenItem(target_open_item_id_optional)]
        else:
            // لا تحديد: توزيع تلقائي FIFO (الأقدم أولًا) - الأكثر شيوعًا في اليمن
            open_items_queue = getOpenItemsSorted(
                settlement_transaction.contact_id, 
                item_category = settlement_transaction.is_collection ? 'AR' : 'AP',
                order_by = 'document_date ASC'
            )

        for open_item in open_items_queue:
            if remaining_to_allocate <= 0: break

            allocate_amount = min(open_item.remaining_amount, remaining_to_allocate)

            // حساب فرق العملة إن اختلف سعر الصرف
            current_rate = getCurrentRate(open_item.currency_code, context.tenant)
            fx_diff = calculateFxDifference(open_item, allocate_amount, current_rate)

            allocation = insert(ar_ap_allocations, {
                open_item_id: open_item.id,
                settlement_transaction_id: settlement_transaction.id,
                allocated_amount: allocate_amount,
                allocated_amount_base: allocate_amount * current_rate,
                fx_gain_loss_amount: fx_diff,
                allocation_date: settlement_transaction.transaction_date
            })

            // إنشاء قيد فرق العملة إن لزم (مرتبط بـ post_action السابق)
            if fx_diff != 0:
                fx_entry = createFxAdjustmentEntry(open_item, fx_diff, context)
                updateAllocation(allocation.id, fx_gain_loss_journal_entry_id = fx_entry.id)

            new_remaining = open_item.remaining_amount - allocate_amount
            updateOpenItem(open_item.id, 
                remaining_amount = new_remaining,
                status = new_remaining == 0 ? 'settled' : 'partially_settled'
            )

            updateContactBalanceAggregate(open_item.contact_id, delta = -allocate_amount_base)
            remaining_to_allocate -= allocate_amount
            allocations_created.append(allocation)

        if remaining_to_allocate > 0:
            // دفعة زائدة عن كل الفواتير المفتوحة
            handleOverpayment(settlement_transaction, remaining_to_allocate, context)

        return allocations_created
3.3 معالجة الدفعة الزائدة (Overpayment) — نقطة كانت مفقودة سابقًا
text

function handleOverpayment(settlement_transaction, excess_amount, context):
    // يُسجَّل كبند مفتوح عكسي: "دفعة مقدمة من العميل" أو "دفعة مقدمة لمورد"
    insert(ar_ap_open_items, {
        contact_id: settlement_transaction.contact_id,
        item_category: settlement_transaction.is_collection ? 'AP_CREDIT' : 'AR_CREDIT', // رصيد دائن للطرف
        source_transaction_id: settlement_transaction.id,
        original_amount: excess_amount,
        remaining_amount: excess_amount,
        status: 'open',
        document_date: settlement_transaction.transaction_date
    })
    // يُستخدَم تلقائيًا كخيار تخصيص متاح في أول فاتورة آجلة قادمة لنفس الطرف
4. تحديث قوالب المرحلة السابقة (إلزامي)
القوالب customer_collection وsupplier_payment المصمَّمة سابقًا تحتاج تحديثًا الآن لحقل invoice_ref ليصبح اختيار فعلي من البنود المفتوحة الحقيقية، لا حقلًا نظريًا:

JSON

{
  "key": "invoice_ref",
  "type": "select",
  "label_ar": "خصّصها لفاتورة معينة؟ (أو اتركها فاضية للتوزيع التلقائي)",
  "required": false,
  "options_source": "open_items(contact_id={{customer_id}}, category='AR')"
}
options_source الفعلي يستدعي:

SQL

SELECT id, document_date, remaining_amount, 
       CONCAT('فاتورة ', document_date, ' - متبقي ', remaining_amount) as label_ar
FROM ar_ap_open_items 
WHERE contact_id = :customer_id AND item_category = 'AR' AND status != 'settled'
ORDER BY document_date ASC
تحديث post_actions:

JSON

"post_actions": ["apply_fx_gain_loss_if_needed", "allocatePayment({{invoice_ref}})"]
ملاحظة: apply_fx_gain_loss_if_needed المُعرَّفة سابقًا في القسم العام تُستبدَل الآن بمنطق أدق محسوب داخل allocatePayment نفسها (القسم 3.2)، لأن فرق العملة يُحسب لكل بند مفتوح على حدة لا على إجمالي المعاملة، وهذا أدق محاسبيًا عند تخصيص دفعة واحدة على عدة فواتير بتواريخ مختلفة (وبالتالي أسعار صرف تاريخية مختلفة).

5. محرك أعمار الديون (Aging Engine)
5.1 منطق الحساب
text

function calculateAgingReport(tenant_id, item_category, as_of_date = today):
    open_items = getOpenItems(tenant_id, item_category, status IN ['open', 'partially_settled'])
    
    buckets = { current: 0, days_1_30: 0, days_31_60: 0, days_61_90: 0, over_90: 0 }
    
    for item in open_items:
        reference_date = item.due_date ?? item.document_date
        age_days = as_of_date - reference_date
        
        bucket = age_days <= 0   ? 'current' :
                 age_days <= 30  ? 'days_1_30' :
                 age_days <= 60  ? 'days_31_60' :
                 age_days <= 90  ? 'days_61_90' : 'over_90'
        
        buckets[bucket] += item.remaining_amount_base
    
    return groupByContactAndBucket(open_items, buckets)
5.2 شكل تقرير أعمار الديون (مرجع للواجهة)
العميل	حالي	1-30 يوم	31-60 يوم	61-90 يوم	أكثر من 90	الإجمالي
أحمد سالم	5,000	12,000	0	8,000	0	25,000
محل الأمانة	0	0	3,500	0	15,000	18,500
6. مواصفات API
6.1 البنود المفتوحة وكشف الحساب
Method	Path	الوصف
GET	/contacts/{id}/open-items?status=&category=	كل البنود المفتوحة لطرف محدد
GET	/contacts/{id}/statement?date_from=&date_to=	كشف حساب كامل (فواتير + تسويات بالترتيب الزمني)
GET	/contacts/{id}/balance	الرصيد الحالي الفوري (من الجدول التجميعي)
POST	/open-items/{id}/write-off	شطب دين معدوم (صلاحية المالك فقط)
نموذج Response لـ GET /contacts/{id}/statement:

JSON

{
  "data": {
    "contact": { "id": "uuid", "name": "أحمد سالم", "phone": "7xxxxxxxx" },
    "opening_balance": 10000,
    "lines": [
      { "date": "2025-01-05", "type": "invoice", "description": "فاتورة بيع آجل", "debit": 15000, "credit": 0, "running_balance": 25000 },
      { "date": "2025-01-10", "type": "payment", "description": "تحصيل نقدي", "debit": 0, "credit": 5000, "running_balance": 20000 }
    ],
    "closing_balance": 20000
  }
}
6.2 أعمار الديون
Method	Path	الوصف
GET	/reports/aging?category=AR&as_of_date=	تقرير أعمار الذمم المدينة
GET	/reports/aging?category=AP&as_of_date=	تقرير أعمار الذمم الدائنة
GET	/reports/aging/summary	إجمالي كل Bucket عبر كل العملاء (للوحة الرئيسية)
6.3 التذكيرات
Method	Path	الوصف
POST	/contacts/{id}/send-reminder	توليد نص جاهز + تسجيل الإرسال
GET	/contacts/{id}/reminders-history	سجل التذكيرات السابقة
نموذج Request/Response لـ POST /contacts/{id}/send-reminder:

JSON

// Request
{ "channel": "whatsapp", "open_item_id": "uuid-اختياري" }

// Response
{
  "data": {
    "message_text": "السلام عليكم أخ أحمد، تذكير بسيط بأن لديك رصيد مستحق قدره 20,000 ريال. نكون شاكرين لو تواصلت معنا بخصوص السداد. 🙏",
    "whatsapp_deep_link": "https://wa.me/9677xxxxxxxx?text=..."
  }
}
6.4 سقف الائتمان
Method	Path	الوصف
PATCH	/contacts/{id}/credit-hold	تجميد/رفع تجميد، تعديل السقف
GET	/contacts/{id}/credit-status	الرصيد الحالي مقابل السقف
تحقق إلزامي يُضاف إلى محرك تنفيذ القوالب (القسم السابق) لقوالب sale_credit وsale_partial:

text

function validateCreditLimit(customer_id, new_amount, context):
    status = getCreditStatus(customer_id)
    if status.is_on_hold:
        throw Error("هذا العميل متوقف عن التعامل الآجل، راجع المالك")
    if status.credit_limit > 0 and (status.current_balance + new_amount) > status.credit_limit:
        return WARNING("العميل راح يتجاوز حد الائتمان المسموح (الحد: X، الرصيد بعد العملية: Y) - تأكيد المتابعة؟")
7. معالجة حالات خاصة (Edge Cases) — ضرورية للصحة المحاسبية
الحالة	المعالجة
تحصيل بعملة مختلفة عن عملة الفاتورة تمامًا (فاتورة بالريال، تحصيل بالدولار)	يُحوَّل مبلغ التحصيل لعملة الفاتورة بسعر صرف يوم التحصيل قبل التخصيص، ثم يُحسب فرق العملة كالمعتاد
مرتجع على فاتورة مسدَّدة جزئيًا	المرتجع ينشئ بندًا عكسيًا يُخصَّص تلقائيًا لنفس source_transaction_id الأصلي، يقلل remaining_amount
حذف/عكس معاملة بيع آجل لها تخصيصات موجودة	محظور — يجب إلغاء التخصيصات أولًا ثم عكس الفاتورة (قيد تطبيقي صارم يمنع كسر تكامل البيانات)
خصم نقدي مسموح به عند السداد المبكر	discount_given_amount في ar_ap_allocations يُنشئ سطر قيد إضافي تلقائي على حساب "خصم مسموح به" (يُضاف لشجرة الحسابات: 5810)
تاجر يريد تسوية يدوية دون ربط لفاتورة محددة (حالات قديمة قبل تفعيل هذا النظام)	خيار "تخصيص حر" يُنشئ بندًا مفتوحًا بقيمة سالبة مباشرة دون المرور بخوارزمية FIFO
8. حوكمة واختبارات الجودة
القاعدة	الآلية
SUM(ar_ap_allocations.allocated_amount) WHERE open_item_id = X يجب ألا يتجاوز original_amount أبدًا	قيد CHECK + Trigger + Unit Test
contact_balances.total_outstanding يساوي دائمًا SUM(open_items.remaining_amount) لنفس الطرف	اختبار تسوية دوري (كما في وحدة المخزون)
كل fx_gain_loss_amount != 0 يملك fx_gain_loss_journal_entry_id غير فارغ	قيد تكامل
اختبار Fuzz: تحصيل مبلغ عشوائي على عميل له 5 فواتير بعملات وتواريخ مختلفة، والتحقق من توازن كل القيود الناتجة	إلزامي قبل الإطلاق
اختبار Overpayment: تحصيل أكبر من كل الفواتير المفتوحة مجتمعة، والتحقق من إنشاء بند رصيد دائن صحيح	Golden Test Case
منع عكس فاتورة لها تخصيصات (القسم 7)	Integration Test يتحقق من رفض العملية برسالة واضحة
9. خلاصة وتوصيات
هذه الوحدة هي الفارق بين "تطبيق يعرض رقمًا" و"نظام محاسبي حقيقي" — دون ar_ap_open_items، كل الحديث عن "أعمار الديون" في التقارير السابقة كان عنوانًا بلا محتوى قابل للتنفيذ.
اعتمد التوزيع التلقائي FIFO كافتراضي دائمًا، لأنه يطابق الفهم الفطري لمعظم التجار اليمنيين غير المتخصصين ("الأقدم يُسدَّد أولًا")، مع إتاحة التخصيص اليدوي لمن يحتاجه فقط.
لا تُطلق ميزة "سقف الائتمان" كقيد صارم (Hard Block) في الإصدار الأول — اجعلها تحذيرًا قابلًا للتجاوز فقط، لأن حظر البيع الآجل فعليًا قد يصطدم بعادات تجارية راسخة يصعب فرض تغييرها فجأة.
اختبر سيناريو "الدفعة الزائدة" (Overpayment) مبكرًا — هي حالة شائعة جدًا في الواقع العملي (عميل يدفع مبلغًا مستديرًا أكبر قليلًا من دينه) ومُهمَلة غالبًا في التصاميم المبسّطة.
اربط send-reminder بصياغة لطيفة ثقافيًا كما في المثال (القسم 6.3) — هذا تفصيل صغير تقنيًا لكنه بالغ الأهمية في قبول الميزة اجتماعيًا في السياق اليمني كما نوقش سابقًا.
الخطوة التالية المقترحة: الوحدات الأساسية الثلاث (المحاسبة، المخزون، الذمم) أصبحت مكتملة الآن. الخيارات المنطقية التالية:

تصميم وحدة التقارير المالية الموحّدة (قائمة الدخل، الميزانية العمومية، ميزان المراجعة) التي تستهلك كل ما سبق.
الانتقال إلى Wireframes الشاشات الفعلية.
تصميم وحدة الاشتراكات والدفع عبر المحافظ اليمنية (المرحلة 3 سابقًا).
أيها تفضل؟




المقترح الاول بأفضل الممارسات والأساليب وبأداء احترافي
