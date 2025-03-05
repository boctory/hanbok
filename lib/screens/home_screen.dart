import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/screens/hanbok_selection_screen.dart';
import 'package:hanbok_app/screens/gallery_screen.dart';
import 'package:hanbok_app/utils/image_utils.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _selectedImage;
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    setState(() {
      _isLoading = true;
    });

    File? image;
    if (source == ImageSource.gallery) {
      image = await ImageUtils.pickImageFromGallery();
    } else {
      image = await ImageUtils.takePhoto();
    }

    setState(() {
      _selectedImage = image;
      _isLoading = false;
    });

    if (_selectedImage != null) {
      // Navigate to Hanbok selection screen
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HanbokSelectionScreen(userImage: _selectedImage!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with logo and title
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Image.asset(
                    //   'assets/images/logo.png',
                    //   height: 40,
                    // ),
                    Icon(
                      Icons.accessibility_new,
                      size: 40,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppConstants.appName,
                      style: AppConstants.headingStyle,
                    ),
                  ],
                ),
              ),
              
              // Hero banner
              Container(
                height: 250,
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                  // image: const DecorationImage(
                  //   image: AssetImage('assets/images/hero_banner.jpg'),
                  //   fit: BoxFit.cover,
                  // ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.primaryColor.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '한복의 아름다움을 경험하세요',
                            style: TextStyle(
                              fontFamily: AppConstants.traditionalFontFamily,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'AI로 만드는 나만의 한복 이미지',
                            style: TextStyle(
                              fontFamily: AppConstants.koreanFontFamily,
                              fontSize: 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '나만의 한복 이미지 만들기',
                      style: AppConstants.subheadingStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.photo_camera,
                            label: '사진 찍기',
                            onTap: () => _pickImage(ImageSource.camera),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.photo_library,
                            label: '갤러리에서 선택',
                            onTap: () => _pickImage(ImageSource.gallery),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      icon: Icons.collections,
                      label: '내 작품 보기',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GalleryScreen(),
                          ),
                        );
                      },
                      color: AppConstants.secondaryColor,
                      textColor: AppConstants.textColor,
                    ),
                  ],
                ),
              ),
              
              // Information section
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '한복이란?',
                      style: AppConstants.subheadingStyle,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '한복은 한국의 전통 의상으로, 아름다운 색상과 우아한 선이 특징입니다. 현대에는 전통 한복뿐만 아니라 현대적으로 재해석된 생활한복도 인기를 끌고 있습니다.',
                      style: AppConstants.bodyStyle,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '이 앱은 AI 기술을 활용하여 당신의 사진을 한복을 입은 모습으로 변환해 줍니다. 경복궁을 배경으로 아름다운 한복 이미지를 만들어보세요!',
                      style: AppConstants.bodyStyle,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppConstants.primaryColor,
    Color textColor = Colors.white,
  }) {
    return ElevatedButton(
      onPressed: _isLoading ? null : onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: textColor,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppConstants.koreanFontFamily,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

enum ImageSource {
  gallery,
  camera,
} 