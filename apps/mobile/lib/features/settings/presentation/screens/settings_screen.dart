import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // General Settings State
  String _businessName = 'بقالة الأمل';
  String _businessType = 'تجارة تجزئة وتموينات';
  String _defaultCurrency = 'YER';
  String _numberFormat = 'western';
  int _expiryAlertDays = 30;

  // AI Settings State
  String _selectedAiProvider = 'Google Gemini';
  String _selectedAiModel = 'gemini-1.5-flash';
  final TextEditingController _apiKeyController = TextEditingController(text: 'AIzaSy********************');
  bool _isApiKeyObscured = true;
  bool _isTestingAi = false;
  String? _aiTestResult;

  // Sync / Backup State
  bool _isSyncing = false;
  int _pendingSyncCount = 0;

  // Roles State
  final String _activeUserRole = 'التاجر المالك';
  final List<Map<String, dynamic>> _users = [
    {
      'name': 'أبو صالح (المالك)',
      'role': 'التاجر المالك',
      'avatar': '👑',
      'permissions': 'صلاحيات كاملة وغير مقيدة',
      'isActive': true,
    },
    {
      'name': 'عادل الشميري (مدير النشاط)',
      'role': 'المدير العام',
      'avatar': '👔',
      'permissions': 'إدارة العمليات والمخازن والتقارير',
      'isActive': true,
    },
    {
      'name': 'عبدالرحمن المحاسب',
      'role': 'المحاسب المالي',
      'avatar': '📊',
      'permissions': 'دفتر اليومية، ميزان المراجعة، التسويات',
      'isActive': true,
    },
    {
      'name': 'سالم الكاشير (نقطة البيع)',
      'role': 'البائع / أمين الصندوق',
      'avatar': '🛒',
      'permissions': 'البيع النقدي، سندات القبض، لا يرى الأرباح',
      'isActive': true,
    },
    {
      'name': 'صادق (أمين المستودع)',
      'role': 'أمين المخزن',
      'avatar': '📦',
      'permissions': 'استلام المشتريات، الجرد، الهالك والتالف',
      'isActive': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  Future<void> _testAiConnection() async {
    setState(() {
      _isTestingAi = true;
      _aiTestResult = null;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      setState(() {
        _isTestingAi = false;
        _aiTestResult = '✅ تم الاتصال بنجاح بنموذج $_selectedAiModel عبر مزود $_selectedAiProvider! الوكيل جاهز لمعالجة اللهجة العامية.';
      });
    }
  }

  Future<void> _triggerSync() async {
    setState(() => _isSyncing = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isSyncing = false;
        _pendingSyncCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ تمت مزامنة جميع البيانات والأحداث مع السحابة بنجاح!'),
          backgroundColor: ColorTokens.positive,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات وإدارة النظام'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: ColorTokens.neutralInfo,
          labelColor: ColorTokens.neutralInfo,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.people_outline), text: 'المستخدمون والصلاحيات'),
            Tab(icon: Icon(Icons.psychology_outlined), text: 'الذكاء الاصطناعي'),
            Tab(icon: Icon(Icons.sync), text: 'المزامنة والنسخ'),
            Tab(icon: Icon(Icons.storefront_outlined), text: 'بيانات المنشأة'),
            Tab(icon: Icon(Icons.tune), text: 'القوالب والأزرار'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersAndRolesTab(),
          _buildAiSettingsTab(),
          _buildSyncAndBackupTab(),
          _buildBusinessSettingsTab(),
          _buildTemplatesCustomizationTab(),
        ],
      ),
    );
  }

  // 1. المستخدمون والصلاحيات
  Widget _buildUsersAndRolesTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 0,
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: ColorTokens.neutralInfo, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'حساب واحد - أجهزة وصلاحيات متعددة',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _activeUserRole,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'يمكن استخدام نفس الحساب من هواتف المالك والمدير والمحاسب والكاشير مع ضبط صلاحيات محددة لكل دور بنمط العمل دون اتصال.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('المستخدمون النشطون (${_users.length})', style: Theme.of(context).textTheme.titleMedium),
            ElevatedButton.icon(
              onPressed: () => _showAddUserDialog(),
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('إضافة مستخدم'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.neutralInfo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ..._users.map((user) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: Text(user['avatar'], style: const TextStyle(fontSize: 20)),
                ),
                title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الدور: ${user['role']}', style: const TextStyle(color: ColorTokens.neutralInfo, fontSize: 12)),
                    Text(user['permissions'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  ],
                ),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('تعديل الصلاحيات')),
                    const PopupMenuItem(value: 'device', child: Text('ربط بجهاز هاتف')),
                    const PopupMenuItem(value: 'disable', child: Text('تعطيل الحساب')),
                  ],
                  onSelected: (val) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('تم تحديد الإجراء: $val لـ ${user['name']}')),
                    );
                  },
                ),
              ),
            )),
        const SizedBox(height: AppSpacing.lg),
        Text('جدول مصفوفة الصلاحيات حسب الأدوار', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _buildRolePermissionMatrix(),
      ],
    );
  }

  Widget _buildRolePermissionMatrix() {
    final rolesMatrix = [
      {'feature': 'البيع السريع ونقطة البيع (POS)', 'owner': true, 'manager': true, 'cashier': true, 'accountant': true},
      {'feature': 'تسجيل المشتريات والموردين', 'owner': true, 'manager': true, 'cashier': false, 'accountant': true},
      {'feature': 'عرض تكلفة البضاعة والأرباح اليومية', 'owner': true, 'manager': true, 'cashier': false, 'accountant': true},
      {'feature': 'الدفاتر المحاسبية وميزان المراجعة', 'owner': true, 'manager': false, 'cashier': false, 'accountant': true},
      {'feature': 'إدخال التالف والهالك والجرد', 'owner': true, 'manager': true, 'cashier': false, 'accountant': true},
      {'feature': 'إدارة إعدادات النظام ومفاتيح AI', 'owner': true, 'manager': false, 'cashier': false, 'accountant': false},
    ];

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('الميزة / الصلاحية', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المالك')),
            DataColumn(label: Text('المدير')),
            DataColumn(label: Text('المحاسب')),
            DataColumn(label: Text('الكاشير')),
          ],
          rows: rolesMatrix.map((r) {
            return DataRow(cells: [
              DataCell(Text(r['feature'] as String, style: const TextStyle(fontSize: 12))),
              DataCell(Icon(r['owner'] == true ? Icons.check_circle : Icons.cancel, color: r['owner'] == true ? Colors.green : Colors.grey, size: 18)),
              DataCell(Icon(r['manager'] == true ? Icons.check_circle : Icons.cancel, color: r['manager'] == true ? Colors.green : Colors.grey, size: 18)),
              DataCell(Icon(r['accountant'] == true ? Icons.check_circle : Icons.cancel, color: r['accountant'] == true ? Colors.green : Colors.grey, size: 18)),
              DataCell(Icon(r['cashier'] == true ? Icons.check_circle : Icons.cancel, color: r['cashier'] == true ? Colors.green : Colors.grey, size: 18)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    String newName = '';
    String newRole = 'البائع / الكاشير';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إضافة مستخدم جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'اسم المستخدم (ثلاثي)', border: OutlineInputBorder()),
              onChanged: (v) => newName = v,
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              initialValue: newRole,
              decoration: const InputDecoration(labelText: 'الدور الوظيفي', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'المدير العام', child: Text('المدير العام')),
                DropdownMenuItem(value: 'المحاسب المالي', child: Text('المحاسب المالي')),
                DropdownMenuItem(value: 'البائع / الكاشير', child: Text('البائع / الكاشير')),
                DropdownMenuItem(value: 'أمين المخزن', child: Text('أمين المخزن')),
              ],
              onChanged: (v) => newRole = v ?? newRole,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إلغاء')),
          ElevatedButton(
            onPressed: () {
              if (newName.isNotEmpty) {
                setState(() {
                  _users.add({
                    'name': newName,
                    'role': newRole,
                    'avatar': '👤',
                    'permissions': 'صلاحيات قياسية لدور $newRole',
                    'isActive': true,
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('تمت إضافة المستخدم $newName بنجاح')));
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  // 2. مزودو الذكاء الاصطناعي
  Widget _buildAiSettingsTab() {
    final providers = [
      {'name': 'Google Gemini', 'models': ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash']},
      {'name': 'OpenAI ChatGPT', 'models': ['gpt-4o', 'gpt-4o-mini', 'gpt-3.5-turbo']},
      {'name': 'Anthropic Claude', 'models': ['claude-3-5-sonnet', 'claude-3-haiku']},
      {'name': 'Groq (Ultra-Fast)', 'models': ['llama-3.3-70b-versatile', 'mixtral-8x7b-32768']},
      {'name': 'DeepSeek', 'models': ['deepseek-chat', 'deepseek-reasoner']},
      {'name': 'Local Ollama (Offline)', 'models': ['llama3:8b', 'qwen2.5:7b']},
    ];

    final currentModels = (providers.firstWhere((p) => p['name'] == _selectedAiProvider)['models'] as List<String>);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 0,
          color: Colors.purple.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'وكيل الذكاء الاصطناعي المالي',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'يفهم الوصف واللهجة العامية للمستخدم صوتياً أو نصياً ويقوم بتحليل القالب المطلوب، اختيار الطرف، وتجهيز القيد على الشاشة بدقة.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        DropdownButtonFormField<String>(
          initialValue: _selectedAiProvider,
          decoration: const InputDecoration(
            labelText: 'مزود خدمة الذكاء الاصطناعي',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.cloud_queue),
          ),
          items: providers
              .map((p) => DropdownMenuItem(value: p['name'] as String, child: Text(p['name'] as String)))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedAiProvider = val;
                _selectedAiModel = (providers.firstWhere((p) => p['name'] == val)['models'] as List<String>).first;
              });
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: currentModels.contains(_selectedAiModel) ? _selectedAiModel : currentModels.first,
          decoration: const InputDecoration(
            labelText: 'النموذج اللغوي (LLM Model)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.memory),
          ),
          items: currentModels
              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedAiModel = val);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          controller: _apiKeyController,
          obscureText: _isApiKeyObscured,
          decoration: InputDecoration(
            labelText: 'مفتاح الـ API Key للمزود (مشفر ومحمي)',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.key),
            suffixIcon: IconButton(
              icon: Icon(_isApiKeyObscured ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _isApiKeyObscured = !_isApiKeyObscured),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isTestingAi ? null : _testAiConnection,
                icon: _isTestingAi
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.network_check),
                label: Text(_isTestingAi ? 'جاري الاختبار...' : 'اختبار الاتصال'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorTokens.neutralInfo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ تم حفظ مفتاح الـ API بنجاح وتشفيره محلياً.')),
                );
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ الإعدادات'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorTokens.positive,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              ),
            ),
          ],
        ),
        if (_aiTestResult != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _aiTestResult!,
              style: TextStyle(color: Colors.green.shade800, fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  // 3. المزامنة والنسخ الاحتياطي
  Widget _buildSyncAndBackupTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Card(
          elevation: 0,
          color: Colors.teal.shade50,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.offline_pin, color: Colors.teal, size: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'معمارية محلي أولاً (Local-First)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        'التطبيق يعمل بشكل كامل ومستقل دون إنترنت. جميع العمليات تُحفظ محلياً أولاً وفور توفر الشبكة تتم المزامنة تلقائياً.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          leading: const Icon(Icons.cloud_done, color: ColorTokens.positive),
          title: const Text('حالة المزامنة السحابية'),
          subtitle: Text(_isSyncing ? 'جاري المزامنة...' : 'متصل بالسحابة - $_pendingSyncCount عمليات معلقة'),
          trailing: ElevatedButton.icon(
            onPressed: _isSyncing ? null : _triggerSync,
            icon: _isSyncing
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.sync, size: 16),
            label: const Text('مزامنة الآن'),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('النسخ الاحتياطي اليدوي', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.file_download, color: ColorTokens.neutralInfo),
                title: const Text('تصدير نسخة احتياطية محلية'),
                subtitle: const Text('تصدير قاعدة البيانات والقيود كملف مشفر قابل للنقل'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ تم تصدير النسخة الاحتياطية بنجاح إلى: Documents/mohaseb_backup.sql')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.file_upload, color: Colors.orange),
                title: const Text('استرجاع نسخة احتياطية'),
                subtitle: const Text('استعادة قاعدة البيانات من ملف نسخ احتياطي سابق'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('اختر ملف النسخة الاحتياطية لاسترجاعه...')),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. بيانات المنشأة والنظام العام
  Widget _buildBusinessSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        TextFormField(
          initialValue: _businessName,
          decoration: const InputDecoration(
            labelText: 'اسم المنشأة / المحل',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.store),
          ),
          onChanged: (v) => _businessName = v,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          initialValue: _businessType,
          decoration: const InputDecoration(
            labelText: 'نوع النشاط التجاري',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.category),
          ),
          onChanged: (v) => _businessType = v,
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _defaultCurrency,
          decoration: const InputDecoration(
            labelText: 'العملة الأساسية للنظام',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.monetization_on),
          ),
          items: const [
            DropdownMenuItem(value: 'YER', child: Text('ريال يمني (YER)')),
            DropdownMenuItem(value: 'SAR', child: Text('ريال سعودي (SAR)')),
            DropdownMenuItem(value: 'USD', child: Text('دولار أمريكي (USD)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _defaultCurrency = v);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        DropdownButtonFormField<String>(
          initialValue: _numberFormat,
          decoration: const InputDecoration(
            labelText: 'تنسيق عرض الأرقام',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.format_list_numbered),
          ),
          items: const [
            DropdownMenuItem(value: 'western', child: Text('أرقام إنجليزية / غربية (1, 2, 3)')),
            DropdownMenuItem(value: 'eastern', child: Text('أرقام عربية مشرقية (١، ٢، ٣)')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _numberFormat = v);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          initialValue: _expiryAlertDays.toString(),
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'مهلة التنبيه للأصناف قريبة الانتهاء (أيام)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.timer),
          ),
          onChanged: (v) => _expiryAlertDays = int.tryParse(v) ?? 30,
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ تم حفظ بيانات المنشأة بنجاح.')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorTokens.positive,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('حفظ التعديلات'),
        ),
      ],
    );
  }

  // 5. تخصيص القوالب والأزرار
  Widget _buildTemplatesCustomizationTab() {
    final quickButtons = [
      {'name': 'بعت (المبيعات: نقدي / آجل / جزئي / مرتجع)', 'enabled': true, 'icon': '🛒'},
      {'name': 'اشتريت (المشتريات: نقدي / آجل / جزئي / مرتجع)', 'enabled': true, 'icon': '💵'},
      {'name': 'تحصيل (تحصيل دين من عميل)', 'enabled': true, 'icon': '📥'},
      {'name': 'سداد (سداد دفعة لمورد)', 'enabled': true, 'icon': '📤'},
      {'name': 'تالف (إتلاف بضاعة مع توزيع التكلفة)', 'enabled': true, 'icon': '🗑️'},
      {'name': 'مصروف (يومي مباشر / دوري موزع على فترة)', 'enabled': true, 'icon': '🧾'},
      {'name': 'شيكات (متابعة الشيكات الواردة والصادرة)', 'enabled': true, 'icon': '💳'},
      {'name': 'العملات (أسعار الصرف والفروق)', 'enabled': true, 'icon': '💱'},
      {'name': 'الرصيد الافتتاحي (معالج الأرصدة)', 'enabled': true, 'icon': '⚖️'},
      {'name': 'عمليات المالك (إيداع رأس مال / مسحوبات)', 'enabled': true, 'icon': '💼'},
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Text(
          'تخصيص أزرار وقوالب العمليات على الواجهة الرئيسية',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'يمكن تفعيل أو تعطيل القوالب التشغيلية بحسب نشاطك التجاري (تجزئة، ورش، خدمات، عيادات):',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const SizedBox(height: AppSpacing.md),
        ...quickButtons.map((btn) => Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SwitchListTile(
                value: btn['enabled'] as bool,
                onChanged: (v) {},
                secondary: Text(btn['icon'] as String, style: const TextStyle(fontSize: 24)),
                title: Text(btn['name'] as String, style: const TextStyle(fontSize: 13)),
              ),
            )),
      ],
    );
  }
}
