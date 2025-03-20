import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageResultScreen extends StatefulWidget {
  final GeneratedImage generatedImage;
  final HanbokModel hanbokModel;

  const ImageResultScreen({
    super.key,
    required this.generatedImage,
    required this.hanbokModel,
  });

  @override
  _ImageResultScreenState createState() => _ImageResultScreenState();
}

class _ImageResultScreenState extends State<ImageResultScreen> {
  bool _isSaving = false;
  bool _isSharing = false;
  String _statusMessage = '';
  bool _showStatus = false;

  Future<void> _saveImage() async {
    setState(() {
      _isSaving = true;
      _showStatus = false;
    });

    try {
      final success = await ImageUtils.saveImageToGallery(widget.generatedImage.imageUrl);
      
      setState(() {
        _isSaving = false;
        _showStatus = true;
        _statusMessage = success ? '이미지가 갤러리에 저장되었습니다.' : '이미지 저장에 실패했습니다.';
      });
      
      // Hide status message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStatus = false;
          });
        }
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
        _showStatus = true;
        _statusMessage = '이미지 저장 중 오류가 발생했습니다.';
      });
      print('Error saving image: $e');
    }
  }

  Future<void> _shareImage() async {
    setState(() {
      _isSharing = true;
    });

    try {
      await ImageUtils.shareImage(widget.generatedImage.imageUrl);
      
      setState(() {
        _isSharing = false;
      });
    } catch (e) {
      setState(() {
        _isSharing = false;
        _showStatus = true;
        _statusMessage = '이미지 공유 중 오류가 발생했습니다.';
      });
      print('Error sharing image: $e');
      
      // Hide status message after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStatus = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          '생성된 이미지',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            color: AppConstants.textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.primaryColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navigate back to home screen (clear all screens in between)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Generated image
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                child: CachedNetworkImage(
                  imageUrl: widget.generatedImage.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 50, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          '이미지를 불러올 수 없습니다.',
                          style: AppConstants.bodyStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Status message
          if (_showStatus)
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                  ? AppConstants.errorColor.withOpacity(0.1)
                  : AppConstants.successColor.withOpacity(0.1),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontFamily: AppConstants.koreanFontFamily,
                  color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                      ? AppConstants.errorColor
                      : AppConstants.successColor,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _saveImage,
                    icon: _isSaving
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      '저장하기',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isSharing ? null : _shareImage,
                    icon: _isSharing
                        ? Container(
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(Icons.share),
                    label: Text(
                      '공유하기',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image info
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            margin: const EdgeInsets.only(
              left: AppConstants.paddingMedium,
              right: AppConstants.paddingMedium,
              bottom: AppConstants.paddingMedium,
            ),
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
                  '이미지 정보',
                  style: AppConstants.subheadingStyle,
                ),
                const SizedBox(height: 8),
                _buildInfoRow('한복 모델', widget.hanbokModel.name),
                _buildInfoRow('생성 날짜', _formatDate(widget.generatedImage.createdAt)),
                _buildInfoRow('배경', '경복궁'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppConstants.koreanFontFamily,
              fontWeight: FontWeight.bold,
              color: AppConstants.textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: AppConstants.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${_formatTimeDigit(dateTime.hour)}:${_formatTimeDigit(dateTime.minute)}';
  }

  String _formatTimeDigit(int digit) {
    return digit.toString().padLeft(2, '0');
  }
} 