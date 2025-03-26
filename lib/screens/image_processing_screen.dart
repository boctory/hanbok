import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';

class ImageProcessingScreen extends StatefulWidget {
  const ImageProcessingScreen({Key? key}) : super(key: key);

  @override
  _ImageProcessingScreenState createState() => _ImageProcessingScreenState();
}

class _ImageProcessingScreenState extends State<ImageProcessingScreen> {
  final ApiService _apiService = ApiService();
  
  File? _sourceImage;
  Uint8List? _webImage;
  String? _sourceImageUrl;
  String? _presetImageUrl;
  String? _generatedResultUrl;
  String? _taskId;
  bool _isLoading = false;
  bool _isGenerating = false;
  String _statusMessage = '';

  // 프리셋 이미지 URL 가져오기
  Future<void> _getPresetImage() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '프리셋 이미지를 가져오는 중...';
    });

    try {
      final presetUrl = await _apiService.getPresetImage();
      setState(() {
        _presetImageUrl = presetUrl;
        _statusMessage = '프리셋 이미지를 가져왔습니다.';
      });
    } catch (e) {
      setState(() {
        _statusMessage = '프리셋 이미지를 가져오는 데 실패했습니다: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 소스 이미지 업로드
  Future<void> _uploadImage() async {
    try {
      setState(() {
        _isLoading = true;
        _statusMessage = '이미지를 선택하는 중...';
      });

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        if (kIsWeb) {
          // 웹 환경에서는 Uint8List로 이미지 데이터를 받음
          final imageBytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = imageBytes;
            _sourceImage = null;
          });
        } else {
          // 모바일 환경에서는 File 객체 사용
          setState(() {
            _sourceImage = File(pickedFile.path);
            _webImage = null;
          });
        }

        setState(() {
          _statusMessage = '이미지를 업로드하는 중...';
        });

        // Edge Function을 통해 이미지 업로드
        final uploadedUrl = await _apiService.uploadSourceImage(
          kIsWeb ? _webImage! : _sourceImage!
        );

        setState(() {
          _sourceImageUrl = uploadedUrl;
          _statusMessage = '이미지 업로드 완료';
        });
      } else {
        setState(() {
          _statusMessage = '이미지 선택이 취소되었습니다.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '이미지 업로드 실패: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Generate 요청 및 polling 시작
  Future<void> _generateImage() async {
    if (_sourceImageUrl == null || _presetImageUrl == null) {
      setState(() {
        _statusMessage = '이미지와 프리셋을 모두 선택해주세요.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _statusMessage = '이미지 생성 요청 중...';
    });

    try {
      // Generate 요청 - taskId 받아옴
      final taskId = await _apiService.requestGeneration(
        _sourceImageUrl!,
        _presetImageUrl!
      );

      setState(() {
        _taskId = taskId;
        _statusMessage = '이미지 생성 중...';
      });

      // Polling 시작
      _startPolling();
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _statusMessage = '이미지 생성 요청 실패: $e';
      });
    }
  }

  // Polling으로 결과 확인
  Future<void> _startPolling() async {
    if (_taskId == null) return;

    const pollingInterval = Duration(seconds: 2);
    bool isCompleted = false;

    while (!isCompleted && mounted) {
      try {
        final result = await _apiService.checkGenerationResult(_taskId!);
        
        if (result['status'] == 'completed') {
          setState(() {
            _generatedResultUrl = result['resultUrl'];
            _isGenerating = false;
            _statusMessage = '이미지 생성 완료!';
          });
          isCompleted = true;
        } else {
          await Future.delayed(pollingInterval);
        }
      } catch (e) {
        print('Polling error: $e');
        await Future.delayed(pollingInterval);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // 화면 로드 시 프리셋 이미지 자동으로 가져오기
    _getPresetImage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('이미지 처리'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 상태 메시지 표시
            if (_statusMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_statusMessage),
              ),

            // 1. 프리셋 이미지 섹션
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '1. 프리셋 이미지',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_presetImageUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _presetImageUrl!,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('프리셋 이미지가 없습니다.'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _getPresetImage,
                        child: Text(_isLoading ? '로딩 중...' : '프리셋 이미지 가져오기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. 소스 이미지 업로드 섹션
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '2. 소스 이미지 업로드',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_sourceImage != null || _webImage != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: kIsWeb
                            ? Image.memory(_webImage!, fit: BoxFit.cover)
                            : Image.file(_sourceImage!, fit: BoxFit.cover),
                      )
                    else if (_sourceImageUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: _sourceImageUrl!,
                          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (context, url, error) => const Icon(Icons.error),
                          fit: BoxFit.cover,
                        ),
                      )
                    else if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text('이미지를 선택해주세요'),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _uploadImage,
                        child: Text(_isLoading ? '로딩 중...' : '이미지 업로드'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. 이미지 생성 섹션
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '3. 이미지 생성',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_sourceImageUrl != null && _presetImageUrl != null && !_isGenerating)
                            ? _generateImage
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(_isGenerating ? '생성 중...' : '이미지 생성하기'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. 결과 이미지 섹션
            if (_generatedResultUrl != null || _isGenerating)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '4. 결과 이미지',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_generatedResultUrl != null)
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: CachedNetworkImage(
                            imageUrl: _generatedResultUrl!,
                            placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                            errorWidget: (context, url, error) => const Icon(Icons.error),
                            fit: BoxFit.contain,
                          ),
                        )
                      else if (_isGenerating)
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('이미지 생성 중...'),
                              ],
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
    );
  }
} 