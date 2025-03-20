import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/services/api_service.dart';
import 'package:hanbok_app/services/storage_service.dart';
import 'package:hanbok_app/utils/image_utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({super.key});

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
  bool _isLoggedIn = false;
  Map<String, dynamic>? _userData;
  late Future<List<HanbokModel>> _hanbokModelsFuture;
  PageController _pageController = PageController();
  PageController _hanbokStyleController = PageController();

  @override
  void initState() {
    super.initState();
    _hanbokModelsFuture = _apiService.getHanbokModels();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pageController.dispose();
    _hanbokStyleController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    if (kIsWeb) {
      try {
        final accessToken = await FacebookAuth.instance.accessToken;
        setState(() {
          _isLoggedIn = accessToken != null;
        });
        
        if (_isLoggedIn) {
          final userData = await FacebookAuth.instance.getUserData();
          setState(() {
            _userData = userData;
          });
        }
      } catch (e) {
        print('Facebook login check error: $e');
      }
    }
  }

  Future<void> _login() async {
    if (kIsWeb) {
      try {
        final LoginResult result = await FacebookAuth.instance.login();
        if (result.status == LoginStatus.success) {
          final userData = await FacebookAuth.instance.getUserData();
          setState(() {
            _isLoggedIn = true;
            _userData = userData;
          });
        }
      } catch (e) {
        print('Facebook login error: $e');
        setState(() {
          _showStatus = true;
          _statusMessage = '로그인 중 오류가 발생했습니다.';
        });
      }
    } else {
      // 모바일에서는 다른 로그인 방식 사용 또는 메시지 표시
      setState(() {
        _showStatus = true;
        _statusMessage = '모바일에서는 Facebook 로그인이 지원되지 않습니다.';
      });
      
      // 3초 후 상태 메시지 숨기기
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showStatus = false;
          });
        }
      });
    }
  }

  Future<void> _logout() async {
    if (kIsWeb) {
      try {
        await FacebookAuth.instance.logOut();
        setState(() {
          _isLoggedIn = false;
          _userData = null;
        });
      } catch (e) {
        print('Facebook logout error: $e');
      }
    }
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
      // Generate image using API - task_id를 받아옴
      final taskId = await _apiService.generateImage(
        kIsWeb ? _webImage : _selectedImage,
        _selectedHanbokModel!.id,
      );

      // task_id로 생성된 이미지 결과를 폴링
      final generatedImage = await _apiService.getGeneratedImage(taskId);

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

  Future<void> _shareToInstagram() async {
    if (_generatedImage == null) return;
    
    try {
      await ImageUtils.shareToInstagram(_generatedImage!.imageUrl);
    } catch (e) {
      print('Error sharing to Instagram: $e');
      setState(() {
        _showStatus = true;
        _statusMessage = 'Instagram 공유 중 오류가 발생했습니다.';
      });
    }
  }

  void _resetImageSelection() {
    setState(() {
      _selectedImage = null;
      _webImage = null;
      _generatedImage = null;
    });
    
    // Scroll to Upload section
    _scrollToSection(1);
  }

  void _scrollToSection(int index) {
    // PageController를 사용하여 페이지 이동
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: PageView(
                controller: _pageController,
                scrollDirection: Axis.vertical,
                children: [
                  _buildHomeSection(),
                  _buildUploadSection(),
                  _buildOutputSection(),
                ],
              ),
            ),
            // 상태 메시지
            if (_showStatus)
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                      ? Colors.red.withOpacity(0.9)
                      : Colors.green.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 로고 디자인
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.pink.shade300,
                  Colors.purple.shade300,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  '한복 AI',
                  style: TextStyle(
                    fontFamily: AppConstants.koreanFontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          // 로그인 버튼 (웹에서만 표시)
          if (kIsWeb)
            _isLoggedIn
                ? Row(
                    children: [
                      if (_userData != null && _userData!['picture'] != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(_userData!['picture']['data']['url']),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _logout,
                        child: const Text('로그아웃'),
                      ),
                    ],
                  )
                : TextButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.facebook, color: Colors.blue),
                    label: const Text('Facebook 로그인'),
                  ),
        ],
      ),
    );
  }

  Widget _buildHomeSection() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
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
                          fontWeight: FontWeight.bold,
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
      color: Colors.white,
      child: Column(
        children: [
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          
          // Upload content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 이미지 선택 버튼
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '나의 사진 선택',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('갤러리'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('카메라'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_hasSelectedImage()) ...[
                        Container(
                          height: 200,
                          width: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildSelectedImage(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 한복 스타일 선택
                Text(
                  '한복 스타일 선택',
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
        ],
      ),
    );
  }

  Widget _buildHanbokStyleOptions() {
    return SizedBox(
      height: 300,
      child: FutureBuilder<List<HanbokModel>>(
        future: _hanbokModelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('한복 스타일을 불러오는데 실패했습니다.'),
            );
          }

          final models = snapshot.data ?? [];
          
          return Column(
            children: [
              SizedBox(
                height: 250,
                child: PageView.builder(
                  controller: _hanbokStyleController,
                  itemCount: models.length,
                  onPageChanged: (index) {
                    setState(() {
                      _selectedHanbokModel = models[index];
                    });
                  },
                  itemBuilder: (context, index) {
                    final model = models[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: CachedNetworkImage(
                                imageUrl: model.imageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: Colors.grey[200],
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.grey[200],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                color: Colors.black.withOpacity(0.5),
                                child: Text(
                                  model.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            if (_selectedHanbokModel?.id == model.id)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
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
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios),
                    onPressed: () {
                      _hanbokStyleController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        _selectedHanbokModel?.name ?? '한복 스타일을 선택하세요',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () {
                      _hanbokStyleController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ],
          );
        },
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
                                const SizedBox(width: 16),
                                IconButton(
                                  icon: const Icon(Icons.camera),
                                  onPressed: _shareToInstagram,
                                  tooltip: 'Instagram에 공유',
                                  color: Colors.purple,
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _resetImageSelection,
                            icon: const Icon(Icons.refresh),
                            label: const Text('다른 사진으로 시도하기'),
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