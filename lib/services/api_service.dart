import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late final SupabaseClient supabase;
  
  // Singleton 패턴
  factory ApiService() {
    return _instance;
  }
  
  ApiService._internal() {
    // Supabase.instance.client를 사용하여 이미 초기화된 클라이언트를 가져옵니다
    supabase = Supabase.instance.client;
  }
  
  // Get available Hanbok models
  Future<List<HanbokModel>> getHanbokModels() async {
    try {
      // print('Sending request to get-presets');
      final response = await supabase.functions.invoke(
        'get-presets',
        body: {'name': 'Functions'},
      );

      // print('Response status: ${response.status}');
      // print('Response data: ${response.data}');
      // print('Response data type: ${response.data.runtimeType}');

      if (response.status == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>;

        final List<dynamic> presetList = jsonData['presets'] as List<dynamic>;
        final List<Map<String, dynamic>> presets =
            presetList.map((item) => Map<String, dynamic>.from(item)).toList();

        final models = presets.map((model) => HanbokModel.fromJson({
              'id': model['id'],
              'name': model['name'],
              'imageUrl': model['image_url'],
              'description': '${model['name'] ?? 'Unnamed'} 스타일의 한복입니다.',
            })).toList();

        // print('✅ Parsed Models Count: ${models.length}');
        return models;
      } else {
        // print('❌ Server error: ${response.status}, Data: ${response.data}');
        return _getFallbackHanbokModels();
      }
    } catch (e) {
      // print('❌ Error fetching Hanbok models: $e');
      // print('🔍 Error details: ${e.toString()}');
      if (e.toString().contains('XMLHttpRequest error')) {
        // print('CORS error detected');
      }
      return _getFallbackHanbokModels();
    }
  }
  
  // 폴백 데이터를 위한 별도 메서드
  List<HanbokModel> _getFallbackHanbokModels() {
    return [
      HanbokModel(
        id: 'style1',
        name: '전통 한복 (여성)',
        imageUrl: 'assets/images/sample/sample1.png',
        description: '전통적인 여성용 한복 모델입니다.',
      ),
      HanbokModel(
        id: 'style2',
        name: '현대적 한복 (여성)',
        imageUrl: 'assets/images/sample/sample2.png',
        description: '현대적인 스타일의 여성용 한복 모델입니다.',
      ),
      HanbokModel(
        id: 'style3',
        name: '전통 한복 (남성)',
        imageUrl: 'assets/images/sample/sample3.png',
        description: '전통적인 남성용 한복 모델입니다.',
      ),
    ];
  }
  
  // Generate AI image with user photo and selected Hanbok model
  Future<Uint8List> _cropFace(dynamic userPhoto) async {
    try {
      final imageBytes = kIsWeb ? userPhoto as Uint8List : await (userPhoto as File).readAsBytes();
      // 얼굴 인식 없이 이미지 전체를 반환
      return imageBytes;
    } catch (e) {
      // print('Error in _cropFace: $e');
      rethrow;
    }
  }

  Future<String> _uploadCroppedFace(Uint8List croppedFace) async {
    try {
      // print('Sending request to upload-swapImage');
      final base64Face = base64Encode(croppedFace);
      final userId = supabase.auth.currentUser?.id;
      // print('Request details - base64Face length: ${base64Face.length}, userId: $userId');

      final response = await supabase.functions.invoke(
        'upload-swapImage',
        body: {
          'croppedFace': base64Face,
          'userId': userId,
        },
      );

      // print('Response status: ${response.status}');
      // print('Response data: ${response.data}');
      // print('Response data type: ${response.data.runtimeType}');

      if (response.status == 200) {
        final Map<String, dynamic> jsonData = response.data is String
            ? jsonDecode(response.data)
            : response.data as Map<String, dynamic>;
        // print('Parsed data: ${jsonData}');
        return jsonData['swapImageUrl'] as String;
      } else {
        // print('❌ Server error: ${response.status}, Data: ${response.data}');
        throw Exception('Failed to upload cropped face: ${response.status}, Data: ${response.data}');
      }
    } catch (e) {
      // print('❌ Error in _uploadCroppedFace: $e');
      // print('🔍 Error details: ${e.toString()}');
      if (e.toString().contains('XMLHttpRequest error')) {
        // print('CORS error detected');
      }
      rethrow;
    }
  }

  Future<String> generateImage(dynamic userPhoto, String hanbokModelId) async {
    try {
      // print('Generating image for hanbok model ID: $hanbokModelId');

      final hanbokModels = await getHanbokModels();
      // print('Available hanbok models: ${hanbokModels.map((m) => '${m.id}: ${m.name}').join(', ')}');

      if (hanbokModels.isEmpty) {
        throw Exception('No hanbok models available');
      }

      HanbokModel? selectedModel;
      try {
        selectedModel = hanbokModels.firstWhere(
          (model) => model.id.trim() == hanbokModelId.trim(),
          orElse: () => hanbokModels.first,
        );
      } catch (e) {
        // print('Error finding model: $e');
        selectedModel = hanbokModels.first;
      }
      // print('Selected Hanbok Model Name: ${selectedModel.name}');

      final croppedFace = await _cropFace(userPhoto);
      final swapImageUrl = await _uploadCroppedFace(croppedFace);
      // print('Swap Image URL: $swapImageUrl');

      final userId = supabase.auth.currentUser?.id;
      // print('Sending request to face-swap with userId: $userId');
      final response = await supabase.functions.invoke(
        'face-swap',
        body: {
          'targetImageUrl': selectedModel.imageUrl,
          'swapImageUrl': swapImageUrl,
          'userId': userId,
        },
      );

      // print('Response status: ${response.status}');
      // print('Response data: ${response.data}');

      if (response.status == 200) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        // print('Parsed data: $jsonData');
        if (jsonData['task_id'] == null) {
          throw Exception('task_id is missing in response data: $jsonData');
        }
        return jsonData['task_id'] as String;
      } else {
        throw Exception('Failed to generate image: Status ${response.status}, Data: ${response.data}');
      }
    } catch (e) {
      // print('❌ Error generating image: $e');
      // print('🔍 Error details: ${e.toString()}');
      if (e.toString().contains('XMLHttpRequest error')) {
        // print('CORS error detected');
      }
      rethrow;
    }
  }
  
  Future<GeneratedImage> getGeneratedImage(String taskId) async {
    const maxAttempts = 30;
    const delaySeconds = 3;
    final apiKey = dotenv.env['PIAPI_API_KEY'] ?? '';
    const piApiUrl = 'https://api.piapi.ai/api/v1/task';

    if (apiKey.isEmpty) {
      throw Exception('PIAPI_API_KEY is not set in .env');
    }

    for (int i = 0; i < maxAttempts; i++) {
      try {
        // print('Polling PIAPI for task_id: $taskId, attempt: ${i + 1}');

        final response = await http.get(
          Uri.parse('$piApiUrl/$taskId'),
          headers: {
            'x-api-key': apiKey,
            'User-Agent': 'Flutter-App/1.0.0',
            'Accept': '*/*',
            'Cache-Control': 'no-cache',
          },
        );

        // print('PIAPI Response status: ${response.statusCode}');
        // print('PIAPI Response data: ${response.body}');

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final status = jsonData['data']['status'];
          final output = jsonData['data']['output'];

          // output이 null이 아닌지 확인
          if (output != null && status == 'completed') {
            final swapImageUrl = jsonData['data']['input']['swap_image'] as String;
            final targetImageUrl = jsonData['data']['input']['target_image'] as String;
            final imageUrl = jsonData['data']['output']['image_url'] as String?;
            final userId = jsonData['data']['input']['userId'] as String?;
            final taskType = jsonData['data']['task_type'] as String? ?? 'face-swap';

            if (imageUrl == null) {
              throw Exception('image_url is missing in PIAPI output');
            }

            final saveResponse = await Supabase.instance.client.functions.invoke(
              'face-swap/save-result',
              body: {
                'task_id': taskId,
                'swap_image': swapImageUrl,
                'target_image': targetImageUrl,
                'image_url': imageUrl,
                'userId': userId,
                'task_type': taskType,
              },
            );

            // print('Save result response status: ${saveResponse.status}');
            // print('Save result response data: ${saveResponse.data}');

            if (saveResponse.status == 200) {
              final saveJsonData = saveResponse.data is String ? jsonDecode(saveResponse.data) : saveResponse.data;
              // print('saveJsonData: $saveJsonData');
              if (saveJsonData['image_url'] == null) {
                throw Exception('image_url is missing in save result response');
              }
              return GeneratedImage.fromJson({
                'id': taskId,
                'imageUrl': saveJsonData['image_url'] as String,
                'createdAt': DateTime.now().toIso8601String(),
                'hanbokModelId': '',
              });
            } else {
              throw Exception('Failed to save result: Status ${saveResponse.status}, Data: ${saveResponse.data}');
            }
          } else {
            // print('Task still pending, status: $status, output: $output, retrying...');
            await Future.delayed(Duration(seconds: delaySeconds));
          }
        } else {
          throw Exception('Failed to fetch PIAPI status: Status ${response.statusCode}, Data: ${response.body}');
        }
      } catch (e) {
        // print('❌ Error fetching generated image: $e');
        if (i == maxAttempts - 1) {
          return GeneratedImage(
            id: 'mock-id-${DateTime.now().millisecondsSinceEpoch}',
            imageUrl: 'https://picsum.photos/400/600',
            createdAt: DateTime.now(),
            hanbokModelId: '',
          );
        }
        await Future.delayed(Duration(seconds: delaySeconds));
      }
    }

    throw Exception('Timeout waiting for image generation');
  }
  
  // Get user's gallery of generated images
  Future<List<GeneratedImage>> getUserGallery() async {
    try {
      final response = await supabase.functions.invoke(
        'get-user-gallery',
        body: {},
      );
      
      if (response.status == 200) {
        final List<dynamic> data = response.data['images'];
        return data.map((image) => GeneratedImage.fromJson(image)).toList();
      } else {
        throw Exception('Failed to load user gallery');
      }
    } catch (e) {
      // print('Error fetching user gallery: $e');
      return [
        GeneratedImage(
          id: 'mock-id-1',
          imageUrl: 'https://picsum.photos/400/600?random=1',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          hanbokModelId: 'style1',
        ),
        GeneratedImage(
          id: 'mock-id-2',
          imageUrl: 'https://picsum.photos/400/600?random=2',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          hanbokModelId: 'style2',
        ),
      ];
    }
  }

  // 새로운 요구사항에 맞는 API 메서드 구현

  // 1. 프리셋 이미지 가져오기 (get-preset Edge Function 호출)
  Future<String> getPresetImage() async {
    try {
      final response = await supabase.functions.invoke(
        'get-preset',
        method: 'GET',
      );
      
      if (response.status == 200) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        final presetUrl = jsonData['presetUrl'] as String;
        return presetUrl;
      } else {
        throw Exception('Failed to get preset image: ${response.status}');
      }
    } catch (e) {
      // 오류 발생 시 샘플 이미지 URL 반환
      return 'https://picsum.photos/400/600?random=1';
    }
  }

  // 2. 소스 이미지 업로드 (upload-image Edge Function 호출)
  Future<String> uploadSourceImage(dynamic imageSource) async {
    try {
      final Uint8List imageBytes = kIsWeb 
          ? imageSource as Uint8List 
          : await (imageSource as File).readAsBytes();
      
      final base64Image = base64Encode(imageBytes);
      
      final response = await supabase.functions.invoke(
        'upload-image',
        method: 'POST',
        body: {
          'image': base64Image,
        },
      );
      
      if (response.status == 200) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        final imageUrl = jsonData['url'] as String;
        return imageUrl;
      } else {
        throw Exception('Failed to upload image: ${response.status}');
      }
    } catch (e) {
      // 에러 로깅
      print('Error uploading image: $e');
      rethrow;
    }
  }

  // 3. Generate 요청 (generate Edge Function 호출)
  Future<String> requestGeneration(String sourceUrl, String presetUrl) async {
    try {
      final response = await supabase.functions.invoke(
        'generate',
        method: 'POST',
        body: {
          'sourceUrl': sourceUrl,
          'presetUrl': presetUrl,
        },
      );
      
      if (response.status == 200) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        final taskId = jsonData['taskId'] as String;
        return taskId;
      } else {
        throw Exception('Failed to request generation: ${response.status}');
      }
    } catch (e) {
      // 에러 로깅
      print('Error requesting generation: $e');
      rethrow;
    }
  }

  // 4. 결과 확인 (check-result Edge Function 호출)
  Future<Map<String, dynamic>> checkGenerationResult(String taskId) async {
    try {
      final response = await supabase.functions.invoke(
        'check-result',
        method: 'GET',
        queryParams: {'taskId': taskId},
      );
      
      if (response.status == 200) {
        final jsonData = response.data is String ? jsonDecode(response.data) : response.data;
        return {
          'status': jsonData['status'] as String? ?? 'pending',
          'resultUrl': jsonData['result_url'] as String?,
        };
      } else {
        throw Exception('Failed to check generation result: ${response.status}');
      }
    } catch (e) {
      // 에러 로깅
      print('Error checking generation result: $e');
      // 오류 발생 시 pending 상태 반환
      return {'status': 'pending'};
    }
  }
}