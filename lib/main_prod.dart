import 'package:flutter/material.dart';
import 'package:guardian_app/core/config/app_config.dart';
import 'package:guardian_app/main_common.dart';

void main() {
  final prodConfig = AppConfig(
    appName: 'الأمين الشرعي',
    apiBaseUrl: 'https://darkturquoise-lark-306795.hostingersite.com/api',
    environment: AppEnvironment.prod,
  );

  mainCommon(prodConfig);
}
