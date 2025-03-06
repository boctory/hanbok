class HanbokModel {
  final String id;
  final String name;
  final String imageUrl;
  final String description;

  HanbokModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.description,
  });

  factory HanbokModel.fromJson(Map<String, dynamic> json) {
    return HanbokModel(
      id: json['id']?.toString() ?? 'unknown_id', // null이면 기본값
      name: json['name']?.toString() ?? 'Unnamed Hanbok', // null이면 기본값
      imageUrl: json['imageUrl']?.toString() ?? '', // null이면 빈 문자열
      description: json['description']?.toString() ?? '설명 없는 한복입니다.', // null이면 기본값
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'description': description,
    };
  }
}