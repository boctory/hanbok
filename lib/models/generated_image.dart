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
      id: json['id'] as String,
      imageUrl: json['imageUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      hanbokModelId: json['hanbokModelId'] as String? ?? '',
    );
  }

  // toJson 메서드 추가
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'hanbokModelId': hanbokModelId,
    };
  }
}