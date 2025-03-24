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
  final PageController _pageController = PageController();
  final PageController _hanbokStyleController = PageController();

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
        // Silently fail but don't show error to user
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
        } else if (result.status == LoginStatus.cancelled) {
          // User cancelled login, don't show error
          return;
        } else {
          setState(() {
            _showStatus = true;
            _statusMessage = '로그인에 실패했습니다. 다시 시도해주세요.';
          });
          // Hide status message after 3 seconds
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() {
                _showStatus = false;
              });
            }
          });
        }
      } catch (e) {
        print('Facebook login error: $e');
        // On web platforms just silently fail the Facebook login but don't crash the app
        setState(() {
          _showStatus = true;
          _statusMessage = '로그인 중 오류가 발생했습니다.';
        });
        // Hide status message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showStatus = false;
            });
          }
        });
      }
    } else {
      // On mobile we'll just show a message that Facebook login is not supported
      setState(() {
        _showStatus = true;
        _statusMessage = '모바일에서는 Facebook 로그인이 지원되지 않습니다.';
      });
      
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
    // PageController를 사용하여 부드럽게 페이지 이동
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOutCubic,
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
                physics: const ClampingScrollPhysics(),
                children: [
                  _buildHomeSection(),
                  _buildUploadSection(),
                  _buildOutputSection(),
                ],
              ),
            ),
            // 상태 메시지 - 더 모던한 디자인으로 업데이트
            if (_showStatus)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: _statusMessage.contains('실패') || _statusMessage.contains('오류')
                      ? AppConstants.errorColor
                      : AppConstants.successColor,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage.contains('실패') || _statusMessage.contains('오류')
                          ? Icons.error_outline
                          : Icons.check_circle_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() {
                          _showStatus = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 로고 디자인 - 모던한 스타일로 업데이트
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppConstants.primaryColor,
                      AppConstants.secondaryColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontFamily: AppConstants.koreanFontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppConstants.textColor,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          
          // 로그인 버튼 (웹에서만 표시) - 모던한 스타일로 업데이트
          if (kIsWeb)
            _isLoggedIn
                ? Row(
                    children: [
                      if (_userData != null && _userData!['picture'] != null)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.primaryColor.withOpacity(0.5),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(_userData!['picture']['data']['url']),
                          ),
                        ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _logout,
                        style: TextButton.styleFrom(
                          foregroundColor: AppConstants.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: const Text('로그아웃'),
                      ),
                    ],
                  )
                : ElevatedButton.icon(
                    onPressed: _login,
                    icon: const Icon(Icons.facebook, color: Colors.white),
                    label: const Text('Facebook 로그인'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1877F2), // Facebook blue
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
        ],
      ),
    );
  }

  Widget _buildHomeSection() {
    return Container(
      color: AppConstants.backgroundColor,
      child: Column(
        children: [
          // 구분선 추가
          Container(
            height: 1,
            color: Colors.grey.withOpacity(0.2),
          ),
          
          // Hero image - 전체 화면 활용 및 모던한 디자인
          Expanded(
            child: Stack(
              children: [
                // 배경 이미지
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/hero_banner.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
                // 그라데이션 오버레이
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
                // 콘텐츠 층
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 메인 제목
                        Text(
                          '한복의 아름다움을\n당신에게',
                          style: TextStyle(
                            fontFamily: AppConstants.traditionalFontFamily,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.3,
                            letterSpacing: -0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // 부제목
                        Text(
                          'AI로 만드는 나만의 한복 이미지',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
                            fontSize: 18,
                            color: Colors.white.withOpacity(0.9),
                            letterSpacing: -0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        // 시작하기 버튼
                        SizedBox(
                          width: 200,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _scrollToSection(1);
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: Text(
                              '시작하기',
                              style: TextStyle(
                                fontFamily: AppConstants.koreanFontFamily,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConstants.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                              ),
                              elevation: AppConstants.elevationMedium,
                              shadowColor: AppConstants.primaryColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Container(
      color: AppConstants.backgroundColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              children: [
                // 섹션 타이틀
                Text(
                  '사진 업로드',
                  style: TextStyle(
                    fontFamily: AppConstants.traditionalFontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '한복을 입고 싶은 인물 사진을 업로드해주세요',
                  style: TextStyle(
                    fontFamily: AppConstants.koreanFontFamily,
                    fontSize: 16,
                    color: AppConstants.lightTextColor,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 24),
                
                // 이미지 선택 영역
                _hasSelectedImage() 
                ? Container(
                    width: double.infinity,
                    height: 280,
                    decoration: AppConstants.cardDecoration.copyWith(
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.borderRadiusMedium - 2),
                              ),
                              color: Colors.grey[200],
                            ),
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.borderRadiusMedium - 2),
                              ),
                              child: _buildSelectedImage(),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '업로드된 사진',
                                style: TextStyle(
                                  fontFamily: AppConstants.koreanFontFamily,
                                  fontWeight: FontWeight.w500,
                                  color: AppConstants.textColor,
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('변경하기'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppConstants.primaryColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        onTap: () => _pickImage(ImageSource.gallery),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 30,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '사진 업로드하기',
                              style: TextStyle(
                                fontFamily: AppConstants.koreanFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '클릭하여 갤러리에서 사진 선택',
                              style: TextStyle(
                                fontFamily: AppConstants.koreanFontFamily,
                                fontSize: 14,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 40),
                
                // 한복 스타일 선택 섹션
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '한복 스타일 선택',
                            style: TextStyle(
                              fontFamily: AppConstants.traditionalFontFamily,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppConstants.textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '원하는 한복 스타일을 선택해주세요',
                            style: TextStyle(
                              fontFamily: AppConstants.koreanFontFamily,
                              fontSize: 16,
                              color: AppConstants.lightTextColor,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_selectedHanbokModel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppConstants.successColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppConstants.successColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '선택됨',
                              style: TextStyle(
                                fontFamily: AppConstants.koreanFontFamily,
                                fontSize: 14,
                                color: AppConstants.successColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildHanbokStyleOptions(),
                const SizedBox(height: 40),
                
                // 생성 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: !_hasSelectedImage() || _selectedHanbokModel == null || _isGenerating
                        ? null
                        : _generateImage,
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(
                      '한복 이미지 생성하기',
                      style: TextStyle(
                        fontFamily: AppConstants.koreanFontFamily,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppConstants.primaryColor.withOpacity(0.3),
                      elevation: AppConstants.elevationSmall,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // 로딩 상태
                if (_isGenerating) ...[
                  Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '한복 이미지를 생성 중입니다...',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
                            fontSize: 16,
                            color: AppConstants.textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '잠시만 기다려주세요',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
                            fontSize: 14,
                            color: AppConstants.lightTextColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Progress bar
                        Container(
                          width: 300,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            widthFactor: 0.6, // 60% progress
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
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
      height: 320,
      child: FutureBuilder<List<HanbokModel>>(
        future: _hanbokModelsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppConstants.errorColor,
                    size: 40,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '한복 스타일을 불러오는데 실패했습니다.',
                    style: TextStyle(
                      fontFamily: AppConstants.koreanFontFamily,
                      color: AppConstants.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _hanbokModelsFuture = _apiService.getHanbokModels();
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final models = snapshot.data ?? [];
          
          return Column(
            children: [
              Expanded(
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
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          onTap: () {
                            setState(() {
                              _selectedHanbokModel = model;
                            });
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            child: Stack(
                              children: [
                                // 이미지
                                Positioned.fill(
                                  child: CachedNetworkImage(
                                    imageUrl: model.imageUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) => Container(
                                      color: Colors.grey[200],
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, color: AppConstants.errorColor),
                                          const SizedBox(height: 8),
                                          Text(
                                            '이미지를 불러올 수 없습니다',
                                            style: TextStyle(
                                              fontFamily: AppConstants.koreanFontFamily,
                                              fontSize: 14,
                                              color: AppConstants.errorColor,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 그라데이션 오버레이
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.6),
                                        ],
                                        stops: const [0.7, 1.0],
                                      ),
                                    ),
                                  ),
                                ),
                                
                                // 텍스트
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      model.name,
                                      style: const TextStyle(
                                        fontFamily: AppConstants.koreanFontFamily,
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                
                                // 선택 표시
                                if (_selectedHanbokModel?.id == model.id)
                                  Positioned(
                                    top: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppConstants.primaryColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // 페이지 인디케이터
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
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
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.textColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.arrow_forward_ios,
                      color: AppConstants.primaryColor,
                      size: 20,
                    ),
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
      color: AppConstants.backgroundColor,
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 이미지 없을 때 보여줄 아이콘
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppConstants.primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.image_search,
                            size: 40,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '생성된 이미지가 없습니다',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: AppConstants.textColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '사진을 업로드하고 한복 스타일을 선택한 후\n이미지를 생성해보세요',
                          style: TextStyle(
                            fontFamily: AppConstants.koreanFontFamily,
                            fontSize: 16,
                            color: AppConstants.lightTextColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _scrollToSection(1),
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('이미지 생성하기'),
                          style: AppConstants.primaryButtonStyle,
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    children: [
                      // 섹션 제목
                      Text(
                        '생성 결과',
                        style: TextStyle(
                          fontFamily: AppConstants.traditionalFontFamily,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '인공지능이 생성한 한복 이미지입니다',
                        style: TextStyle(
                          fontFamily: AppConstants.koreanFontFamily,
                          fontSize: 16,
                          color: AppConstants.lightTextColor,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // 생성된 이미지 카드
                      Container(
                        decoration: AppConstants.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 이미지 부분
                            ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(AppConstants.borderRadiusMedium),
                                topRight: Radius.circular(AppConstants.borderRadiusMedium),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: Image.network(
                                  _generatedImage!.imageUrl,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / 
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            size: 50,
                                            color: AppConstants.errorColor,
                                          ),
                                          const SizedBox(height: 16),
                                          Text(
                                            '이미지를 불러올 수 없습니다',
                                            style: TextStyle(
                                              fontFamily: AppConstants.koreanFontFamily,
                                              fontSize: 16,
                                              color: AppConstants.errorColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            
                            // 정보 및 공유 버튼
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.check_circle,
                                        color: AppConstants.successColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '생성 완료',
                                        style: TextStyle(
                                          fontFamily: AppConstants.koreanFontFamily,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppConstants.successColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '이미지 공유하기',
                                    style: TextStyle(
                                      fontFamily: AppConstants.koreanFontFamily,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppConstants.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      _buildShareButton(
                                        icon: Icons.download,
                                        label: '다운로드',
                                        color: AppConstants.accentColor,
                                        onTap: _saveImage,
                                      ),
                                      _buildShareButton(
                                        icon: Icons.share,
                                        label: '공유하기',
                                        color: AppConstants.successColor,
                                        onTap: _shareImage,
                                      ),
                                      _buildShareButton(
                                        icon: Icons.camera_alt,
                                        label: 'Instagram',
                                        color: Colors.purple,
                                        onTap: _shareToInstagram,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // 새 이미지 생성 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton.icon(
                          onPressed: _resetImageSelection,
                          icon: const Icon(Icons.refresh),
                          label: Text(
                            '새 이미지 생성하기',
                            style: TextStyle(
                              fontFamily: AppConstants.koreanFontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppConstants.primaryColor,
                            elevation: AppConstants.elevationSmall,
                            side: BorderSide(color: AppConstants.primaryColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildShareButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppConstants.koreanFontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ImageSource {
  gallery,
  camera,
} 