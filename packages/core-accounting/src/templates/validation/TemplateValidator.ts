// src/templates/validation/TemplateValidator.ts

import { ExpressionEngine } from "../engine/ExpressionEngine";
import { TemplateDefinition, FieldDefinition } from "../types/TemplateDefinition";

export class TemplateValidationError extends Error {
  constructor(public readonly fieldErrors: Array<{ key: string; message: string }>) {
    // رسالة مفصّلة قابلة للقراءة مباشرة على واجهة المستخدم (رسالة عربية لكل حقل)
    super(
      `فشل التحقق من ${fieldErrors.length} حقل/حقول: ${fieldErrors.map((e) => e.message).join(" | ")}`
    );
    this.name = "TemplateValidationError";
  }
}

export class TemplateValidator {
  validate(template: TemplateDefinition, payload: Record<string, unknown>): void {
    const errors: Array<{ key: string; message: string }> = [];
    const context = { fields: payload, computed: {} };

    for (const field of template.fields) {
      if (this.isHiddenByVisibility(field, context)) continue;

      const value = payload[field.key];
      const isEmpty = value === undefined || value === null || value === "";

      if (field.required && isEmpty) {
        errors.push({ key: field.key, message: `الحقل "${field.label_ar}" مطلوب` });
        continue;
      }

      if (!isEmpty && field.validation) {
        const isValid = ExpressionEngine.evaluateAsBoolean(field.validation, context);
        if (!isValid) {
          errors.push({ key: field.key, message: `قيمة الحقل "${field.label_ar}" غير صحيحة` });
        }
      }
    }

    if (errors.length > 0) {
      throw new TemplateValidationError(errors);
    }
  }

  private isHiddenByVisibility(
    field: FieldDefinition,
    context: { fields: Record<string, unknown>; computed: Record<string, never> }
  ): boolean {
    if (!field.visible_when) return false;
    return !ExpressionEngine.evaluateAsBoolean(field.visible_when, context);
  }
}
