import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/models/generated_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  late final Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: dotenv.env['API_BASE_URL'] ?? '',
      headers: {
        'Authorization': 'Bearer ${dotenv.env['API_KEY']}',
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors for logging, error handling, etc.
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        print('REQUEST[${options.method}] => PATH: ${options.path}');
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        print('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
        return handler.next(e);
      },
    ));
  }
  
  // Get available Hanbok models
  Future<List<HanbokModel>> getHanbokModels() async {
    try {
      final response = await _dio.get(dotenv.env['HANBOK_MODELS_ENDPOINT'] ?? '/hanbok-models');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['models'];
        return data.map((model) => HanbokModel.fromJson(model)).toList();
      } else {
        throw Exception('Failed to load Hanbok models');
      }
    } catch (e) {
      print('Error fetching Hanbok models: $e');
      // Return some mock data for now
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
        HanbokModel(
          id: 'style4',
          name: '현대적 한복 (남성)',
          imageUrl: 'assets/images/sample/sample4.png',
          description: '현대적인 스타일의 남성용 한복 모델입니다.',
        ),
      ];
    }
  }
  
  // Generate AI image with user photo and selected Hanbok model
  Future<GeneratedImage> generateImage(dynamic userPhoto, String hanbokModelId) async {
    try {
      // Create form data
      FormData formData;
      
      if (kIsWeb && userPhoto is Uint8List) {
        // 웹 환경에서는 Uint8List를 사용
        formData = FormData.fromMap({
          'user_photo': MultipartFile.fromBytes(
            userPhoto,
            filename: 'user_photo.jpg',
          ),
          'hanbok_style': hanbokModelId, // 선택한 한복 스타일 ID
          'background': 'natural', // 배경 설정
        });
      } else if (userPhoto is File) {
        // 모바일 환경에서는 File을 사용
        formData = FormData.fromMap({
          'user_photo': await MultipartFile.fromFile(userPhoto.path),
          'hanbok_style': hanbokModelId, // 선택한 한복 스타일 ID
          'background': 'natural', // 배경 설정
        });
      } else {
        throw Exception('Invalid user photo format');
      }
      
      final response = await _dio.post(
        dotenv.env['GENERATE_IMAGE_ENDPOINT'] ?? '/generate-image',
        data: formData,
      );
      
      if (response.statusCode == 200) {
        return GeneratedImage.fromJson(response.data);
      } else {
        throw Exception('Failed to generate image');
      }
    } catch (e) {
      print('Error generating image: $e');
      // Return mock data for now - 실제 API 연동 전까지 테스트용 이미지 반환
      return GeneratedImage(
        id: 'mock-id-${DateTime.now().millisecondsSinceEpoch}',
        imageUrl: 'https://picsum.photos/400/600', // 랜덤 이미지로 대체
        createdAt: DateTime.now(),
        hanbokModelId: hanbokModelId,
      );
    }
  }
  
  // Get user's gallery of generated images
  Future<List<GeneratedImage>> getUserGallery() async {
    try {
      final response = await _dio.get(dotenv.env['USER_GALLERY_ENDPOINT'] ?? '/user-gallery');
      
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data['images'];
        return data.map((image) => GeneratedImage.fromJson(image)).toList();
      } else {
        throw Exception('Failed to load user gallery');
      }
    } catch (e) {
      print('Error fetching user gallery: $e');
      // Return mock data for now
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
} 