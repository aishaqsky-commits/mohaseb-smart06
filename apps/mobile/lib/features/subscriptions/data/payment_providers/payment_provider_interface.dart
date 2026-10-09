class InitiatePaymentRequest {
  final String targetPlanCode;
  final double amount;
  final String currencyCode;

  InitiatePaymentRequest({
    required this.targetPlanCode,
    required this.amount,
    required this.currencyCode,
  });
}

class InitiatePaymentResult {
  final String transactionId;
  final String instructionsAr;
  final String receivingAccountNumber;
  final DateTime expiresAt;

  InitiatePaymentResult({
    required this.transactionId,
    required this.instructionsAr,
    required this.receivingAccountNumber,
    required this.expiresAt,
  });
}

class VerificationResult {
  final String transactionId;
  final double amount;
  final String currency;
  final String status; // 'paid' | 'failed' | 'pending'
  final String? failureReason;

  VerificationResult({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.status,
    this.failureReason,
  });
}

abstract class PaymentProviderAdapter {
  String get code;
  String get displayNameAr;

  /// Initiate the payment process (generates instructions for Pull mode).
  Future<InitiatePaymentResult> initiatePayment(InitiatePaymentRequest request);

  /// Verify the payment by reference number (simulated for mobile until backend is ready).
  Future<VerificationResult> verifyByReference(String referenceNumber, String transactionId);
}
