import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/services/api_service.dart';
import 'package:hanbok_app/services/storage_service.dart';
import 'package:hanbok_app/utils/image_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();
  final ScrollController _scrollController = ScrollController();
  
  File? _selectedImage;
  Uint8List? _webImage;
  List<HanbokModel> _hanbokModels = [];
  HanbokModel? _selectedHanbokModel;
  bool _isGenerating = false;
  GeneratedImage? _generatedImage;
  String _statusMessage = '';
  bool _showStatus = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHanbokModels();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHanbokModels() async {
    try {
      final models = await _apiService.getHanbokModels();
      setState(() {
        _hanbokModels = models;
      });
    } catch (e) {
      print('Error loading hanbok models: $e');
      // Show error message
      setState(() {
        _showStatus = true;
        _statusMessage = '한복 모델을 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (kIsWeb) {
        // 웹 환경에서는 Uint8List로 이미지 데이터를 받음
        Uint8List? imageData;
        if (source == ImageSource.gallery) {
          imageData = await ImageUtils.pickImageFromGalleryWeb();
        } else {
          imageData = await ImageUtils.takePhotoWeb();
        }

        setState(() {
          _webImage = imageData;
          _selectedImage = null; // 웹에서는 File 객체 사용 안함
          _isLoading = false;
        });
      } else {
        // 모바일 환경에서는 File 객체 사용
        File? image;
        if (source == ImageSource.gallery) {
          image = await ImageUtils.pickImageFromGallery();
        } else {
          image = await ImageUtils.takePhoto();
        }

        setState(() {
          _selectedImage = image;
          _webImage = null; // 모바일에서는 Uint8List 사용 안함
          _isLoading = false;
        });
      }

      if (_hasSelectedImage()) {
        // Scroll to Select section
        _scrollToSection(1);
      }
    } catch (e) {
      print('Error picking image: $e');
      setState(() {
        _showStatus = true;
        _statusMessage = '이미지를 선택하는 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  bool _hasSelectedImage() {
    return kIsWeb ? _webImage != null : _selectedImage != null;
  }

  Widget _buildSelectedImage() {
    if (kIsWeb) {
      return _webImage != null 
          ? Image.memory(_webImage!, fit: BoxFit.cover)
          : Container();
    } else {
      return _selectedImage != null 
          ? Image.file(_selectedImage!, fit: BoxFit.cover)
          : Container();
    }
  }

  void _selectHanbokModel(HanbokModel model) {
    setState(() {
      _selectedHanbokModel = model;
    });
    
    // Scroll to Generate section
    _scrollToSection(2);
  }

  Future<void> _generateImage() async {
    if (!_hasSelectedImage() || _selectedHanbokModel == null) {
      setState(() {
        _showStatus = true;
        _statusMessage = '이미지와 한복 스타일을 모두 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _showStatus = true;
      _statusMessage = '한복 이미지를 생성하는 중입니다...';
    });

    try {
      // Generate image using API - 사용자 얼굴 사진과 선택한 한복 스타일 합성
      final generatedImage = await _apiService.generateImage(
        kIsWeb ? _webImage : _selectedImage,
        _selectedHanbokModel!.id,
      );

      // Save to local storage
      await _storageService.saveGeneratedImage(generatedImage);

      setState(() {
        _generatedImage = generatedImage;
        _isGenerating = false;
        _showStatus = true;
        _statusMessage = '이미지가 성공적으로 생성되었습니다!';
      });
      
      // 3초 후 상태 메시지 숨기기
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStatus = false;
          });
        }
      });
      
      // Scroll to Output section
      _scrollToSection(2);
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _showStatus = true;
        _statusMessage = '이미지 생성 중 오류가 발생했습니다.';
      });
      print('Error generating image: $e');
    }
  }

  Future<void> _saveImage() async {
    if (_generatedImage == null) return;

    setState(() {
      _showStatus = false;
    });

    try {
      final success = await ImageUtils.saveImageToGallery(_generatedImage!.imageUrl);
      
      setState(() {
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
        _showStatus = true;
        _statusMessage = '이미지 저장 중 오류가 발생했습니다.';
      });
      print('Error saving image: $e');
    }
  }

  Future<void> _shareImage() async {
    if (_generatedImage == null) return;

    try {
      await ImageUtils.shareImage(_generatedImage!.imageUrl);
    } catch (e) {
      setState(() {
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

  void _scrollToSection(int index) {
    // Calculate the height of each section (approximate)
    final sectionHeight = MediaQuery.of(context).size.height;
    
    // Scroll to the section
    _scrollController.animateTo(
      sectionHeight * index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          ListView(
            controller: _scrollController,
            children: [
              // Home Section
              _buildHomeSection(),
              
              // Upload and Select Section
              _buildUploadSection(),
              
              // Output Section
              _buildOutputSection(),
            ],
          ),
          
          // Status message
          if (_showStatus)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                      ? AppConstants.errorColor.withOpacity(0.9)
                      : AppConstants.successColor.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
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
        ],
      ),
    );
  }

  Widget _buildHomeSection() {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // App bar
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.diamond_outlined,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '한복 AI',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        // Login action
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          color: AppConstants.textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        // Sign up action
                      },
                      child: Text(
                        'Sign up',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          color: AppConstants.textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.language),
                      onPressed: () {
                        // Language selection
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  child: Text(
                    'Try on Hanbok',
                    style: TextStyle(
                      fontFamily: AppConstants.koreanFontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Hero image
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(
                  image: AssetImage('assets/images/hero_banner.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // 그라데이션 오버레이 추가
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
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
                  // 텍스트 추가
                  Positioned(
                    bottom: 60,
                    left: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '한복의 아름다움을 경험하세요',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
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
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: ElevatedButton(
                      onPressed: () {
                        _scrollToSection(1);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        '시작하기',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Column(
        children: [
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          
          // Upload content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Upload Your Photo',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppConstants.textColor,
                      ),
                    ),
                  ),
                  Container(
                    width: 300,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.blue[200]!,
                        width: 1,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _hasSelectedImage()
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildSelectedImage(),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload,
                                size: 48,
                                color: Colors.blue[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Drag and drop your photo here or',
                                style: TextStyle(
                                  fontFamily: AppConstants.koreanFontFamily,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.file_upload),
                                label: const Text('Choose File'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Select Hanbok Style',
                    style: TextStyle(
                      fontFamily: AppConstants.koreanFontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildHanbokStyleOptions(),
                  const SizedBox(height: 40),
                  ElevatedButton.icon(
                    onPressed: !_hasSelectedImage() || _selectedHanbokModel == null || _isGenerating
                        ? null
                        : _generateImage,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      'Generate',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_isGenerating) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      'Processing your image...',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        color: AppConstants.textColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Progress bar
                    Container(
                      width: 300,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: FractionallySizedBox(
                        widthFactor: 0.6, // 60% progress
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHanbokStyleOptions() {
    return Container(
      height: 200,
      width: 600,
      child: GridView.count(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        children: [
          _buildHanbokStyleOption('assets/images/sample/sample1.png', 'style1'),
          _buildHanbokStyleOption('assets/images/sample/sample2.png', 'style2'),
          _buildHanbokStyleOption('assets/images/sample/sample3.png', 'style3'),
          _buildHanbokStyleOption('assets/images/sample/sample4.png', 'style4'),
        ],
      ),
    );
  }

  Widget _buildHanbokStyleOption(String imagePath, String styleId) {
    final bool isSelected = _selectedHanbokModel?.id == styleId;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          // Create a temporary HanbokModel with the selected style
          _selectedHanbokModel = HanbokModel(
            id: styleId,
            name: 'Hanbok $styleId',
            description: 'Traditional Korean Hanbok style',
            imageUrl: imagePath,
          );
        });
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.error),
                  );
                },
              ),
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutputSection() {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.grey[100],
      ),
      child: Column(
        children: [
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          
          // Output content
          Expanded(
            child: _generatedImage == null
                ? Center(
                    child: Text(
                      '이미지를 생성해주세요.',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontSize: 18,
                        color: AppConstants.textColor,
                      ),
                    ),
                  )
                : Center(
                    child: Container(
                      width: 400,
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppConstants.primaryColor,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                            child: Image.network(
                              _generatedImage!.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 400,
                                  color: Colors.grey[300],
                                  child: const Center(
                                    child: Icon(
                                      Icons.error,
                                      size: 50,
                                      color: Colors.red,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: _saveImage,
                                  tooltip: '다운로드',
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.share),
                                  onPressed: _shareImage,
                                  tooltip: '공유하기',
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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