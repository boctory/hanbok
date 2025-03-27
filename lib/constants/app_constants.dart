import 'package:flutter/material.dart';

class AppConstants {
  // 앱 정보
  static const String appName = '한복 앱';
  static const String appVersion = '1.0.0';
  
  // 색상
  static final Color primaryColor = Colors.indigo[400]!;
  static final Color secondaryColor = Colors.pink[300]!;
  static final Color accentColor = Colors.amber[400]!;
  static final Color backgroundColor = Colors.grey[50]!;
  static final Color textColor = Colors.black87;
  static final Color errorColor = Colors.red[400]!;
  static final Color successColor = Colors.green[400]!;
  
  // 폰트
  static const String koreanFontFamily = 'NotoSansKR';
  
  // 레이아웃
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  
  // 패딩
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // 이미지 비율
  static const double hanbokImageRatio = 3 / 4;
  
  // API 경로
  static const String apiBaseUrl = 'https://your-api-domain.com';
  
  // Supabase 버킷
  static const String presetsStorageBucket = 'presets';
  static const String uploadsStorageBucket = 'uploads';
  static const String generatedStorageBucket = 'generated';
  
  // 페이지 라우트
  static const String homeRoute = '/';
  static const String detailRoute = '/detail';
  static const String generateRoute = '/generate';
  static const String resultRoute = '/result';
  static const String historyRoute = '/history';
} 