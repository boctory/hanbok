import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:hanbok_app/utils/logger.dart';

// 한복 카테고리 모델
class HanbokCategory {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final bool isActive;

  HanbokCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.isActive = true,
  });

  factory HanbokCategory.fromJson(Map<String, dynamic> json) {
    return HanbokCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'],
      isActive: json['is_active'] ?? true,
    );
  }
}

// API 서비스 클래스
class ApiService {
  static final ApiService _instance = ApiService._internal();
  
  factory ApiService() {
    return _instance;
  }
  
  final SupabaseClient _supabaseClient;
  final String _functionsUrl;
  bool _isDebugMode = true;  // 디버그 로깅 활성화
  List<HanbokCategory> _categories = [];
  
  ApiService._internal() : 
    _supabaseClient = Supabase.instance.client,
    _functionsUrl = '${dotenv.env['SUPABASE_URL'] ?? 'https://awxineofxcvdpsxlvtxv.supabase.co'}/functions/v1';
  
  void _logDebug(String message) {
    if (_isDebugMode) {
      debugPrint('[HanbokAPI] $message');
    }
  }
  
  // 카테고리별 한복 모델 조회
  Future<List<HanbokModel>> getHanbokModels({String? categorySlug}) async {
    try {
      _logDebug('🔍 Fetching Hanbok models ${categorySlug != null ? "for category: $categorySlug" : ""}');
      
      final url = '$_functionsUrl/get-preset${categorySlug != null ? '?category_slug=$categorySlug' : ''}';
      _logDebug('🌐 Request URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
        },
      );
      
      _logDebug('✅ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> models = jsonData['data'];
        
        _logDebug('✅ Successfully parsed ${models.length} models');
        return models.map((model) => HanbokModel.fromJson(model)).toList();
      } else if (response.statusCode == 404) {
        _logDebug('⚠️ No models found');
        return [];
      } else {
        _logDebug('❌ Server error: ${response.statusCode}, Body: ${response.body}');
        throw Exception('Failed to load hanbok models');
      }
    } catch (e) {
      _logDebug('❌ Exception in getHanbokModels: $e');
      throw Exception('Failed to load hanbok models: $e');
    }
  }
  
  // 모든 카테고리 조회
  Future<List<HanbokCategory>> getCategories() async {
    try {
      _logDebug('🔍 Fetching categories');
      
      final supabaseUrl = dotenv.env['SUPABASE_URL'] ?? 'https://awxineofxcvdpsxlvtxv.supabase.co';
      final supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? _supabaseClient.auth.currentSession?.accessToken ?? '';
      
      final url = Uri.parse('$supabaseUrl/rest/v1/hanbok_categories?select=*&is_active=eq.true&order=name');
      
      final response = await http.get(
        url,
        headers: {
          'apikey': supabaseKey,
          'Authorization': 'Bearer $supabaseKey',
          'Content-Type': 'application/json',
          'Prefer': 'return=representation'
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> categories = jsonDecode(response.body);
        _logDebug('✅ Retrieved ${categories.length} categories');
        
        _categories = categories.map((category) => HanbokCategory.fromJson(category)).toList();
        return _categories;
      } else {
        _logDebug('❌ Failed to load categories: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      _logDebug('❌ Exception in getCategories: $e');
      throw Exception('Failed to load categories: $e');
    }
  }
  
  // 이미지 업로드
  Future<String> uploadImage(Uint8List imageBytes) async {
    try {
      _logDebug('📤 Uploading image');
      
      // 이미지를 Base64로 인코딩
      final base64Image = 'data:image/png;base64,${base64Encode(imageBytes)}';
      
      // 현재 사용자 ID 가져오기
      final userId = _supabaseClient.auth.currentUser?.id;
      _logDebug('👤 User ID: ${userId ?? 'anonymous'}');
      
      // Edge Function에 이미지 업로드 요청
      final url = '$_functionsUrl/upload-image';
      _logDebug('🌐 Request URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'image_data': base64Image,
          'user_id': userId,
        }),
      );
      
      _logDebug('✅ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        _logDebug('📄 Uploaded image URL: ${jsonResponse['public_url']}');
        return jsonResponse['public_url'];
      } else {
        _logDebug('❌ Error uploading image: ${response.body}');
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      _logDebug('❌ Exception in uploadImage: $e');
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // 사용자의 생성된 이미지 조회
  Future<List<GeneratedImage>> getUserGeneratedImages() async {
    try {
      _logDebug('🔍 Fetching user generated images');
      
      final userId = _supabaseClient.auth.currentUser?.id;
      
      if (userId == null) {
        _logDebug('⚠️ No authenticated user');
        return []; // 로그인하지 않은 경우 빈 목록 반환
      }
      
      _logDebug('👤 User ID: $userId');
      
      final response = await _supabaseClient
        .from('generated_images')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
      
      _logDebug('✅ Retrieved ${response.length} generated images');
      
      final List<dynamic> images = response;
      return images.map((image) => GeneratedImage.fromJson(image)).toList();
    } catch (e) {
      _logDebug('❌ Exception in getUserGeneratedImages: $e');
      throw Exception('Failed to load generated images: $e');
    }
  }
  
  // 사용자 이미지 업로드 (File 객체)
  Future<String> uploadUserImage(dynamic image) async {
    try {
      _logDebug('📤 Uploading user image');
      
      if (image is File) {
        // 파일을 바이트로 읽기
        final bytes = await image.readAsBytes();
        return uploadImage(bytes);
      } else if (image is Uint8List) {
        // 이미 바이트 형태인 경우 그대로 사용
        return uploadImage(image);
      } else {
        throw Exception('Unsupported image type');
      }
    } catch (e) {
      _logDebug('❌ Exception in uploadUserImage: $e');
      throw Exception('Failed to upload user image: $e');
    }
  }
  
  // 이미지 생성 요청
  Future<String> generateImage(dynamic image, String modelId) async {
    try {
      _logDebug('🎨 Generating image with model ID: $modelId');
      
      String imageUrl;
      
      // 이미지가 File, Uint8List 또는 String 형식인지 확인
      if (image is File || image is Uint8List) {
        imageUrl = await uploadUserImage(image);
      } else if (image is String) {
        // 이미 URL인 경우 그대로 사용
        imageUrl = image;
      } else {
        throw Exception('Unsupported image type');
      }
      
      _logDebug('🖼️ Using image URL: $imageUrl');
      
      // Edge Function에 생성 요청
      final url = '$_functionsUrl/generate';
      _logDebug('🌐 Request URL: $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'image_url': imageUrl,
          'model_id': modelId,
          'user_id': _supabaseClient.auth.currentUser?.id,
        }),
      );
      
      _logDebug('✅ Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final taskId = jsonResponse['task_id'];
        _logDebug('🆔 Task ID: $taskId');
        return taskId;
      } else {
        _logDebug('❌ Error generating image: ${response.body}');
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      _logDebug('❌ Exception in generateImage: $e');
      throw Exception('Failed to generate image: $e');
    }
  }
  
  // 생성된 이미지 결과 조회
  Future<GeneratedImage> getGeneratedImage(String taskId) async {
    try {
      _logDebug('🔍 Checking result for task ID: $taskId');
      
      // Edge Function에 결과 조회 요청
      final url = '$_functionsUrl/check-result';
      _logDebug('🌐 Request URL: $url');
      
      bool isCompleted = false;
      GeneratedImage? result;
      int attempts = 0;
      const maxAttempts = 30; // 최대 30회 시도 (5초 간격으로 약 2.5분)
      
      while (!isCompleted && attempts < maxAttempts) {
        attempts++;
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
          },
          body: jsonEncode({
            'task_id': taskId,
          }),
        );
        
        _logDebug('✅ Response status: ${response.statusCode}, Attempt: $attempts');
        
        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          
          if (jsonResponse['status'] == 'completed') {
            _logDebug('✅ Generation completed!');
            isCompleted = true;
            result = GeneratedImage.fromJson(jsonResponse['result']);
          } else {
            _logDebug('⏳ Generation in progress (${jsonResponse['status']})...');
            await Future.delayed(const Duration(seconds: 5)); // 5초 대기 후 재시도
          }
        } else {
          _logDebug('❌ Error checking result: ${response.body}');
          await Future.delayed(const Duration(seconds: 5)); // 에러 시에도 대기 후 재시도
        }
      }
      
      if (result != null) {
        return result;
      } else {
        throw Exception('Image generation timed out');
      }
    } catch (e) {
      _logDebug('❌ Exception in getGeneratedImage: $e');
      throw Exception('Failed to get generated image: $e');
    }
  }
  
  // Getter for categories
  List<HanbokCategory> get categories => _categories;

  // 인기순으로 한복 모델 가져오기
  Future<List<HanbokModel>> getPopularHanbokModels({int limit = 10}) async {
    try {
      final url = Uri.parse('$_functionsUrl/get-popular-models?limit=$limit');
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => HanbokModel.fromJson(json)).toList();
      } else {
        logger.e('인기 한복 모델 가져오기 실패: ${response.statusCode} - ${response.body}');
        throw Exception('인기 한복 모델 데이터를 가져오는데 실패했습니다.');
      }
    } catch (e) {
      logger.e('인기 한복 모델 가져오기 오류: $e');
      throw Exception('인기 한복 모델 데이터 로드 중 오류가 발생했습니다.');
    }
  }

  // 조회수 증가 메서드
  Future<void> incrementViewCount(String hanbokId) async {
    try {
      final url = Uri.parse('$_functionsUrl/increment-view-count');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_supabaseClient.auth.currentSession?.accessToken}',
        },
        body: jsonEncode({
          'hanbok_id': hanbokId,
        }),
      );
      
      if (response.statusCode != 204) {
        logger.e('조회수 증가 실패: ${response.statusCode} - ${response.body}');
        throw Exception('조회수 증가에 실패했습니다.');
      }
    } catch (e) {
      logger.e('조회수 증가 오류: $e');
      // 조회수 증가 실패는 사용자 경험에 큰 영향을 주지 않으므로 예외를 다시 던지지 않음
    }
  }
} 