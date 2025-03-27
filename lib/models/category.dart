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