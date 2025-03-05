import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/screens/image_result_screen.dart';
import 'package:hanbok_app/services/api_service.dart';
import 'package:hanbok_app/services/storage_service.dart';
import 'dart:io';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ImageGenerationScreen extends StatefulWidget {
  final File userImage;
  final HanbokModel hanbokModel;

  const ImageGenerationScreen({
    super.key,
    required this.userImage,
    required this.hanbokModel,
  });

  @override
  _ImageGenerationScreenState createState() => _ImageGenerationScreenState();
}

class _ImageGenerationScreenState extends State<ImageGenerationScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  bool _isGenerating = true;
  String _statusMessage = '이미지 생성 중...';
  GeneratedImage? _generatedImage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _generateImage();
  }

  Future<void> _generateImage() async {
    try {
      setState(() {
        _isGenerating = true;
        _statusMessage = '이미지 생성 중...';
        _hasError = false;
      });

      // Generate image using API
      final generatedImage = await _apiService.generateImage(
        widget.userImage,
        widget.hanbokModel.id,
      );

      // Save to local storage
      await _storageService.saveGeneratedImage(generatedImage);

      setState(() {
        _generatedImage = generatedImage;
        _isGenerating = false;
      });

      // Navigate to result screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ImageResultScreen(
              generatedImage: _generatedImage!,
              hanbokModel: widget.hanbokModel,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _hasError = true;
        _statusMessage = '이미지 생성 중 오류가 발생했습니다.';
      });
      print('Error generating image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          '이미지 생성 중',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            color: AppConstants.textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.primaryColor),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isGenerating) ...[
                SpinKitDoubleBounce(
                  color: AppConstants.primaryColor,
                  size: 100.0,
                ),
                const SizedBox(height: 32),
                Text(
                  _statusMessage,
                  style: AppConstants.subheadingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  '잠시만 기다려주세요. 한복을 입은 당신의 모습을 생성하고 있습니다.',
                  style: AppConstants.bodyStyle,
                  textAlign: TextAlign.center,
                ),
              ] else if (_hasError) ...[
                Icon(
                  Icons.error_outline,
                  color: AppConstants.errorColor,
                  size: 80,
                ),
                const SizedBox(height: 32),
                Text(
                  _statusMessage,
                  style: AppConstants.subheadingStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _generateImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                  ),
                  child: Text(
                    '다시 시도',
                    style: TextStyle(
                      fontFamily: AppConstants.koreanFontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 