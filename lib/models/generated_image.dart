class GeneratedImage {
  final String id;
  final String imageUrl;
  final DateTime createdAt;
  final String hanbokModelId;

  GeneratedImage({
    required this.id,
    required this.imageUrl,
    required this.createdAt,
    required this.hanbokModelId,
  });

  factory GeneratedImage.fromJson(Map<String, dynamic> json) {
    return GeneratedImage(
      id: json['id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      hanbokModelId: json['hanbok_model_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'hanbok_model_id': hanbokModelId,
    };
  }
} 