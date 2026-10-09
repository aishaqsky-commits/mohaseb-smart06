// src/templates/engine/errors.ts

export class ExpressionSyntaxError extends Error {
  constructor(message: string, position: number) {
    super(`خطأ في تحليل الصيغة عند الموضع ${position}: ${message}`);
    this.name = "ExpressionSyntaxError";
  }
}

export class ExpressionEvaluationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ExpressionEvaluationError";
  }
}

export class UnknownFunctionError extends ExpressionEvaluationError {
  constructor(name: string) {
    super(`الدالة "${name}" غير معروفة أو غير مسموح باستخدامها`);
    this.name = "UnknownFunctionError";
  }
}
