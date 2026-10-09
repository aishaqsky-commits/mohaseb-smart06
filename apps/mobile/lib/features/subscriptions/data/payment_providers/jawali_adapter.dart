import 'package:uuid/uuid.dart';
import 'payment_provider_interface.dart';

class JawaliAdapter implements PaymentProviderAdapter {
  final Uuid _uuid = const Uuid();

  @override
  String get code => 'jawali';

  @override
  String get displayNameAr => 'جوالي (WeCash)';

  @override
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    return InitiatePaymentResult(
      transactionId: _uuid.v4(),
      instructionsAr: 'يرجى تحويل ${request.amount} ريال عبر تطبيق جوالي إلى حساب المنصة ثم إدخال رقم العملية.',
      receivingAccountNumber: '777000111',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simple mock logic: If ref number starts with 'J', it's valid for this mock.
    if (referenceNumber.toUpperCase().startsWith('J')) {
      return VerificationResult(
        transactionId: transactionId,
        amount: 15000, // mock amount
        currency: 'YER',
        status: 'paid',
      );
    } else {
      return VerificationResult(
        transactionId: transactionId,
        amount: 0,
        currency: 'YER',
        status: 'failed',
        failureReason: 'رقم العملية غير صالح أو لم يتم تأكيده من نظام جوالي.',
      );
    }
  }
}
