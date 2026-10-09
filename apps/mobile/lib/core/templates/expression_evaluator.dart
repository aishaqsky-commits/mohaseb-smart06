// ignore_for_file: deprecated_member_use

import 'package:math_expressions/math_expressions.dart';

class ExpressionEvaluatorService {
  /// Evaluates a math expression string using variables mapping
  static double evaluate(String expression, Map<String, dynamic> variables) {
    try {
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
           cm.bindVariable(Variable(key), Number(0.0));
        }
      });

      return exp.evaluate(EvaluationType.REAL, cm) as double;
    } catch (e) {
      // Return 0 on failure to avoid crashes during typing
      return 0.0; 
    }
  }

  /// Evaluates a boolean condition like "inventory_mode == true"
  static bool evaluateCondition(String condition, Map<String, dynamic> variables) {
    if (condition.trim().isEmpty) return true;
    
    // Very basic evaluator for MVP: supports "var == value", "var != value"
    String cleaned = condition.replaceAll(' ', '');
    bool isEq = cleaned.contains('==');
    bool isNeq = cleaned.contains('!=');
    
    if (isEq || isNeq) {
      List<String> parts = cleaned.split(isEq ? '==' : '!=');
      if (parts.length == 2) {
        String key = parts[0];
        String targetVal = parts[1];
        
        String actualVal = (variables[key] ?? false).toString();
        
        if (isEq) return actualVal == targetVal;
        if (isNeq) return actualVal != targetVal;
      }
    }
    
    // If it's just a variable name like "inventory_mode"
    if (variables.containsKey(cleaned)) {
      return variables[cleaned] == true;
    }
    
    return true; // Default to visible if parsing fails for now
  }
}

