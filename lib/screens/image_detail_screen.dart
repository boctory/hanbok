import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/services/storage_service.dart';
import 'package:hanbok_app/utils/image_utils.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageDetailScreen extends StatefulWidget {
  final GeneratedImage generatedImage;

  const ImageDetailScreen({
    super.key,
    required this.generatedImage,
  });

  @override
  _ImageDetailScreenState createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  final StorageService _storageService = StorageService();
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isDeleting = false;
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

  Future<void> _deleteImage() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '이미지 삭제',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '정말로 이 이미지를 삭제하시겠습니까?',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: AppConstants.textColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '삭제',
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: AppConstants.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isDeleting = true;
      });

      try {
        await _storageService.deleteGeneratedImage(widget.generatedImage.id);
        
        // Navigate back
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        setState(() {
          _isDeleting = false;
          _showStatus = true;
          _statusMessage = '이미지 삭제 중 오류가 발생했습니다.';
        });
        print('Error deleting image: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isDeleting ? null : _deleteImage,
            tooltip: '이미지 삭제',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Image
          Center(
            child: GestureDetector(
              onTap: () {
                // Toggle app bar and bottom bar visibility
              },
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: widget.generatedImage.imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                    ),
                  ),
                  errorWidget: (context, url, error) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '이미지를 불러올 수 없습니다.',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Status message
          if (_showStatus)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                    ? AppConstants.errorColor.withOpacity(0.8)
                    : AppConstants.successColor.withOpacity(0.8),
                child: Text(
                  _statusMessage,
                  style: TextStyle(
                    fontFamily: AppConstants.koreanFontFamily,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          
          // Bottom bar with actions
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                    Colors.black,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: Icons.download,
                    label: '저장',
                    isLoading: _isSaving,
                    onTap: _saveImage,
                  ),
                  _buildActionButton(
                    icon: Icons.share,
                    label: '공유',
                    isLoading: _isSharing,
                    onTap: _shareImage,
                  ),
                  _buildActionButton(
                    icon: Icons.info_outline,
                    label: '정보',
                    onTap: _showImageInfo,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withOpacity(0.9),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '이미지 정보',
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('생성 날짜', _formatDate(widget.generatedImage.createdAt)),
            _buildInfoRow('이미지 ID', widget.generatedImage.id),
            _buildInfoRow('한복 모델 ID', widget.generatedImage.hanbokModelId),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  ),
                ),
                child: Text(
                  '닫기',
                  style: TextStyle(
                    fontFamily: AppConstants.koreanFontFamily,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontFamily: AppConstants.koreanFontFamily,
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                color: Colors.white,
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