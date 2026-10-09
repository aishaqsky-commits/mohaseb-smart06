claude-sonnet-5-high
تصميم وحدة المخزون التفصيلية
(Inventory Management Module) — بأفضل الممارسات
0. قرارات تصميمية وتصحيحات ضرورية قبل البدء
0.1 تصحيح جوهري: فصل "الرصيد" عن "الحركة"
الخطأ الشائع هو تخزين "الكمية الحالية" كحقل واحد يُحدَّث مباشرة. هذا يكسر مبدأ Event Sourcing المعتمد في تصميم المزامنة سابقًا، ويجعل تتبع سبب أي رصيد مستحيلًا.

الحل المعتمد (معيار صناعي):

دفتر حركة المخزون stock_movements هو مصدر الحقيقة الوحيد (Source of Truth) — سجل Append-only لا يُعدَّل ولا يُحذف.
جدول stock_balances هو جدول تجميعي (Materialized Aggregate) محسوب من الحركات، يُحدَّث تدريجيًا لأغراض الأداء فقط (كما أوصينا بالجداول التجميعية للتقارير سابقًا).
0.2 ربط حتمي بمحرك القيود
كل حركة مخزون ذات أثر مالي (شراء، بيع، تالف) يجب أن تحمل journal_entry_id مرجعيًا، تحقيقًا لمبدأ: لا تغيّر كمية أو تكلفة دون أثر محاسبي موازٍ، والعكس صحيح أيضًا.

0.3 دعم النمطين معًا (جرد دوري/مستمر) بنموذج بيانات واحد
بدل بناء نظامين منفصلين، القرار الهندسي الأفضل:

كل الأصناف تُسجَّل حركاتها فعليًا (كأنها جرد مستمر) على مستوى الباطن (Backend)، لكن واجهة "المخزن العام" تُبسِّط العرض لمن يريد العمل بعقلية الجرد الدوري (إدخال إجمالي دون تتبع صنف بصنف)، عبر "صنف تجميعي افتراضي" واحد. هذا يمنع ازدواج المنطق البرمجي ويتيح للتاجر الترقية لاحقًا من دوري إلى مستمر دون فقد بيانات.

0.4 تعديل على accounts.code — لا تغيير مطلوب
حساب 1310/1320/إلخ المعرَّف في Seed سابقًا يبقى كما هو — يمثل إجمالي قيمة المخزون في القيد المحاسبي، بينما تفاصيل الكميات والتكلفة بالصنف تُدار في وحدة المخزون هذه بشكل منفصل تمامًا ومتوازٍ (Subsidiary Ledger)، تمامًا كما contacts تفصّل حساب 1210 المجمّع.

1. مخطط العلاقات (ERD)
1.1 نطاق تعريف الأصناف
mermaid

