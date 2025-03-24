import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'screens/index_screen.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  // Initialize Facebook Auth for Web
  if (kIsWeb) {
    try {
      await FacebookAuth.instance.webAndDesktopInitialize(
        appId: dotenv.env['FACEBOOK_APP_ID'] ?? '1234567890', // Use Facebook App ID from .env
        cookie: true,
        xfbml: true,
        version: "v14.0",
      );
    } catch (e) {
      print('Facebook Auth web initialization error: $e');
      // Continue with the app even if Facebook Auth fails
    }
  }
  
  // Initialize Supabase with error handling
  try {
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
      debug: true,
    );
  } catch (e) {
    print('Supabase initialization error: $e');
    // Continue with the app even if Supabase fails
  }
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppConstants.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.primaryColor,
          primary: AppConstants.primaryColor,
          secondary: AppConstants.secondaryColor,
          background: AppConstants.backgroundColor,
          error: AppConstants.errorColor,
        ),
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        fontFamily: AppConstants.koreanFontFamily,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textColor,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            color: AppConstants.textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(
            color: AppConstants.primaryColor,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            textStyle: TextStyle(
              fontFamily: AppConstants.koreanFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppConstants.primaryColor,
            textStyle: TextStyle(
              fontFamily: AppConstants.koreanFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(
              color: Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(
              color: AppConstants.primaryColor,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            borderSide: BorderSide(
              color: AppConstants.errorColor,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          hintStyle: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            color: Colors.grey[400],
          ),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      home: const IndexScreen(),
    );
  }
}
