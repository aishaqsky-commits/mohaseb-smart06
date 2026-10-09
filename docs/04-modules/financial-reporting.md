claude-sonnet-5-high
تصميم وحدة التقارير المالية الموحّدة
(Financial Reporting Engine) — بأفضل الممارسات
0. قرارات تصميمية وتصحيحات ضرورية قبل البدء
0.1 المشكلة الجوهرية: لماذا لا يصح حساب التقارير من journal_lines مباشرة؟
مع نمو البيانات نحو 5 ملايين مستخدم، استعلام مثل "اجمع كل حركات حساب المبيعات منذ بداية النشاط" سيصبح بطيئًا جدًا إن نُفِّذ كـ SUM() حي على جدول يحوي ملايين الصفوف في كل مرة يُفتح فيها تقرير. هذا يكرر نفس المشكلة التي حللناها في stock_balances وcontact_balances — والحل هو نفس المبدأ: فصل مصدر الحقيقة (Ledger) عن الرصيد المجمّع (Aggregate).

0.2 المبدأ المعماري: نموذج "الفترات الساخنة والباردة" (Hot/Cold Period Model)
هذا معيار صناعي معتمد في أنظمة ERP الكبرى: الفترة المحاسبية المفتوحة الحالية تُحسب أرصدتها حيًّا (بيانات قليلة الحجم، أيام أو أسابيع)، بينما الفترات المُقفَلة تُجمَّد في لقطة (Snapshot) ثابتة لا تُعاد حسابتها أبدًا. هذا يحل مشكلتين معًا:

الأداء: لا مسح لملايين السجلات القديمة أبدًا.
صحة التعديل بأثر رجعي: إقفال الفترة يمنع القيود المتأخرة فيها، فلا حاجة لإعادة حساب تسلسلي (Cascading Recalculation) عند كل تعديل.
0.3 تفريق ضروري بين نوعين من "الإقفال" (كان غامضًا سابقًا)
النوع	الغرض	الصرامة
إقفال اليوم (Day Close)	تسوية نقدية يومية وتقرير نتيجة اليوم	مرن، قابل لإعادة الفتح بسهولة
إقفال الفترة المحاسبية (Period Close)	شهر/سنة — يمنع القيود بأثر رجعي رسميًا	صارم، يتطلب صلاحية خاصة لإعادة الفتح مع سجل تدقيق
0.4 تصحيح على journal_entries من التصميم السابق
إضافة حقل للربط بالفترة المحاسبية:

الحقل الجديد	النوع	الوصف
fiscal_period_id	UUID NULL FK → fiscal_periods.id	يُحدَّد تلقائيًا عند الترحيل حسب entry_date
قيد إلزامي جديد في محرك القيد (Journal Engine):

text

قبل قبول أي journal_entry جديد:
    period = resolveFiscalPeriod(tenant_id, entry_date)
    IF period.status == 'closed':
        REJECT "الفترة المحاسبية لهذا التاريخ مُقفَلة، لا يمكن الترحيل فيها"
1. مخطط العلاقات (ERD)
mermaid

