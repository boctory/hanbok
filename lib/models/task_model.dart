class TaskModel {
  final String id;
  final String sourceUrl;
  final String presetUrl;
  final String? resultUrl;
  final String status;
  final DateTime createdAt;

  TaskModel({
    required this.id,
    required this.sourceUrl,
    required this.presetUrl,
    this.resultUrl,
    required this.status,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      sourceUrl: json['source_url'] as String,
      presetUrl: json['preset_url'] as String,
      resultUrl: json['result_url'] as String?,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'source_url': sourceUrl,
      'preset_url': presetUrl,
      'result_url': resultUrl,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
} 