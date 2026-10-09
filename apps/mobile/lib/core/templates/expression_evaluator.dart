// ignore_for_file: deprecated_member_use

import 'package:math_expressions/math_expressions.dart';

class ExpressionEvaluatorService {
  /// Evaluates an expression string using variables mapping
  /// E.g., evaluate("amount * 0.15", {"amount": 100}) -> 15.0
  static double evaluate(String expression, Map<String, dynamic> variables) {
    try {
      // Clean expression by replacing custom syntax {var} with var
      String cleanedExpr = expression.replaceAll('{', '').replaceAll('}', '');
      
      final p = Parser();
      final exp = p.parse(cleanedExpr);
      
      ContextModel cm = ContextModel();
      variables.forEach((key, value) {
        if (value is num) {
          cm.bindVariable(Variable(key), Number(value.toDouble()));
        } else if (value is String && double.tryParse(value) != null) {
          cm.bindVariable(Variable(key), Number(double.parse(value)));
        } else {
           // Default to 0 for unbound or non-numeric variables
           cm.bindVariable(Variable(key), Number(0.0));
        }
      });

      return exp.evaluate(EvaluationType.REAL, cm) as double;
    } catch (e) {
      throw Exception('فشل في حساب المعادلة الرياضية: $expression');
    }
  }
}