erDiagram
    TENANTS ||--o{ FISCAL_PERIODS : "defines"
    FISCAL_PERIODS ||--o{ ACCOUNT_PERIOD_BALANCES : "freezes"
    ACCOUNTS ||--o{ ACCOUNT_PERIOD_BALANCES : "snapshot_of"
    TENANTS ||--o{ ACCOUNT_RUNNING_BALANCES : "live_tracks"
    ACCOUNTS ||--o{ ACCOUNT_RUNNING_BALANCES : "current_period"
    TENANTS ||--o{ DAILY_CLOSURES : "performs"
    TENANTS ||--o{ DAILY_BUSINESS_RESULTS : "aggregates"
    TENANTS ||--o{ REPORT_DEFINITIONS : "enables"
    USERS ||--o{ REPORT_EXECUTION_LOG : "runs"
2. تفصيل الجداول حقلًا حقلًا
2.1 🟢 fiscal_periods — الفترات المحاسبية الرسمية
الحقل	النوع	القيود	الوصف
period_type	VARCHAR(10)	NOT NULL	month | year
period_key	VARCHAR(10)	NOT NULL	"2025-01" أو "2025"
start_date	DATE	NOT NULL	
end_date	DATE	NOT NULL	
status	VARCHAR(20)	DEFAULT 'open'	open / closed
closed_by_user_id	UUID	NULL	
closed_at	TIMESTAMPTZ	NULL	
reopened_by_user_id	UUID	NULL	
reopened_at	TIMESTAMPTZ	NULL	
reopen_reason	TEXT	NULL	إلزامي عند إعادة الفتح
فهارس: UNIQUE(tenant_id, period_type, period_key)، INDEX(tenant_id, start_date, end_date)

قاعدة توليد تلقائي: يُنشئ النظام فترة الشهر الحالي تلقائيًا عند أول قيد يُسجَّل فيه (Lazy Creation)، لا حاجة لمعالج يدوي يُنشئ 12 شهرًا مسبقًا.

2.2 🟢 account_period_balances — اللقطة المجمّدة (Cold Data)
تُنشأ مرة واحدة فقط عند إقفال الفترة، ولا تُعدَّل أبدًا بعدها.

الحقل	النوع	الوصف
fiscal_period_id	UUID FK	
account_id	UUID FK	
opening_balance_base	DECIMAL(18,4)	رصيد بداية الفترة
period_debit_total_base	DECIMAL(18,4)	إجمالي حركة مدين خلال الفترة
period_credit_total_base	DECIMAL(18,4)	إجمالي حركة دائن خلال الفترة
closing_balance_base	DECIMAL(18,4)	رصيد نهاية الفترة (محسوب)
فهارس: UNIQUE(tenant_id, fiscal_period_id, account_id)

2.3 🟢 account_running_balances — الرصيد الحي (Hot Data)
يُحدَّث تدريجيًا ضمن نفس Transaction الذرية لكل قيد يُرحَّل في الفترة المفتوحة الحالية — تمامًا كآلية stock_balances وcontact_balances سابقًا.

الحقل	النوع	الوصف
account_id	UUID FK	
current_fiscal_period_id	UUID FK	الفترة المفتوحة الحالية
opening_balance_base	DECIMAL(18,4)	= closing_balance_base من آخر فترة مُقفَلة
period_debit_total_base	DECIMAL(18,4)	يتراكم مع كل قيد جديد
period_credit_total_base	DECIMAL(18,4)	يتراكم مع كل قيد جديد
current_balance_base	DECIMAL(18,4)	محسوب = opening + net movement
last_updated_at	TIMESTAMPTZ	
فهرس: UNIQUE(tenant_id, account_id) — سجل واحد فقط لكل حساب (يمثّل الفترة المفتوحة دائمًا).

2.4 🟢 daily_closures — إقفال اليوم (مرن)
الحقل	النوع	الوصف
warehouse_id	UUID NULL	اختياري إن أراد التاجر إقفالًا لكل فرع
business_date	DATE	NOT NULL
status	VARCHAR(20)	open / closed
cash_expected_balance	DECIMAL(18,4)	محسوب من الحركات
cash_actual_counted	DECIMAL(18,4)	NULL، يُدخله المستخدم عند الإقفال
cash_variance	DECIMAL(18,4)	محسوب = actual - expected
total_revenue_base	DECIMAL(18,4)	
total_expenses_base	DECIMAL(18,4)	
net_result_base	DECIMAL(18,4)	
closed_by_user_id	UUID	NULL
closed_at	TIMESTAMPTZ	NULL
فهرس: UNIQUE(tenant_id, warehouse_id, business_date)

2.5 🟢 daily_business_results — الجدول التجميعي للنتيجة اليومية
هذا هو الجدول الأهم لتحقيق متطلب "نتيجة النشاط على مستوى اليوم" بأداء فوري. يُحدَّث تدريجيًا عند كل معاملة (Increment)، لا يُحسب بالمسح الكامل أبدًا.

الحقل	النوع	الوصف
business_date	DATE	NOT NULL
revenue_total_base	DECIMAL(18,4)	
cogs_total_base	DECIMAL(18,4)	تكلفة البضاعة/الخدمة المباعة
gross_profit_base	DECIMAL(18,4)	محسوب
expenses_total_base	DECIMAL(18,4)	يشمل حصة المصروفات الموزَّعة المستهلكة لهذا اليوم
net_profit_base	DECIMAL(18,4)	محسوب
cash_in_base	DECIMAL(18,4)	
cash_out_base	DECIMAL(18,4)	
transactions_count	INTEGER	
فهرس: UNIQUE(tenant_id, business_date)

آلية التحديث (Hook في محرك تنفيذ القوالب من المرحلة السابقة):

text

بعد نجاح أي executeTemplate():
    IF template.category IN ['sales','services']:
        incrementDailyResult(transaction_date, revenue += amount, cogs += cogs_amount)
    IF template.category == 'expenses':
        incrementDailyResult(transaction_date, expenses += amount)
    IF line.account_code IN ['1101','1110','1120']:
        incrementDailyResult(transaction_date, cash_in/cash_out += amount)
2.6 🟢 report_definitions — سجل التقارير (قابلية التوسع)
يحقق متطلب "إمكانية إضافة أي تقارير أخرى بسهولة لاحقًا" بنفس فلسفة template_registry المعتمدة سابقًا.

الحقل	النوع	الوصف
report_code	VARCHAR(50) UNIQUE	trial_balance, income_statement...
name_ar	VARCHAR(100)	
category	VARCHAR(30)	financial / operational / inventory / ar_ap
description_ar	TEXT	
data_source_type	VARCHAR(20)	hybrid / live_query / materialized
required_permission	VARCHAR(100)	FK منطقي → permissions.code
supported_filters	JSONB	["date_range","warehouse_id","contact_id"]
is_system_report	BOOLEAN	
is_active	BOOLEAN	يُستخدم للتحكم عن بُعد بإخفاء/إظهار تقرير
sort_order	SMALLINT	
2.7 report_execution_log — سجل تنفيذ التقارير (تدقيق وأداء)
الحقل	النوع	الوصف
report_code	VARCHAR(50)	
user_id	UUID	
filters_used	JSONB	
execution_time_ms	INTEGER	لرصد التقارير البطيئة
exported_format	VARCHAR(10)	NULL / pdf / excel
3. محرك الأرصدة الهجين (Hybrid Balance Engine)
3.1 حساب رصيد حساب معيّن حتى تاريخ محدد (Balance Sheet Logic)
text

function getAccountBalanceAsOf(account_id, as_of_date, context):
    period = resolveFiscalPeriod(context.tenant, as_of_date)

    IF period.status == 'closed':
        // الفترة مُقفَلة: القراءة من اللقطة المجمّدة مباشرة (سريع جدًا)
        snapshot = getAccountPeriodBalance(account_id, period.id)
        RETURN snapshot.closing_balance_base

    ELSE:
        // الفترة مفتوحة: الرصيد الحي + أي حركة إضافية حتى as_of_date إن لم يكن اليوم الحالي
        running = getAccountRunningBalance(account_id)
        IF as_of_date == today:
            RETURN running.current_balance_base
        ELSE:
            // تاريخ ماضٍ ضمن الفترة المفتوحة فقط (حجم بيانات محدود - أيام قليلة)
            movements_after = queryJournalLines(account_id, date > as_of_date, date <= today)
            RETURN running.current_balance_base - netMovement(movements_after)
3.2 حساب نشاط حساب خلال فترة زمنية (Income Statement Logic)
text

function getAccountActivityForRange(account_id, date_from, date_to, context):
    periods_involved = resolveFiscalPeriodsOverlapping(date_from, date_to)
    total_debit = 0
    total_credit = 0

    FOR period IN periods_involved:
        IF period.status == 'closed':
            snapshot = getAccountPeriodBalance(account_id, period.id)
            total_debit += snapshot.period_debit_total_base
            total_credit += snapshot.period_credit_total_base
        ELSE:
            // الفترة المفتوحة: استعلام حي (محدود الحجم بطبيعته)
            lines = queryJournalLines(account_id, date_from, date_to) WITHIN period
            total_debit += sum(lines.debit)
            total_credit += sum(lines.credit)

    RETURN { total_debit, total_credit }
ملاحظة أداء حرجة: إذا طلب المستخدم تقريرًا يمتد لعدة فترات مُقفَلة (مثال: "قائمة دخل لآخر 6 أشهر")، الاستعلام يقرأ 6 صفوف فقط لكل حساب من account_period_balances بدلًا من مسح آلاف القيود — هذا هو جوهر تحقيق الأداء الاحترافي المطلوب.

4. محرك إقفال الفترات (Period Closing Engine)
4.1 خوارزمية إقفال فترة شهرية
text

function closeFiscalPeriod(fiscal_period_id, context):
    requirePermission(context.user, 'periods.close')
    period = getFiscalPeriod(fiscal_period_id)
    ASSERT period.status == 'open'

    atomic_transaction:
        accounts = getAllPostableAccounts(context.tenant)

        FOR account IN accounts:
            running = getAccountRunningBalance(account.id)
            insert(account_period_balances, {
                fiscal_period_id: period.id,
                account_id: account.id,
                opening_balance_base: running.opening_balance_base,
                period_debit_total_base: running.period_debit_total_base,
                period_credit_total_base: running.period_credit_total_base,
                closing_balance_base: running.current_balance_base
            })

        // إن كانت فترة سنوية: ترحيل أرباح/خسائر الإيرادات والمصروفات إلى الأرباح المرحّلة
        IF period.period_type == 'year':
            net_income = sumRevenueAndExpenseAccounts(accounts)
            createClosingJournalEntry(
                debit: revenue_accounts (لتصفيرها),
                credit: expense_accounts (لتصفيرها),
                balancing_line: account_3300 (أرباح مرحّلة) += net_income
            )

        markPeriodClosed(period.id, context.user.id)
        createNextPeriod(period)  // ينشئ الفترة التالية ويهيّئ account_running_balances الجديدة
        
        // تصفير account_running_balances لحسابات الإيرادات/المصروفات فقط عند إقفال سنوي
        IF period.period_type == 'year':
            resetRunningBalancesForNominalAccounts(revenue_and_expense_accounts)

    logAudit('period_closed', period.id, context.user.id)
4.2 خوارزمية إعادة فتح فترة (صلاحية حرجة)
text

function reopenFiscalPeriod(fiscal_period_id, reason, context):
    requirePermission(context.user, 'periods.reopen')  // صلاحية أعلى من الإقفال نفسه
    
    period = getFiscalPeriod(fiscal_period_id)
    ASSERT period.status == 'closed'
    ASSERT getNextPeriod(period).status == 'open'  // يُمنع فتح فترة ليست الأحدث مُقفَلة (تسلسل إلزامي)

    atomic_transaction:
        // استعادة الأرصدة من اللقطة إلى الجدول الحي مؤقتًا
        restoreRunningBalancesFromSnapshot(period)
        deleteAccountPeriodBalances(period.id)  // ستُعاد عند الإقفال مجددًا
        markPeriodOpen(period.id, context.user.id, reason)

    logAudit('period_reopened', period.id, context.user.id, reason)  // إلزامي في audit_log
    notifyTenantOwner('تم إعادة فتح فترة محاسبية مُقفَلة بواسطة ' + context.user.name)
4.3 خوارزمية إقفال اليوم (مرن، منفصل عن القفل المحاسبي الصارم)
text

function closeBusinessDay(business_date, warehouse_id, actual_cash_counted, context):
    expected = getDailyBusinessResult(business_date)
    expected_cash = calculateExpectedCashBalance(business_date, warehouse_id)
    
    upsert(daily_closures, {
        business_date, warehouse_id,
        cash_expected_balance: expected_cash,
        cash_actual_counted: actual_cash_counted,
        cash_variance: actual_cash_counted - expected_cash,
        total_revenue_base: expected.revenue_total_base,
        total_expenses_base: expected.expenses_total_base,
        net_result_base: expected.net_profit_base,
        status: 'closed', closed_by_user_id: context.user.id, closed_at: now()
    })

    IF abs(cash_variance) > 0:
        suggestVarianceAdjustmentTemplate(cash_variance)  // اقتراح قيد "عجز/زيادة صندوق" من قوالب المرحلة السابقة
لا يمنع إقفال اليوم القيود المستقبلية بتاريخ ذلك اليوم (بعكس إقفال الفترة الشهرية) — فقط يُسجّل لقطة تسوية ويُنبّه بالفروقات، تماشيًا مع المرونة المطلوبة للتاجر غير المختص.

5. كتالوج التقارير المعتمدة (Seed لـ report_definitions)
JSON

[
  { "report_code": "trial_balance", "name_ar": "ميزان المراجعة", "category": "financial",
    "data_source_type": "hybrid", "supported_filters": ["as_of_date"], "is_system_report": true },

  { "report_code": "income_statement", "name_ar": "قائمة الدخل", "category": "financial",
    "data_source_type": "hybrid", "supported_filters": ["date_from","date_to"], "is_system_report": true },

  { "report_code": "balance_sheet", "name_ar": "الميزانية العمومية", "category": "financial",
    "data_source_type": "hybrid", "supported_filters": ["as_of_date"], "is_system_report": true },

  { "report_code": "daily_result", "name_ar": "نتيجة نشاط اليوم", "category": "operational",
    "data_source_type": "materialized", "supported_filters": ["business_date","warehouse_id"], "is_system_report": true },

  { "report_code": "period_result", "name_ar": "نتيجة نشاط فترة (أسبوع/شهر/مخصص)", "category": "operational",
    "data_source_type": "hybrid", "supported_filters": ["date_from","date_to"], "is_system_report": true },

  { "report_code": "cash_book", "name_ar": "دفتر النقدية", "category": "financial",
    "data_source_type": "live_query", "supported_filters": ["date_from","date_to","account_id"], "is_system_report": true },

  { "report_code": "general_ledger", "name_ar": "دفتر الأستاذ العام", "category": "financial",
    "data_source_type": "live_query", "supported_filters": ["account_id","date_from","date_to"], "is_system_report": true },

  { "report_code": "journal_book", "name_ar": "دفتر اليومية", "category": "financial",
    "data_source_type": "live_query", "supported_filters": ["date_from","date_to"], "is_system_report": true },

  { "report_code": "ar_aging", "name_ar": "أعمار الذمم المدينة", "category": "ar_ap",
    "data_source_type": "live_query", "supported_filters": ["as_of_date"], "is_system_report": true },

  { "report_code": "ap_aging", "name_ar": "أعمار الذمم الدائنة", "category": "ar_ap",
    "data_source_type": "live_query", "supported_filters": ["as_of_date"], "is_system_report": true },

  { "report_code": "fx_impact_report", "name_ar": "تقرير فروق العملة", "category": "financial",
    "data_source_type": "live_query", "supported_filters": ["date_from","date_to"], "is_system_report": true,
    "description_ar": "يفصل الربح التشغيلي عن أثر تقلب سعر الصرف - مهم جدًا للسوق اليمني" }
]
6. تفصيل منطق التقارير الرئيسية
6.1 ميزان المراجعة (trial_balance)
text

function generateTrialBalance(as_of_date, context):
    accounts = getAllPostableAccounts(context.tenant)
    rows = []
    total_debit = 0; total_credit = 0

    FOR account IN accounts:
        balance = getAccountBalanceAsOf(account.id, as_of_date, context)
        IF balance == 0: continue  // لا تُعرض الحسابات الصفرية
        
        side = (account.normal_balance == 'debit' AND balance >= 0) OR 
               (account.normal_balance == 'credit' AND balance < 0) ? 'debit' : 'credit'
        
        rows.append({ account_code, account_name, debit: side=='debit'?abs(balance):0, 
                       credit: side=='credit'?abs(balance):0 })
        total_debit += row.debit
        total_credit += row.credit

    ASSERT total_debit == total_credit  // ضمان صحي (Sanity Check) قبل الإرجاع
    RETURN { rows, total_debit, total_credit }
6.2 قائمة الدخل (income_statement)
text

function generateIncomeStatement(date_from, date_to, context):
    revenue_accounts = getAccountsByType('revenue')
    expense_accounts = getAccountsByType('expense')

    revenue_lines = []
    FOR account IN revenue_accounts:
        activity = getAccountActivityForRange(account.id, date_from, date_to, context)
        net = activity.total_credit - activity.total_debit  // طبيعة الإيراد دائنة
        IF net != 0: revenue_lines.append({ account, amount: net })

    expense_lines = []
    FOR account IN expense_accounts:
        activity = getAccountActivityForRange(account.id, date_from, date_to, context)
        net = activity.total_debit - activity.total_credit  // طبيعة المصروف مدينة
        IF net != 0: expense_lines.append({ account, amount: net })

    total_revenue = sum(revenue_lines.amount)
    cogs = sum(expense_lines WHERE account.code STARTS_WITH '51')  // تكلفة المبيعات
    gross_profit = total_revenue - cogs
    operating_expenses = sum(expense_lines WHERE NOT STARTS_WITH '51')
    net_profit = gross_profit - operating_expenses

    RETURN { revenue_lines, cogs, gross_profit, expense_lines, operating_expenses, net_profit }
6.3 نتيجة نشاط اليوم (daily_result) — الأسرع في كامل النظام
text

function getDailyResult(business_date, warehouse_id, context):
    RETURN SELECT * FROM daily_business_results 
           WHERE tenant_id = context.tenant AND business_date = business_date
    // قراءة سجل واحد فقط - زمن استجابة أقل من 50ms حتى مع ملايين المستخدمين
6.4 تقرير فروق العملة (fx_impact_report) — يحقق توصية سابقة مهمة
text

function generateFxImpactReport(date_from, date_to, context):
    operating_net_profit = generateIncomeStatement(date_from, date_to, context).net_profit
    
    fx_gains = sumAllocations(fx_gain_loss_amount > 0, date_from, date_to)
    fx_losses = sumAllocations(fx_gain_loss_amount < 0, date_from, date_to)
    net_fx_impact = fx_gains - abs(fx_losses)
    
    RETURN {
        operating_net_profit,          // الربح الحقيقي من النشاط
        net_fx_impact,                  // أثر تقلب الصرف فقط
        total_reported_profit: operating_net_profit + net_fx_impact,
        warning_ar: net_fx_impact != 0 ? 
            "جزء من ربحك ناتج عن تغيّر سعر الصرف وليس من نشاطك التجاري الفعلي" : null
    }
7. مواصفات API
7.1 نقطة نهاية موحّدة للتقارير (Generic Report Endpoint)
Method	Path	الوصف
GET	/reports	قائمة التقارير المتاحة (من report_definitions، مفلترة حسب صلاحيات المستخدم)
GET	/reports/{report_code}?filters...	تنفيذ أي تقرير عبر محرك موحّد
POST	/reports/{report_code}/export	تصدير PDF/Excel
نموذج Response لـ GET /reports:

JSON

{
  "data": [
    { "report_code": "daily_result", "name_ar": "نتيجة نشاط اليوم", "category": "operational" },
    { "report_code": "trial_balance", "name_ar": "ميزان المراجعة", "category": "financial" }
  ]
}
نموذج Response لـ GET /reports/income_statement?date_from=2025-01-01&date_to=2025-01-31:

JSON

{
  "data": {
    "period": { "from": "2025-01-01", "to": "2025-01-31" },
    "revenue": { "total": 450000, "lines": [{ "account": "إيرادات المبيعات", "amount": 450000 }] },
    "cogs": 280000,
    "gross_profit": 170000,
    "operating_expenses": { "total": 65000, "lines": [...] },
    "net_profit": 105000
  },
  "meta": { "generated_from": "hybrid", "execution_time_ms": 42 }
}
7.2 إقفال الفترات
Method	Path	الوصف
GET	/fiscal-periods?status=	قائمة الفترات وحالاتها
POST	/fiscal-periods/{id}/close	إقفال فترة (صلاحية محاسب/مالك)
POST	/fiscal-periods/{id}/reopen	إعادة فتح (صلاحية مالك فقط + سبب إلزامي)
7.3 إقفال اليوم
Method	Path	الوصف
GET	/daily-closures/{date}/preview	معاينة قبل الإقفال (الفلوس المتوقعة)
POST	/daily-closures/{date}/close	تنفيذ الإقفال مع إدخال الكاش الفعلي
GET	/daily-closures?date_from=&date_to=	سجل إقفالات سابقة
8. الأداء والتخزين المؤقت (توصيات حرجة للتوسع)
الممارسة	السبب
تحديث account_running_balances وdaily_business_results ضمن نفس Transaction الذرية للقيد	يضمن تطابق الأرقام دومًا، كما في stock_balances
Partitioning لـ account_period_balances حسب fiscal_period_id	قراءة سريعة لفترة محددة دون مسح كل التاريخ
Cache للتقارير الثقيلة (income_statement لفترة طويلة) لمدة دقائق معدودة	تقليل الحمل عند تكرار نفس الطلب
حد أقصى لحجم الاستعلام الحي في الفترة المفتوحة (مثال: إن تجاوزت الفترة المفتوحة 45 يومًا دون إقفال، يُنبَّه التاجر)	يمنع تدهور الأداء إن أهمل التاجر الإقفال الدوري
فهرسة journal_lines(account_id, entry_date) مستخدمة من هذه الوحدة مباشرة	مُعرَّفة مسبقًا في تصميم المحاسبة الأساسي
تنفيذ closeFiscalPeriod كمهمة خلفية (Background Job) لا طلب API متزامن إن كان عدد الحسابات كبيرًا	يمنع Timeout على التطبيق
9. حوكمة واختبارات الجودة
القاعدة	الآلية
account_running_balances.current_balance_base يساوي دائمًا المجموع الفعلي من journal_lines للفترة المفتوحة	اختبار تسوية دوري (كنظيراتها في المخزون والذمم)
SUM(trial_balance.debit) == SUM(trial_balance.credit) دائمًا	Assertion إلزامي قبل إرجاع أي استجابة
لا قيد يُرحَّل بتاريخ يقع ضمن فترة closed	اختبار تكامل على محرك القيد (القسم 0.4)
إعادة فتح فترة تتطلب صلاحية أعلى من إقفالها + سجل تدقيق إلزامي	Integration Test + مراجعة صلاحيات
اختبار "اليوم الطويل": تاجر لم يُقفل حسابه لـ 60 يومًا، التحقق من استمرار الأداء المقبول	Load Test
قائمة الدخل لفترة تمتد عبر فترتين (واحدة مُقفَلة وواحدة مفتوحة) تُعطي نفس النتيجة كما لو حُسبت حيًّا بالكامل	Golden Test الأهم في هذه الوحدة
10. خلاصة وتوصيات
نموذج الفترات الساخنة/الباردة هو الفيصل بين تطبيق يتباطأ بعد سنة من الاستخدام وآخر يبقى سريعًا عند 5 ملايين مستخدم — لا تؤجل بناء account_period_balances وaccount_running_balances لمرحلة لاحقة، فإعادة هيكلة محرك الأرصدة بعد تراكم بيانات حقيقية مكلفة جدًا.
لا تفرض إقفال الفترة الشهرية إجباريًا على التاجر العادي — اجعلها ميزة يُفعِّلها المحاسب أو المالك متى احتاجها، بينما إقفال اليوم المرن يبقى التجربة الافتراضية لغير المختصين، تماشيًا مع فلسفة التبسيط المعتمدة من بداية المشروع.
daily_business_results يجب أن يُحدَّث من نفس Hook الذي يُحدِّث stock_balances وcontact_balances — صمّم طبقة "ما بعد التنفيذ" (Post-Execution Hooks) موحّدة في محرك القوالب تستدعي كل هذه التحديثات معًا ذريًّا، بدل وحدات منفصلة قد تتعارض.
تقرير فروق العملة (fx_impact_report) يجب أن يظهر بشكل بارز في لوحة التاجر الرئيسية لا كتقرير مدفون بين التقارير الأخرى — هذا يحقق توصية سابقة بالغة الأهمية لصدق الأرقام المعروضة في السياق اليمني.
اختبر "اختبار الفترتين المختلطتين" (القسم 9، آخر سطر) كأولوية قصوى قبل الإطلاق — فهو يتحقق عمليًا أن الانتقال بين البيانات الساخنة والباردة لا يُنتج أي اختلاف في الأرقام، وهي أخطر نقطة ضعف محتملة في كامل هذا التصميم.
بهذا تكتمل تصميم الوحدات الأساسية الأربع للمرحلة صفر والأولى: المحاسبة الجوهرية، المخزون، الذمم (AR/AP)، والتقارير المالية. الخطوات المنطقية التالية المتبقية من النقاش السابق:

تصميم Wireframes الشاشات الفعلية التي تُشغِّل كل هذه المحركات.
تصميم وحدة الاشتراكات والدفع عبر المحافظ اليمنية.
أيهما تفضل أن نبدأ به؟




1 بأفضل الممارسات والأساليب وبأداء احترافي
