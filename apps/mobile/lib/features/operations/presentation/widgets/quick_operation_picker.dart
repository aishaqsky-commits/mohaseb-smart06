import 'package:flutter/material.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/app_spacing.dart';
import 'package:go_router/go_router.dart';

class QuickOperationPicker {
  static void show(BuildContext context, {required String category}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        switch (category) {
          case 'sale':
            return _buildSalesSheet(ctx);
          case 'purchase':
            return _buildPurchasesSheet(ctx);
          case 'expense':
            return _buildExpensesSheet(ctx);
          case 'damage':
            return _buildDamageSheet(ctx);
          case 'settlement':
            return _buildSettlementsSheet(ctx);
          case 'owner':
            return _buildOwnerSheet(ctx);
          default:
            return _buildAllOperationsSheet(ctx);
        }
      },
    );
  }

  // 1. مبيعات
  static Widget _buildSalesSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'عمليات المبيعات والعملاء',
      icon: '🛒',
      options: [
        {
          'title': 'بيع نقدي',
          'subtitle': 'استلام كاش فوري في الصندوق مقابل البضاعة',
          'icon': Icons.payments_outlined,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'sale_cash'});
          },
        },
        {
          'title': 'بيع آجل (على الحساب)',
          'subtitle': 'تسجيل دين مستحق على العميل مع إمكانية إضافته سريعاً',
          'icon': Icons.assignment_outlined,
          'color': ColorTokens.neutralInfo,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'sale_credit'});
          },
        },
        {
          'title': 'بيع جزئي (دفعة مقدمة)',
          'subtitle': 'استلام دفعة أولى كاش والباقي يسجل كدين على العميل',
          'icon': Icons.pie_chart_outline,
          'color': Colors.teal,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'sale_partial'});
          },
        },
        {
          'title': 'مرتجع مبيعات من عميل',
          'subtitle': 'استرجاع بضاعة مباعة ورد النقد أو خصم من دينه',
          'icon': Icons.replay,
          'color': Colors.deepOrange,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'sales_return'});
          },
        },
        {
          'title': 'نقطة البيع السريعة (POS)',
          'subtitle': 'واجهة الكاشير الفورية بالباركود والسلة السريعة',
          'icon': Icons.point_of_sale,
          'color': Colors.purple,
          'onTap': () {
            Navigator.pop(context);
            context.push('/pos');
          },
        },
      ],
    );
  }

  // 2. مشتريات
  static Widget _buildPurchasesSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'عمليات المشتريات والموردين',
      icon: '💵',
      options: [
        {
          'title': 'شراء نقدي',
          'subtitle': 'شراء بضاعة ودفع قيمتها نقداً من الصندوق مباشرة',
          'icon': Icons.payments_outlined,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'purchase_cash'});
          },
        },
        {
          'title': 'شراء آجل (دين للمورد)',
          'subtitle': 'شراء بالآجل وتسجيل التزام للمورد مع إضافة المورد بسهولة',
          'icon': Icons.assignment_outlined,
          'color': ColorTokens.negative,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'purchase_credit'});
          },
        },
        {
          'title': 'شراء جزئي (دفعة للمورد)',
          'subtitle': 'دفع جزء نقداً وتسجيل المتبقي كدين للمورد',
          'icon': Icons.pie_chart_outline,
          'color': Colors.teal,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'purchase_partial'});
          },
        },
        {
          'title': 'مرتجع مشتريات لمورد',
          'subtitle': 'إرجاع بضاعة واسترداد قيمتها نقداً أو خصماً من الحساب',
          'icon': Icons.replay,
          'color': Colors.deepOrange,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'purchase_return'});
          },
        },
      ],
    );
  }

  // 3. مصروفات
  static Widget _buildExpensesSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'المصروفات والتكاليف التشغيلية',
      icon: '🧾',
      options: [
        {
          'title': 'مصروف يومي مباشر',
          'subtitle': 'أجور يومية، كهرباء، مياه، نظافة، نثريات (يخصم من ربح اليوم)',
          'icon': Icons.flash_on,
          'color': Colors.amber.shade800,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'expense_daily'});
          },
        },
        {
          'title': 'مصروف دوري (يوزع على فترة)',
          'subtitle': 'إيجار شهر، اشتراكات، تأمين (يوزع على عدد الأيام لحساب ربح اليوم)',
          'icon': Icons.date_range,
          'color': ColorTokens.neutralInfo,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'expense_period'});
          },
        },
        {
          'title': 'إثبات مصروف مستحق',
          'subtitle': 'تسجيل التزام مصروف لم يدفع بعد (أساس الاستحقاق)',
          'icon': Icons.pending_actions,
          'color': Colors.purple,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'expense_accrued'});
          },
        },
        {
          'title': 'سداد مصروف مستحق',
          'subtitle': 'دفع قيمة مصروف مستحق مسجل سابقاً من الصندوق',
          'icon': Icons.check_circle_outline,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'accrued_expense_payment'});
          },
        },
      ],
    );
  }

  // 4. تالف
  static Widget _buildDamageSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'إتلاف بضاعة هالكة أو منتهية',
      icon: '🗑️',
      options: [
        {
          'title': 'إتلاف بضاعة (تحميل على المحل)',
          'subtitle': 'خسارة تشغيلية تثبت في قائمة الدخل وتخفض المخزون',
          'icon': Icons.store,
          'color': ColorTokens.negative,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'inventory_damage'});
          },
        },
        {
          'title': 'إتلاف بضاعة (تحميل على المورد)',
          'subtitle': 'إثبات تلف بضاعة بالاتفاق وخصم قيمتها من رصيد المورد',
          'icon': Icons.assignment_return,
          'color': Colors.blueGrey,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'inventory_damage'});
          },
        },
        {
          'title': 'جرد المخزون والتسويات',
          'subtitle': 'مقارنة الرصيد الفعلي بالدفتري واعتماد فوارق الجرد',
          'icon': Icons.fact_check_outlined,
          'color': Colors.teal,
          'onTap': () {
            Navigator.pop(context);
            context.push('/inventory-check');
          },
        },
      ],
    );
  }

  // 5. تحصيل وسداد
  static Widget _buildSettlementsSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'التحصيل والسداد المالي',
      icon: '⚖️',
      options: [
        {
          'title': 'تحصيل دين من عميل',
          'subtitle': 'قبض دفعة من عميل نقداً أو بحوالة لتخفيض دينه',
          'icon': Icons.call_received,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'customer_collection'});
          },
        },
        {
          'title': 'سداد دفعة لمورد',
          'subtitle': 'دفع مبلغ لمورد لتخفيض الالتزام المستحق له',
          'icon': Icons.call_made,
          'color': ColorTokens.warning,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'supplier_payment'});
          },
        },
      ],
    );
  }

  // 6. المالك
  static Widget _buildOwnerSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'عمليات التاجر المالك',
      icon: '💼',
      options: [
        {
          'title': 'إيداع رأس مال للمالك',
          'subtitle': 'ضخ سيولة نقدية في صندوق النشاط لزيادة رأس المال',
          'icon': Icons.add_card,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'owner_deposit'});
          },
        },
        {
          'title': 'مسحوبات شخصية للمالك',
          'subtitle': 'سحب مبالغ للاستخدام الشخصي خارج نطاق مصاريف المحل',
          'icon': Icons.money_off,
          'color': Colors.redAccent,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'owner_withdrawal'});
          },
        },
        {
          'title': 'معالج الرصيد الافتتاحي',
          'subtitle': 'تسجيل الأرصدة الافتتاحية للمخازن والصناديق والديون',
          'icon': Icons.tune,
          'color': Colors.deepPurple,
          'onTap': () {
            Navigator.pop(context);
            context.push('/operations/form', extra: {'templateCode': 'opening_balance_wizard'});
          },
        },
      ],
    );
  }

  // 7. كافة العمليات
  static Widget _buildAllOperationsSheet(BuildContext context) {
    return _buildSheetScaffold(
      context,
      title: 'مركز كافة العمليات المحاسبية',
      icon: '📋',
      options: [
        {
          'title': 'المبيعات والعملاء (نقدي / آجل / جزئي)',
          'subtitle': 'جميع خيارات البيع والمرتجعات ونقطة البيع',
          'icon': Icons.shopping_cart,
          'color': ColorTokens.positive,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'sale');
          },
        },
        {
          'title': 'المشتريات والموردين (نقدي / آجل / جزئي)',
          'subtitle': 'جميع خيارات الشراء والتوريد',
          'icon': Icons.local_shipping,
          'color': ColorTokens.negative,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'purchase');
          },
        },
        {
          'title': 'المصروفات والتكاليف (يومي / دوري موزع)',
          'subtitle': 'إيجارات، رواتب، فواتير، كهرباء، نظافة',
          'icon': Icons.receipt_long,
          'color': Colors.deepOrange,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'expense');
          },
        },
        {
          'title': 'التحصيل والسداد',
          'subtitle': 'تحصيل ديون وسداد موردين',
          'icon': Icons.account_balance_wallet,
          'color': ColorTokens.neutralInfo,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'settlement');
          },
        },
        {
          'title': 'إتلاف البضاعة والجرد',
          'subtitle': 'إثبات الهالك وتحديد جهة التحمل والتسويات',
          'icon': Icons.delete_outline,
          'color': Colors.brown,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'damage');
          },
        },
        {
          'title': 'عمليات المالك والرصيد الافتتاحي',
          'subtitle': 'إيداعات، مسحوبات شخصية، إعداد أرصدة البداية',
          'icon': Icons.person,
          'color': Colors.deepPurple,
          'onTap': () {
            Navigator.pop(context);
            show(context, category: 'owner');
          },
        },
        {
          'title': 'إدارة الشيكات البنكية',
          'subtitle': 'متابعة الشيكات الواردة والصادرة والتحصيل',
          'icon': Icons.credit_card,
          'color': Colors.indigo,
          'onTap': () {
            Navigator.pop(context);
            context.push('/checks');
          },
        },
        {
          'title': 'التحويل بين المخازن والفروع',
          'subtitle': 'نقل أصناف بين المستودعات والفروع',
          'icon': Icons.swap_horiz,
          'color': Colors.teal,
          'onTap': () {
            Navigator.pop(context);
            context.push('/inventory/transfer');
          },
        },
      ],
    );
  }

  static Widget _buildSheetScaffold(
    BuildContext context, {
    required String title,
    required String icon,
    required List<Map<String, dynamic>> options,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        top: AppSpacing.lg,
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 26)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (c, i) => const Divider(height: 1),
              itemBuilder: (ctx, idx) {
                final opt = options[idx];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: (opt['color'] as Color).withValues(alpha: 0.12),
                    child: Icon(opt['icon'] as IconData, color: opt['color'] as Color),
                  ),
                  title: Text(opt['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(opt['subtitle'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: opt['onTap'] as VoidCallback,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
