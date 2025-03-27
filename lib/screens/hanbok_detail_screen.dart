import 'package:flutter/material.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/utils/logger.dart';

class HanbokDetailScreen extends StatefulWidget {
  final HanbokModel hanbokModel;

  const HanbokDetailScreen({
    Key? key,
    required this.hanbokModel,
  }) : super(key: key);

  @override
  _HanbokDetailScreenState createState() => _HanbokDetailScreenState();
}

class _HanbokDetailScreenState extends State<HanbokDetailScreen> {
  @override
  void initState() {
    super.initState();
    // 조회수 증가 로직을 여기에 추가할 수 있습니다.
    logger.d('한복 모델 상세 화면: ${widget.hanbokModel.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hanbokModel.name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 이미지 표시
            Hero(
              tag: 'hanbok_${widget.hanbokModel.id}',
              child: Container(
                height: 400,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(widget.hanbokModel.imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            
            // 한복 정보
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 카테고리 및 스타일 정보
                  Row(
                    children: [
                      _buildInfoChip(
                        widget.hanbokModel.categoryName ?? '카테고리 없음',
                        Icons.category,
                      ),
                      const SizedBox(width: 8),
                      if (widget.hanbokModel.style != null)
                        _buildInfoChip(
                          widget.hanbokModel.style!,
                          Icons.style,
                        ),
                      const SizedBox(width: 8),
                      if (widget.hanbokModel.gender != null)
                        _buildInfoChip(
                          widget.hanbokModel.gender!,
                          Icons.person,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 한복 이름
                  Text(
                    widget.hanbokModel.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // 인기도 표시
                  Row(
                    children: [
                      Icon(
                        Icons.favorite,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '인기도: ${widget.hanbokModel.popularityScore}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.visibility,
                        color: Colors.blue,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '조회수: ${widget.hanbokModel.viewCount}',
                        style: TextStyle(
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 설명
                  Text(
                    '설명',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hanbokModel.description ?? '설명이 없습니다.',
                    style: TextStyle(
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // 버튼들
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // 가상 착용 기능 구현
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('가상 착용 기능은 준비 중입니다.')),
                            );
                          },
                          icon: Icon(Icons.photo_camera),
                          label: Text('가상 착용'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // 즐겨찾기 기능 구현
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('즐겨찾기에 추가되었습니다.')),
                            );
                          },
                          icon: Icon(Icons.favorite_border),
                          label: Text('즐겨찾기'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.grey[800],
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }
} 