import 'package:uuid/uuid.dart';
import 'payment_provider_interface.dart';

class PaymobAdapter implements PaymentProviderAdapter {
  final Uuid _uuid = const Uuid();

  @override
  String get code => 'paymob';

  @override
  String get displayNameAr => 'Paymob (مَحافظ وبطاقات)';

  @override
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request) async {
    await Future.delayed(const Duration(seconds: 2));

    return InitiatePaymentResult(
      transactionId: _uuid.v4(),
      instructionsAr: 'يرجى الدفع باستخدام بوابات Paymob لضمان تأكيد اشتراكك فوراً.',
      receivingAccountNumber: 'PAYMOB-GATEWAY',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));

    return VerificationResult(
      transactionId: transactionId,
      amount: 0.0, 
      currency: 'EGP',
      status: 'paid',
    );
  }
}
