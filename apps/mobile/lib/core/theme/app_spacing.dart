import 'package:flutter/material.dart';

class AppSpacing {
  // وحدة المسافة الأساسية
  static const double unit = 4.0;
  static const double xs = 4.0;
  
  static const double sm = unit * 2;   // 8.0
  static const double md = unit * 3;   // 12.0
  static const double lg = unit * 4;   // 16.0 (الهامش الجانبي القياسي)
  static const double xl = unit * 6;   // 24.0
  static const double xxl = unit * 8;  // 32.0

  // الهوامش القياسية
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: lg, vertical: lg);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: lg);
  
  // معيار إمكانية الوصول
  static const double minTouchTarget = 48.0;
}
