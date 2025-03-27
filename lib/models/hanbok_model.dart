import 'package:flutter/foundation.dart';

// 한복 모델
class HanbokModel {
  final int id;
  final String name;
  final String description;
  final String imageUrl;
  final int categoryId;
  final String gender;
  final String style;
  final bool isActive;
  final int viewCount;
  final int popularityScore;

  HanbokModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.categoryId,
    required this.gender,
    required this.style,
    this.isActive = true,
    this.viewCount = 0,
    this.popularityScore = 0,
  });

  factory HanbokModel.fromJson(Map<String, dynamic> json) {
    return HanbokModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
      categoryId: json['category_id'] ?? 0,
      gender: json['gender'] ?? '',
      style: json['style'] ?? '',
      isActive: json['is_active'] ?? true,
      viewCount: json['view_count'] ?? 0,
      popularityScore: json['popularity_score'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'category_id': categoryId,
      'gender': gender,
      'style': style,
      'is_active': isActive,
      'view_count': viewCount,
      'popularity_score': popularityScore,
    };
  }
}

class HanbokCategory {
  final int id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;

  HanbokCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    this.isActive = true,
  });

  factory HanbokCategory.fromJson(Map<String, dynamic> json) {
    return HanbokCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
      description: json['description'] ?? '',
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'is_active': isActive,
    };
  }
}

class GeneratedImage {
  final String id;
  final String userId;
  final String sourceImageUrl;
  final String presetImageUrl;
  final String? resultImageUrl;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  GeneratedImage({
    required this.id,
    required this.userId,
    required this.sourceImageUrl,
    required this.presetImageUrl,
    this.resultImageUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      sourceImageUrl: json['source_image_url'] ?? '',
      presetImageUrl: json['preset_image_url'] ?? '',
      resultImageUrl: json['result_image_url'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null 
        ? DateTime.parse(json['created_at']) 
        : DateTime.now(),
      updatedAt: json['updated_at'] != null 
        ? DateTime.parse(json['updated_at']) 
        : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'source_image_url': sourceImageUrl,
      'preset_image_url': presetImageUrl,
      'result_image_url': resultImageUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}