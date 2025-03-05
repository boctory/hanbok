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
      id: json['id'],
      name: json['name'],
      imageUrl: json['image_url'],
      description: json['description'],
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