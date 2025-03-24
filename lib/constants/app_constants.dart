import 'package:flutter/material.dart';

class AppConstants {
  // App Name
  static const String appName = "한복 AI";
  
  // Colors - 하늘색 테마로 업데이트
  static const Color primaryColor = Color(0xFF4A90E2); // Sky blue (하늘색)
  static const Color secondaryColor = Color(0xFF5FCBEF); // Light blue (밝은 하늘색)
  static const Color accentColor = Color(0xFF2D78C8); // Darker blue (진한 하늘색)
  static const Color backgroundColor = Color(0xFFF6FAFF); // Very light blue background
  static const Color cardColor = Color(0xFFFFFFFF); // Card background
  static const Color textColor = Color(0xFF2D2B35); // Dark text
  static const Color lightTextColor = Color(0xFF8F8D96); // Light text
  static const Color errorColor = Color(0xFFE53935); // Error red
  static const Color successColor = Color(0xFF43A047); // Success green
  static const Color shadowColor = Color(0x40000000); // Shadow color
  
  // Font Families
  static const String koreanFontFamily = "NotoSansKR";
  static const String traditionalFontFamily = "NanumMyeongjo";
  
  // Text Styles
  static TextStyle headingStyle = const TextStyle(
    fontFamily: traditionalFontFamily,
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: textColor,
    letterSpacing: -0.5,
  );
  
  static TextStyle subheadingStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: textColor,
    letterSpacing: -0.3,
  );
  
  static TextStyle bodyStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 16,
    color: textColor,
    letterSpacing: -0.2,
  );
  
  static TextStyle captionStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 14,
    color: lightTextColor,
    letterSpacing: -0.1,
  );
  
  static TextStyle buttonStyle = const TextStyle(
    fontFamily: koreanFontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.2,
  );
  
  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 20.0;
  
  // Elevation
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  
  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 350);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // Card Decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(borderRadiusMedium),
    boxShadow: [
      BoxShadow(
        color: shadowColor.withOpacity(0.08),
        blurRadius: 15,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  // Button Decoration
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadiusMedium),
    ),
    elevation: elevationSmall,
  );
  
  // API Endpoints
  static const String generateImageEndpoint = "/generate-image";
  static const String userGalleryEndpoint = "/user-gallery";
  static const String hanbokModelsEndpoint = "/hanbok-models";
} 