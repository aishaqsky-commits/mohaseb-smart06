import 'dart:convert';
import 'package:flutter/services.dart';
import 'template_model.dart';

class TemplateRepository {
  final Map<String, TransactionTemplate> _cache = {};
  
  /// Loads a template from assets and caches it
  Future<TransactionTemplate> loadTemplate(String templateCode) async {
    if (_cache.containsKey(templateCode)) {
      return _cache[templateCode]!;
    }
    
    try {
      // In a real app, this might read from SQLite or specific asset paths.
      // Assuming templates are stored in assets/templates/sales/sale_cash.json etc.
      // For now, we will simulate the asset path based on convention.
      // We will look into a flat directory 'assets/templates/' for simplicity here.
      String jsonString = await rootBundle.loadString('assets/templates/$templateCode.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      
      final template = TransactionTemplate.fromJson(jsonMap);
      _cache[templateCode] = template;
      return template;
    } catch (e) {
      throw Exception('فشل في تحميل القالب: $templateCode. التعديلات مطلوبة في ملف pubspec.yaml لإضافة المجلد.');
    }
  }

  /// Clears the cache to force reloading from source
  void clearCache() {
    _cache.clear();
  }
}
