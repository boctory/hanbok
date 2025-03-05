import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/screens/image_detail_screen.dart';
import 'package:hanbok_app/services/storage_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final StorageService _storageService = StorageService();
  late Future<List<GeneratedImage>> _galleryFuture;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadGallery();
  }

  void _loadGallery() {
    setState(() {
      _isLoading = true;
      _galleryFuture = _storageService.getGallery();
    });
  }

  Future<void> _deleteImage(String imageId) async {
    setState(() {
      _isLoading = true;
    });

    await _storageService.deleteGeneratedImage(imageId);
    
    // Reload gallery
    _loadGallery();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _clearGallery() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '갤러리 비우기',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '정말로 모든 이미지를 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.',
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
        _isLoading = true;
      });

      await _storageService.clearGallery();
      
      // Reload gallery
      _loadGallery();
      
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          '내 작품 갤러리',
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
            icon: const Icon(Icons.delete_outline),
            onPressed: _clearGallery,
            tooltip: '갤러리 비우기',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadGallery();
          await _galleryFuture;
        },
        child: FutureBuilder<List<GeneratedImage>>(
          future: _galleryFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 60,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '갤러리를 불러오는 중 오류가 발생했습니다.',
                      style: AppConstants.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadGallery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(
                        '다시 시도',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.photo_library_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '갤러리가 비어 있습니다.',
                      style: AppConstants.subheadingStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '한복 이미지를 생성하여 갤러리에 추가해보세요!',
                      style: AppConstants.bodyStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.add_photo_alternate),
                      label: Text(
                        '이미지 생성하기',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            
            final images = snapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.all(AppConstants.paddingMedium),
              child: MasonryGridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final image = images[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageDetailScreen(
                            generatedImage: image,
                          ),
                        ),
                      ).then((_) => _loadGallery());
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        child: Stack(
                          children: [
                            // Image
                            CachedNetworkImage(
                              imageUrl: image.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: index % 2 == 0 ? 200 : 250,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: index % 2 == 0 ? 200 : 250,
                                color: Colors.grey[200],
                                child: const Icon(Icons.error),
                              ),
                            ),
                            
                            // Gradient overlay
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60,
                                decoration: BoxDecoration(
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
                            ),
                            
                            // Date
                            Positioned(
                              bottom: 8,
                              left: 8,
                              child: Text(
                                _formatDate(image.createdAt),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            // Delete button
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                    minHeight: 36,
                                  ),
                                  padding: EdgeInsets.zero,
                                  onPressed: () => _deleteImage(image.id),
                                  tooltip: '이미지 삭제',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}.${_formatTimeDigit(dateTime.month)}.${_formatTimeDigit(dateTime.day)}';
  }

  String _formatTimeDigit(int digit) {
    return digit.toString().padLeft(2, '0');
  }
} 