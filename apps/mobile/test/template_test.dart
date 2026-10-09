import 'package:flutter_test/flutter_test.dart';
import 'package:mohaseb_smart/core/templates/template_model.dart';

void main() {
  test('Template JSON parsing', () {
    final jsonStr = {
      "template_code": "cash_purchase",
      "template_version": 1,
      "category": "purchases",
      "ui": {
        "button_group_ar": "مشتريات",
        "display_name_ar": "شراء نقدي",
        "description_ar": "شراء بضاعة ودفع قيمتها نقداً من الصندوق",
        "icon": "shopping_cart",
        "sort_order": 1
      },
      "fields": [
        {
          "key": "amount",
          "type": "amount",
          "label_ar": "المبلغ المدفوع",
          "required": true
        },
        {
          "key": "notes",
          "type": "text",
          "label_ar": "البيان",
          "required": false
        }
      ]
    };

    final template = TransactionTemplate.fromJson(jsonStr);

    expect(template.templateCode, 'cash_purchase');
    expect(template.ui.displayNameAr, 'شراء نقدي');
    expect(template.fields.length, 2);
    expect(template.fields[0].key, 'amount');
    expect(template.fields[0].required, true);
    expect(template.fields[1].key, 'notes');
    expect(template.fields[1].required, false);
  });
}
