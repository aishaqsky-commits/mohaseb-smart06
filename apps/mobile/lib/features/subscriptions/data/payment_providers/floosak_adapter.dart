import 'dart:math';
import 'package:uuid/uuid.dart';
import 'payment_provider_interface.dart';

class FloosakAdapter implements PaymentProviderAdapter {
  final Uuid _uuid = const Uuid();

  @override
  String get code => 'floosak';

  @override
  String get displayNameAr => 'فلوسك (Floosak)';

  @override
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request) async {
    await Future.delayed(const Duration(milliseconds: 800));

    return InitiatePaymentResult(
      transactionId: _uuid.v4(),
      instructionsAr: 'يرجى تحويل ${request.amount} ريال عبر محفظة فلوسك إلى رقم التاجر ${'711000222'} وأدخل رقم العملية.',
      receivingAccountNumber: '711000222',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock logic: Valid if starts with 'F'
    if (referenceNumber.toUpperCase().startsWith('F')) {
      return VerificationResult(
        transactionId: transactionId,
        amount: 15000,
        currency: 'YER',
        status: 'paid',
      );
    } else {
      return VerificationResult(
        transactionId: transactionId,
        amount: 0,
        currency: 'YER',
        status: 'failed',
        failureReason: 'تعذر التحقق من العملية عبر نظام فلوسك.',
      );
    }
  }
}
