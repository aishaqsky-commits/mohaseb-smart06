import 'package:flutter/material.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/color_tokens.dart';
import '../../data/payment_providers/payment_provider_interface.dart';
import '../../data/payment_providers/jawali_adapter.dart';
import '../../data/payment_providers/kuraimi_adapter.dart';
import '../../data/payment_providers/floosak_adapter.dart';
import '../../data/payment_providers/moyasar_adapter.dart';
import '../../data/payment_providers/paymob_adapter.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatefulWidget {
  final String planCode;
  final double planPrice;

  const CheckoutScreen({
    super.key,
    required this.planCode,
    required this.planPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final List<PaymentProviderAdapter> _providers = [
    JawaliAdapter(),
    KuraimiAdapter(),
    FloosakAdapter(),
    MoyasarAdapter(),
    PaymobAdapter(),
  ];

  PaymentProviderAdapter? _selectedProvider;
  InitiatePaymentResult? _paymentInitiation;
  bool _isInitiating = false;
  bool _isVerifying = false;
  final TextEditingController _referenceController = TextEditingController();

  Future<void> _initiatePayment() async {
    if (_selectedProvider == null) return;
    
    setState(() => _isInitiating = true);
    
    try {
      final req = InitiatePaymentRequest(
        targetPlanCode: widget.planCode,
        amount: widget.planPrice,
        currencyCode: 'YER',
      );
      
      final result = await _selectedProvider!.initiatePayment(req);
      setState(() => _paymentInitiation = result);
    } finally {
      setState(() => _isInitiating = false);
    }
  }

  Future<void> _verifyPayment() async {
    if (_referenceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم العملية')),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      final result = await _selectedProvider!.verifyByReference(
        _referenceController.text.trim(),
        _paymentInitiation!.transactionId,
      );

      if (!mounted) return;

      if (result.status == 'paid') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل باقتك بنجاح!'),
            backgroundColor: ColorTokens.positive,
          ),
        );
        // Navigate to success or back to dashboard
        context.go('/');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.failureReason ?? 'فشل التحقق من الدفع'),
            backgroundColor: ColorTokens.negative,
          ),
        );
      }
    } finally {
      setState(() => _isVerifying = false);
    }
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دفع الاشتراك'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildOrderSummary(),
            const SizedBox(height: AppSpacing.xl),
            
            if (_paymentInitiation == null) ...[
              Text(
                'اختر وسيلة الدفع',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              ..._providers.map((p) => _buildProviderTile(p)),
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton(
                onPressed: _selectedProvider == null || _isInitiating
                    ? null
                    : _initiatePayment,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: ColorTokens.neutralInfo,
                  foregroundColor: Colors.white,
                ),
                child: _isInitiating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('متابعة الدفع', style: TextStyle(fontSize: 18)),
              ),
            ] else ...[
              _buildPaymentInstructions(),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ملخص الطلب', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'باقة ${widget.planCode.toUpperCase()}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                '${widget.planPrice.toStringAsFixed(0)} ريال',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: ColorTokens.neutralInfo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProviderTile(PaymentProviderAdapter provider) {
    final isSelected = _selectedProvider?.code == provider.code;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedProvider = provider;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? ColorTokens.neutralInfo : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? ColorTokens.neutralInfo.withValues(alpha: 0.05) : Colors.white,
          ),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: isSelected ? ColorTokens.neutralInfo : Colors.grey,
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                provider.displayNameAr,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? ColorTokens.neutralInfo : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentInstructions() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: ColorTokens.neutralInfo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorTokens.neutralInfo),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: ColorTokens.neutralInfo),
              SizedBox(width: 8),
              Text('تعليمات الدفع', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            _paymentInitiation!.instructionsAr,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'رقم العملية (Reference Number)',
              hintText: 'أدخل رقم العملية بعد التحويل',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.numbers),
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: _isVerifying ? null : _verifyPayment,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: ColorTokens.positive,
              foregroundColor: Colors.white,
            ),
            child: _isVerifying
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('تأكيد الدفع', style: TextStyle(fontSize: 18)),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentInitiation = null;
              });
            },
            child: const Text('تغيير وسيلة الدفع'),
          ),
        ],
      ),
    );
  }
}
