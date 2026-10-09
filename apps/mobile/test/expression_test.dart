import 'package:flutter_test/flutter_test.dart';
import 'package:mohaseb_smart/core/templates/expression_evaluator.dart';

void main() {
  test('Evaluates simple math with variables', () {
    final result = ExpressionEvaluatorService.evaluate("amount * 0.15", {"amount": 100.0});
    expect(result, 15.0);
  });

  test('Evaluates complex math with bracket syntax variables', () {
    final result = ExpressionEvaluatorService.evaluate("{total_amount} - {discount}", {
      "total_amount": 500.0,
      "discount": 50.0,
    });
    expect(result, 450.0);
  });

  test('Throws exception on invalid math', () {
    expect(() => ExpressionEvaluatorService.evaluate("amount * (", {"amount": 100}), throwsException);
  });
}
