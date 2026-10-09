import 'package:uuid/uuid.dart';
import 'payment_provider_interface.dart';

class MoyasarAdapter implements PaymentProviderAdapter {
  final Uuid _uuid = const Uuid();

  @override
  String get code => 'moyasar';
  
  @override
  String get displayNameAr => 'ميسر (Apple Pay، مدى، فيزا)';

  @override
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    return InitiatePaymentResult(
      transactionId: _uuid.v4(),
      instructionsAr: 'يرجى إكمال عملية الدفع عبر صفحة ميسر الآمنة المفتوحة لك.',
      receivingAccountNumber: 'MOYASAR-GATEWAY',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));

    return VerificationResult(
      transactionId: transactionId,
      amount: 0.0, // Should be fetched from actual verification response
      currency: 'SAR',
      status: 'paid',
    );
  }
}
