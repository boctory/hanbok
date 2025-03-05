import 'package:flutter/material.dart';

class AppConstants {
  // App Name
  static const String appName = "한복 AI";
  
  // Colors
  static const Color primaryColor = Color(0xFF9E4784); // Traditional Korean purple
  static const Color secondaryColor = Color(0xFFE7BCDE); // Light pink
  static const Color accentColor = Color(0xFFD16BA5); // Accent pink
  static const Color backgroundColor = Color(0xFFFFF5F5); // Light background
  static const Color textColor = Color(0xFF333333); // Dark text
  static const Color lightTextColor = Color(0xFF666666); // Light text
  static const Color errorColor = Color(0xFFE53935); // Error red
  static const Color successColor = Color(0xFF43A047); // Success green
  
  // Font Families
  static const String koreanFontFamily = "NotoSansKR";
  static const String traditionalFontFamily = "NanumMyeongjo";
  
  // Text Styles
  static TextStyle headingStyle = const TextStyle(
    fontFamily: traditionalFontFamily,
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );
  
  static TextStyle subheadingStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );
  
  static TextStyle bodyStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 16,
    color: textColor,
  );
  
  static TextStyle captionStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 14,
    color: lightTextColor,
  );
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusMedium = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // API Endpoints
  static const String generateImageEndpoint = "/generate-image";
  static const String userGalleryEndpoint = "/user-gallery";
  static const String hanbokModelsEndpoint = "/hanbok-models";
} 