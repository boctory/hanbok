// 생성된 이미지 모델
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