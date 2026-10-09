import 'dart:math';
import 'package:uuid/uuid.dart';
import 'payment_provider_interface.dart';

class KuraimiAdapter implements PaymentProviderAdapter {
  final Uuid _uuid = const Uuid();

  @override
  String get code => 'kuraimi';

  @override
  String get displayNameAr => 'كريمي جوال';

  @override
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    return InitiatePaymentResult(
      transactionId: _uuid.v4(),
      instructionsAr: 'قم بالتحويل عبر تطبيق كريمي جوال إلى حسابنا ${'123456789'} وأدخل الرقم المرجعي للحوالة.',
      receivingAccountNumber: '123456789',
      expiresAt: DateTime.now().add(const Duration(minutes: 30)),
    );
  }

  @override
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock logic: Valid if starts with 'K'
    if (referenceNumber.toUpperCase().startsWith('K')) {
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
        failureReason: 'الرقم المرجعي غير مطابق أو الحوالة لم تصل.',
      );
    }
  }
}