erDiagram
    TENANTS ||--o{ ITEM_CATEGORIES : "has"
    ITEM_CATEGORIES ||--o{ ITEM_CATEGORIES : "parent_of"
    TENANTS ||--o{ UNITS_OF_MEASURE : "defines"
    TENANTS ||--o{ ITEMS : "has"
    ITEM_CATEGORIES ||--o{ ITEMS : "classifies"
    ITEMS ||--o{ ITEM_UNIT_CONVERSIONS : "has_units"
    UNITS_OF_MEASURE ||--o{ ITEM_UNIT_CONVERSIONS : "used_in"
    ITEMS ||--o{ ITEM_BARCODES : "has"
    ITEMS ||--o{ ITEM_SUPPLIERS : "supplied_by"
    CONTACTS ||--o{ ITEM_SUPPLIERS : "supplies"
1.2 نطاق المخازن والدفعات
mermaid

erDiagram
    TENANTS ||--o{ WAREHOUSES : "has"
    ITEMS ||--o{ ITEM_BATCHES : "has"
    WAREHOUSES ||--o{ ITEM_BATCHES : "stored_in"
    ITEM_BATCHES ||--o{ STOCK_MOVEMENTS : "affected_by"
    ITEMS ||--o{ STOCK_BALANCES : "aggregated_in"
    WAREHOUSES ||--o{ STOCK_BALANCES : "per_warehouse"
    ITEM_BATCHES ||--o{ STOCK_BALANCES : "per_batch"
1.3 نطاق الحركة والتكلفة
mermaid

erDiagram
    TRANSACTIONS ||--o{ STOCK_MOVEMENTS : "generates"
    JOURNAL_ENTRIES ||--o{ STOCK_MOVEMENTS : "financially_linked"
    STOCK_MOVEMENTS ||--o{ STOCK_MOVEMENT_COST_LAYERS : "consumes"
    ITEM_BATCHES ||--o{ STOCK_MOVEMENT_COST_LAYERS : "layer_source"
1.4 نطاق الجرد
mermaid

erDiagram
    TENANTS ||--o{ STOCK_COUNT_SESSIONS : "performs"
    WAREHOUSES ||--o{ STOCK_COUNT_SESSIONS : "counted_in"
    STOCK_COUNT_SESSIONS ||--|{ STOCK_COUNT_LINES : "contains"
    ITEMS ||--o{ STOCK_COUNT_LINES : "counted"
    STOCK_COUNT_SESSIONS ||--o{ STOCK_MOVEMENTS : "produces_adjustment"
2. تفصيل الجداول حقلًا حقلًا
جميع الجداول تحمل الأعمدة القياسية المعرَّفة سابقًا (id UUID, tenant_id, created_at/by, updated_at/by, origin_device_id, lamport_clock, is_deleted) ما لم يُذكر خلاف ذلك.

2.1 warehouses — المخازن/الفروع
الحقل	النوع	القيود	الوصف
name	VARCHAR(100)	NOT NULL	"المخزن الرئيسي"، "فرع عدن"
warehouse_type	VARCHAR(20)	DEFAULT 'general'	general (جرد دوري) | detailed (جرد مستمر)
is_default	BOOLEAN	DEFAULT FALSE	مخزن افتراضي واحد لكل Tenant
address	TEXT	NULL	
is_active	BOOLEAN	DEFAULT TRUE	
ملاحظة: warehouse_type يُستخدم فقط لتبسيط واجهة العرض الافتراضية؛ الحركة الفعلية خلف الكواليس موحّدة كما في القسم 0.3.

2.2 item_categories — تصنيفات الأصناف
الحقل	النوع	القيود
name_ar	VARCHAR(100)	NOT NULL
parent_category_id	UUID	FK self، NULL
is_active	BOOLEAN	DEFAULT TRUE
2.3 units_of_measure — وحدات القياس
الحقل	النوع	القيود	الوصف
name_ar	VARCHAR(30)	NOT NULL	قطعة، كرتون، كيلو، لتر
symbol	VARCHAR(10)	NULL	
is_system_unit	BOOLEAN	DEFAULT FALSE	وحدات افتراضية مشتركة (Seed)
Seed افتراضي: piece (قطعة)، carton (كرتون)، kg، gram، liter، meter، box، dozen.

2.4 🟢 items — الأصناف (الجدول الجوهري)
الحقل	النوع	القيود	الوصف
sku	VARCHAR(50)	NOT NULL	رمز الصنف الداخلي، يُولَّد تلقائيًا إن لم يُدخَل
name_ar	VARCHAR(150)	NOT NULL	
category_id	UUID	FK NULL	
item_type	VARCHAR(20)	NOT NULL	stock (مخزني) | service (خدمي، لا مخزون) | bundle (مركّب — توسع مستقبلي)
base_unit_id	UUID	FK → units_of_measure	وحدة القياس الأساسية للتخزين والتكلفة
tracking_mode	VARCHAR(20)	DEFAULT 'simple'	simple (بلا دفعات/صلاحية) | batch (دفعات) | batch_expiry (دفعات + صلاحية)
costing_method	VARCHAR(20)	DEFAULT 'weighted_average'	weighted_average (افتراضي) — موسّع لاحقًا لـ FIFO
is_aggregate_placeholder	BOOLEAN	DEFAULT FALSE	صنف تجميعي للمخزن العام (قسم 0.3)
min_stock_alert_qty	DECIMAL(18,4)	NULL	حد التنبيه للنقص
default_sale_price	DECIMAL(18,4)	NULL	سعر بيع مقترح (ليس إلزاميًا)
default_purchase_price	DECIMAL(18,4)	NULL	
image_url	TEXT	NULL	
is_active	BOOLEAN	DEFAULT TRUE	
فهارس: UNIQUE(tenant_id, sku)، INDEX(tenant_id, category_id)، INDEX(tenant_id, name_ar) (بحث نصي)

2.5 item_barcodes — الباركود (علاقة واحد لأصناف متعددة باركود)
الحقل	النوع	القيود
item_id	UUID	FK NOT NULL
barcode_value	VARCHAR(50)	UNIQUE(tenant_id, barcode_value)
unit_id	UUID	FK → units_of_measure — باركود مختلف لكل وحدة (كرتون له باركود غير القطعة)
2.6 item_unit_conversions — تحويلات الوحدات
ضرورية للبند "كرتون/قطعة" المطلوب — تُحفَظ كل الوحدات المسموح بها لكل صنف مع معامل التحويل إلى الوحدة الأساسية.

الحقل	النوع	القيود	الوصف
item_id	UUID	FK NOT NULL	
unit_id	UUID	FK NOT NULL	
conversion_factor_to_base	DECIMAL(18,6)	NOT NULL, > 0	مثال: كرتون = 24 (أي 24 قطعة)
is_purchase_default	BOOLEAN	DEFAULT FALSE	الوحدة الافتراضية عند الشراء
is_sale_default	BOOLEAN	DEFAULT FALSE	الوحدة الافتراضية عند البيع
قيد: UNIQUE(item_id, unit_id)، ويجب وجود سجل واحد بـ conversion_factor_to_base = 1 يمثل الوحدة الأساسية نفسها.

2.7 item_suppliers — ربط الصنف بالموردين (لفلترة "حسب المورد")
الحقل	النوع	ملاحظات
item_id	UUID	FK
supplier_contact_id	UUID	FK → contacts
supplier_sku	VARCHAR(50)	رمز الصنف عند المورد (اختياري)
last_purchase_price	DECIMAL(18,4)	يُحدَّث تلقائيًا عند كل شراء
last_purchase_date	DATE	
is_preferred	BOOLEAN	DEFAULT FALSE
2.8 🟢 item_batches — الدفعات (جوهر دعم الصلاحية)
الحقل	النوع	القيود	الوصف
item_id	UUID	FK NOT NULL	
warehouse_id	UUID	FK NOT NULL	
batch_number	VARCHAR(50)	NULL	رقم الدفعة من المورد، أو يُولَّد تلقائيًا
supplier_contact_id	UUID	FK NULL	مصدر هذه الدفعة تحديدًا
manufacture_date	DATE	NULL	
expiry_date	DATE	NULL	إلزامي إن tracking_mode = batch_expiry
received_date	DATE	NOT NULL	
original_qty_base_unit	DECIMAL(18,4)	NOT NULL	الكمية الأصلية عند الاستلام (بالوحدة الأساسية)
unit_cost_base_currency	DECIMAL(18,6)	NOT NULL	تكلفة الوحدة وقت الاستلام (بعملة الأساس)
source_transaction_id	UUID	FK → transactions	
status	VARCHAR(20)	DEFAULT 'active'	active / depleted / expired_written_off
فهارس حرجة للأداء والفلترة المطلوبة:

SQL

INDEX(tenant_id, item_id, expiry_date)       -- "الأقرب انتهاءً"
INDEX(tenant_id, warehouse_id, expiry_date)  -- فلترة الصلاحية بالمخزن
INDEX(tenant_id, supplier_contact_id)        -- فلترة "حسب المورد"
INDEX(tenant_id, received_date DESC)         -- "الأصناف الأحدث"
تصنيف الصلاحية (محسوب عند الاستعلام لا مخزَّن):

text

expiry_status = 
  expiry_date IS NULL          → "لا ينطبق"
  expiry_date < today          → "منتهي الصلاحية"
  expiry_date <= today + 30    → "قريب الانتهاء" (المدة قابلة للتهيئة بالإعدادات)
  else                         → "سليم"
2.9 🟢 stock_movements — دفتر حركة المخزون (مصدر الحقيقة)
الحقل	النوع	القيود	الوصف
item_id	UUID	FK NOT NULL	
warehouse_id	UUID	FK NOT NULL	
batch_id	UUID	FK NULL	NULL إن tracking_mode = simple
movement_type	VARCHAR(30)	NOT NULL	انظر جدول 2.9.1
direction	VARCHAR(10)	NOT NULL	in | out
qty_base_unit	DECIMAL(18,4)	NOT NULL, > 0	دائمًا موجبة؛ الاتجاه يحدد الأثر
unit_cost_base_currency	DECIMAL(18,6)	NOT NULL	تكلفة الوحدة وقت هذه الحركة تحديدًا
total_cost_base_currency	DECIMAL(18,4)	NOT NULL، محسوب	qty × unit_cost
source_transaction_id	UUID	FK → transactions, NULL	
source_journal_entry_id	UUID	FK → journal_entries, NULL	إلزامي إن كانت الحركة ذات أثر مالي
related_stock_count_session_id	UUID	FK NULL	للتسويات الناتجة عن الجرد
transfer_pair_movement_id	UUID	FK self, NULL	يربط حركتي "صادر من مخزن" و"وارد لمخزن" عند التحويل
movement_date	DATE	NOT NULL	
note	TEXT	NULL	
2.9.1 أنواع الحركة (movement_type)
الكود	الاتجاه	المصدر
purchase_receipt	in	قوالب الشراء
sale_issue	out	قوالب البيع
sales_return_receipt	in	مرتجع من عميل
purchase_return_issue	out	مرتجع للمورد
damage_write_off	out	قالب التالف
opening_balance	in	الرصيد الافتتاحي
transfer_out / transfer_in	out/in	تحويل بين مخازن
count_adjustment_increase / _decrease	in/out	تسوية جرد
consumption_internal	out	استخدام داخلي (دواء/قطعة غيار ضمن job)
فهارس:

SQL

INDEX(tenant_id, item_id, movement_date)
INDEX(tenant_id, warehouse_id, movement_date)
INDEX(tenant_id, source_transaction_id)
2.10 🟢 stock_movement_cost_layers — طبقات استهلاك التكلفة
ضرورية لتتبع أي دفعة استُهلكت فعليًا عند البيع، خاصة مع منطق FEFO (الأقرب انتهاءً أولًا).

الحقل	النوع	الوصف
stock_movement_id	UUID FK	حركة "الصرف" (out)
consumed_batch_id	UUID FK	الدفعة التي أُخذت منها الكمية
qty_consumed_base_unit	DECIMAL(18,4)	
unit_cost_at_consumption	DECIMAL(18,6)	
سطر واحد في stock_movements (مثل بيع 10 قطع) قد يُفصَّل إلى عدة cost_layers إن استُهلكت من دفعتين مختلفتين (5 من دفعة قديمة + 5 من جديدة).

2.11 🟢 stock_balances — الرصيد المجمّع (جدول أداء)
لا تُحسب الكمية بجمع كل stock_movements في كل استعلام — هذا يبطئ النظام مع نمو البيانات. هذا الجدول يُحدَّث تدريجيًا (Increment/Decrement) عند كل حركة ضمن نفس المعاملة الذرية (Atomic Transaction).

الحقل	النوع	القيود
item_id	UUID	FK
warehouse_id	UUID	FK
batch_id	UUID	FK NULL
qty_on_hand_base_unit	DECIMAL(18,4)	NOT NULL DEFAULT 0
avg_unit_cost_base_currency	DECIMAL(18,6)	NOT NULL DEFAULT 0
total_value_base_currency	DECIMAL(18,4)	محسوب = qty × avg_cost
last_movement_at	TIMESTAMPTZ	
قيد: UNIQUE(tenant_id, item_id, warehouse_id, COALESCE(batch_id, '00000000-0000-0000-0000-000000000000'))

مستوى تجميع إضافي للأداء (اختياري لكن موصى به): stock_balances_by_item بدون تفصيل مخزن/دفعة، لتسريع شاشة "قائمة الأصناف" الرئيسية.

2.12 stock_count_sessions و stock_count_lines — الجرد
stock_count_sessions

الحقل	النوع	الوصف
warehouse_id	UUID FK	
count_date	DATE	
status	VARCHAR(20)	in_progress / completed / cancelled
counted_by_user_id	UUID	
approved_by_user_id	UUID NULL	يتطلب صلاحية أعلى لاعتماد الفروقات
stock_count_lines

الحقل	النوع	الوصف
session_id	UUID FK	
item_id	UUID FK	
batch_id	UUID FK NULL	
system_qty_base_unit	DECIMAL(18,4)	الكمية الدفترية وقت الجرد (Snapshot)
counted_qty_base_unit	DECIMAL(18,4)	الكمية الفعلية المُدخَلة
variance_qty	DECIMAL(18,4)	محسوب = counted - system
3. محرك التكلفة (Costing Engine) — المتوسط المرجّح مع FEFO
3.1 عند الإدخال (شراء/رصيد افتتاحي) — تحديث المتوسط المرجّح
text

function receiveStock(item_id, warehouse_id, qty, unit_cost, batch_info, context):
    atomic_transaction:
        // 1) إنشاء الدفعة إن كان tracking_mode != simple
        if item.tracking_mode != 'simple':
            batch = createBatch(item_id, warehouse_id, qty, unit_cost, batch_info)
            batch_id = batch.id
        else:
            batch_id = null

        // 2) تسجيل حركة الوارد
        movement = insertStockMovement(
            item_id, warehouse_id, batch_id,
            movement_type='purchase_receipt', direction='in',
            qty, unit_cost
        )

        // 3) تحديث المتوسط المرجّح على مستوى (item, warehouse) دائمًا
        //    وعلى مستوى (item, warehouse, batch) إن وُجدت دفعات
        balance = getOrCreateStockBalance(item_id, warehouse_id, batch_id)

        new_total_value = (balance.qty_on_hand * balance.avg_unit_cost) + (qty * unit_cost)
        new_total_qty   = balance.qty_on_hand + qty
        new_avg_cost    = new_total_qty > 0 ? new_total_value / new_total_qty : 0

        updateStockBalance(balance, qty_on_hand = new_total_qty, avg_unit_cost = new_avg_cost)

        // 4) إن وُجدت دفعات، يُحدَّث أيضًا الرصيد الإجمالي للصنف بالمخزن (بدون تفصيل دفعة)
        //    لتسريع شاشة قائمة الأصناف
        if batch_id is not null:
            updateAggregateItemWarehouseBalance(item_id, warehouse_id, qty, unit_cost)

    return movement
3.2 عند الصرف (بيع/تالف) — استهلاك بمنطق FEFO + حساب COGS
text

function issueStock(item_id, warehouse_id, qty_requested, movement_type, context):
    atomic_transaction:
        if item.tracking_mode == 'simple':
            // لا دفعات: استهلاك مباشر من المتوسط المرجّح العام
            balance = getStockBalance(item_id, warehouse_id, batch_id=null)
            assertSufficientStock(balance.qty_on_hand, qty_requested, allow_negative=tenant.settings.allow_negative_stock)
            cost = balance.avg_unit_cost
            movement = insertStockMovement(item_id, warehouse_id, null, movement_type, 'out', qty_requested, cost)
            updateStockBalance(balance, qty_on_hand -= qty_requested)
            return { movement, total_cost: qty_requested * cost }

        else:
            // مع دفعات: تطبيق FEFO (الأقرب انتهاءً أولًا)، أو FIFO إن لم توجد صلاحية
            available_batches = getActiveBatchesSorted(
                item_id, warehouse_id,
                order_by = item.tracking_mode == 'batch_expiry' ? 'expiry_date ASC NULLS LAST' : 'received_date ASC'
            )

            assertSufficientStock(sum(available_batches.qty), qty_requested, ...)

            remaining = qty_requested
            total_cost = 0
            cost_layers = []

            movement = insertStockMovement(item_id, warehouse_id, batch_id=null /* multi-batch */, 
                                            movement_type, 'out', qty_requested, unit_cost=TBD)

            for batch in available_batches:
                if remaining <= 0: break
                take_qty = min(batch.qty_on_hand, remaining)
                cost_layers.append({ batch_id: batch.id, qty: take_qty, unit_cost: batch.unit_cost })
                total_cost += take_qty * batch.unit_cost
                remaining -= take_qty

                updateBatchBalance(batch.id, qty_on_hand -= take_qty)
                if batch.qty_on_hand == 0:
                    markBatchDepleted(batch.id)

            // تصحيح unit_cost في سطر الحركة الرئيسي = المتوسط الفعلي المستهلك
            finalizeMovementCost(movement.id, unit_cost = total_cost / qty_requested, total_cost)
            insertCostLayers(movement.id, cost_layers)
            updateAggregateItemWarehouseBalance(item_id, warehouse_id, -qty_requested, weighted=true)

            return { movement, total_cost }
3.3 دالة cogs_amount() المستخدمة في قوالب المرحلة السابقة
text

function cogs_amount(payload_items, warehouse_id):
    total = 0
    for line in payload_items:   // كل سطر = {item_id, qty, unit_id}
        qty_base = convertToBaseUnit(line.item_id, line.unit_id, line.qty)
        result = issueStock(line.item_id, warehouse_id, qty_base, 'sale_issue', context)
        total += result.total_cost
        // ربط الحركة بالمعاملة والقيد المالي للمحاسبة المزدوجة الكاملة
        linkMovementToTransaction(result.movement.id, context.transaction_id)
    return total
هذا هو الجسر الفعلي بين وحدة المخزون ومحرك القوالب المصمَّم سابقًا — cogs_amount() لم تعد دالة نظرية بل مرتبطة الآن بخوارزمية استهلاك فعلية.

3.4 معالجة المخزون السالب (قرار تهيئة لا قرار صلب)
الإعداد	tenant.settings.allow_negative_stock
false (افتراضي)	رفض البيع مع رسالة: "الكمية المتوفرة من هذا الصنف X فقط"
true	يُسمح بالبيع، وتُستخدم آخر تكلفة معروفة للصنف، مع تنبيه بصري دائم في شاشة المخزون لـ"أرصدة سالبة تحتاج تسوية"
4. منطق التحويل بين المخازن
text

function transferStock(item_id, from_warehouse_id, to_warehouse_id, qty, context):
    atomic_transaction:
        issue_result = issueStock(item_id, from_warehouse_id, qty, 'transfer_out', context)
        receive_movement = receiveStock(item_id, to_warehouse_id, qty, 
                                         unit_cost = issue_result.total_cost / qty, 
                                         batch_info = null, context)
        linkTransferPair(issue_result.movement.id, receive_movement.id)
    // ملاحظة: لا قيد محاسبي مطلوب إن كان المخزنان ضمن نفس شجرة الحسابات (1310)
    // إلا إن مثّل كل مخزن حسابًا منفصلًا (توسع مستقبلي للفروع المستقلة ماليًا)
5. جلسة الجرد ومعالجة الفروقات
text

function completeStockCount(session_id, context):
    session = getSession(session_id)
    requirePermission(context.user, 'inventory.approve_count')

    for line in getSessionLines(session_id):
        variance = line.counted_qty_base_unit - line.system_qty_base_unit
        if variance == 0: continue

        if variance > 0:
            // زيادة: دخول بتكلفة آخر معروفة (لا ربح وهمي بتكلفة صفر)
            receiveStock(line.item_id, session.warehouse_id, variance, 
                         unit_cost = getLastKnownCost(line.item_id), batch_info=null, context)
            movement_type = 'count_adjustment_increase'
        else:
            issueStock(line.item_id, session.warehouse_id, abs(variance), 
                      'count_adjustment_decrease', context)

        // قيد محاسبي تلقائي للفروقات (ربط بحساب 5701 تالف/عجز أو حساب عجز مخزون مخصص)
        createJournalEntryForVariance(line, variance, context)

    markSessionCompleted(session_id)
6. مواصفات API
6.1 الأصناف
Method	Path	الوصف
GET	/items?search=&category_id=&page=&limit=	قائمة مع بحث نصي وفلترة
GET	/items/{id}	تفاصيل صنف + أرصدته بكل مخزن
POST	/items	إنشاء صنف
PATCH	/items/{id}	تعديل
DELETE	/items/{id}	حذف منطقي (مرفوض إن وُجدت حركات)
POST	/items/{id}/barcodes	إضافة باركود
POST	/items/{id}/units	إضافة وحدة تحويل
GET	/items/{id}/batches?expiry_status=&supplier_id=&sort=	الفلترة المطلوبة: حسب المورد والصلاحية
GET	/items/low-stock	الأصناف تحت حد التنبيه
GET	/items/expiring-soon?days=30	عبر كل الأصناف
نموذج Response لـ GET /items/{id}/batches?expiry_status=expiring_soon:

JSON

{
  "data": [
    {
      "batch_id": "uuid", "batch_number": "B-2024-11",
      "supplier_name": "مؤسسة النور للأدوية",
      "expiry_date": "2025-02-10", "expiry_status": "expiring_soon",
      "qty_on_hand": 45, "unit_cost": 120.5, "total_value": 5422.5
    }
  ],
  "meta": { "total_items_affected": 1 }
}
6.2 حركة المخزون والمخازن
Method	Path	الوصف
GET	/warehouses	قائمة المخازن/الفروع
POST	/warehouses	إنشاء مخزن جديد
GET	/stock-movements?item_id=&warehouse_id=&date_from=&date_to=&type=	كشف حركة صنف (Stock Card)
POST	/stock-transfers	تحويل بين مخزنين
GET	/stock-balances?warehouse_id=&low_stock_only=	أرصدة حالية
نموذج Request لـ POST /stock-transfers:

JSON

{
  "item_id": "uuid", "from_warehouse_id": "uuid", "to_warehouse_id": "uuid",
  "qty": 10, "unit_id": "uuid-كرتون", "transfer_date": "2025-01-15", "note": "تزويد فرع عدن"
}
6.3 الجرد
Method	Path	الوصف
POST	/stock-count-sessions	فتح جلسة جرد لمخزن
GET	/stock-count-sessions/{id}	عرض الجلسة وأسطرها (كميات دفترية مُهيَّأة مسبقًا)
PATCH	/stock-count-sessions/{id}/lines/{line_id}	إدخال الكمية الفعلية
POST	/stock-count-sessions/{id}/complete	اعتماد وتوليد تسويات + قيود
6.4 دعم شاشة الشراء/البيع (Quick Lookup)
Method	Path	الوصف
GET	/items/lookup?barcode=	بحث فوري بالباركود (كاميرا)
GET	/items/lookup?query=	بحث نصي سريع للـ item_picker
7. الأداء والتوسع (توصيات حرجة)
الممارسة	السبب
تحديث stock_balances ضمن نفس Transaction الذرية للحركة	يمنع عدم تطابق الرصيد المجمّع مع الحركات الفعلية
Partitioning لجدول stock_movements شهريًا	أسرع الجداول نموًا بعد journal_lines
Index مركّب (tenant_id, item_id, warehouse_id) على stock_balances	أساس كل استعلام رصيد
Cache محلي (SQLite) لقائمة الأصناف الأكثر استخدامًا	تسريع item_picker أثناء الإدخال السريع بدون اتصال
lazy loading للدفعات	لا تُحمَّل تفاصيل الدفعات إلا عند فتح شاشة صنف محدد، لا في القائمة العامة
حساب expiry_status ديناميكيًا لا تخزينه	يتجنب Job يومي لتحديث حالات الصلاحية عبر ملايين السجلات
8. التكامل مع نظام الخدمات (Jobs) — استهلاك داخلي
لربط استخدام "قطعة غيار" أو "دواء" ضمن job (من المرحلة السابقة):

JSON

{
  "template_code": "job_item_consumption",
  "template_version": 1,
  "scope": ["clinic", "workshop"],
  "category": "services",
  "ui": { "button_group_ar": "استخدام من المخزون", "display_name_ar": "صرف قطعة/دواء لملف", "icon": "box_minus",
          "description_ar": "استخدمت صنف من المخزون ضمن هذا الملف", "sort_order": 7 },
  "inventory_effect": "decrease",
  "fields": [
    { "key": "job_id", "type": "select", "label_ar": "الملف", "required": true, "options_source": "open_jobs()" },
    { "key": "items", "type": "item_picker", "label_ar": "الأصناف المستخدمة", "required": true },
    { "key": "warehouse_id", "type": "select", "label_ar": "من أي مخزن؟", "required": true, "options_source": "warehouses()" }
  ],
  "journal_rules": [
    { "account_code_ref": "5120", "side": "debit", "amount_formula": "cogs_amount()" },
    { "account_code_ref": "1320", "side": "credit", "amount_formula": "cogs_amount()" }
  ],
  "post_actions": ["link_movement_to_job({{job_id}})"]
}
9. حوكمة واختبارات الجودة
القاعدة	الآلية
stock_balances.qty_on_hand يجب أن يساوي دائمًا SUM(stock_movements) لنفس المفتاح	اختبار تسوية (Reconciliation Test) دوري آلي يقارن الجدولين
لا حركة out دون cost_layers مكتملة تساوي qty_requested بالضبط	Unit Test على issueStock
كل حركة مالية الأثر تحمل source_journal_entry_id غير فارغ	قيد CHECK + اختبار تكامل
اختبار Fuzz لاستهلاك FEFO: عدة دفعات بصلاحيات متداخلة، تحقق من ترتيب الاستهلاك الصحيح دائمًا	Unit Test إلزامي قبل الإطلاق
اختبار التحويل بين مخزنين لا يُغيّر القيمة الإجمالية للمخزون ككل	Invariant Test
اختبار الجرد: فروقات موجبة وسالبة تنتج قيودًا متوازنة دومًا	Golden Test Case
10. خلاصة وتوصيات
stock_movements هو "دفتر اليومية" الخاص بالمخزون — بنفس قداسة journal_entries المالية: Append-only، لا تعديل، لا حذف.
ابدأ بتفعيل tracking_mode = simple فقط للإطلاق الأول (حتى للتجزئة)، وفعّل batch/batch_expiry تدريجيًا بعد التأكد من صلابة محرك FEFO — فالتعقيد الإضافي يستحق الاستثمار لاحقًا لا في أول إصدار.
لا تُطلق "الوضع التفصيلي" للبيع (أصناف وكميات) قبل اجتياز اختبارات التسوية (القسم 9) 100% — خطأ هنا يُنتج قيم مخزون وتكلفة بضاعة خاطئة تتراكم بصمت وتكتشف متأخرًا جدًا.
وحّد منطق الجرد الدوري والمستمر في نفس الجداول كما في القسم 0.3 — يوفر إعادة هيكلة مكلفة جدًا إذا احتاج تاجر "جرد دوري" للترقية لاحقًا لتتبع تفصيلي.
اربط item_suppliers.last_purchase_price بتحديث تلقائي من قالب purchase_credit/cash/partial فور اعتماده، فهذا يُغذّي مستقبلًا ميزة "اقتراح سعر الشراء" بذكاء دون جهد إضافي.
الخطوة التالية المقترحة: تصميم وحدة الذمم المدينة والدائنة التفصيلية (AR/AP Aging Engine) — آلية ربط التحصيل/السداد بفواتير محددة (allocate_to_invoice المذكورة سابقًا)، وحساب أعمار الديون؛ أو الانتقال إلى تصميم Wireframes الشاشات الفعلية. أيهما تفضل؟




ابدأ بتصميم وحدة النخزون التفصيلية.....
بأفضل الممارسات والأساليب وبأداء احترافي.
