import 'package:flutter/material.dart';
import 'package:mvp_2/data/mock_data.dart';
import 'package:mvp_2/models/hanbok_model.dart';
import 'package:mvp_2/screens/generate_screen.dart';

class DetailScreen extends StatefulWidget {
  final int modelId;
  
  const DetailScreen({Key? key, required this.modelId}) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  HanbokModel? _model;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHanbokModel();
  }

  void _loadHanbokModel() {
    // 데모 용도로 지연 효과 추가
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _model = MockData.getHanbokModelById(widget.modelId);
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoading ? '한복 상세 정보' : _model?.name ?? '한복 정보 없음'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _model == null
              ? _buildErrorWidget()
              : _buildDetailContent(),
      bottomNavigationBar: _isLoading || _model == null
          ? null
          : _buildBottomButton(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          SizedBox(height: 16),
          Text(
            '한복 정보를 찾을 수 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('돌아가기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    final model = _model!;
    final category = MockData.categories.firstWhere(
      (cat) => cat.id == model.categoryId,
      orElse: () => MockData.categories.first,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 헤더 이미지
          AspectRatio(
            aspectRatio: 3 / 4,
            child: Image.network(
              model.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: Icon(Icons.error, color: Colors.red),
                  ),
                );
              },
            ),
          ),
          
          // 상세 정보
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 카테고리 및 스타일 정보
                Row(
                  children: [
                    Chip(
                      label: Text(category.name),
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text(model.gender),
                      backgroundColor: Colors.grey[200],
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // 한복 이름
                Text(
                  model.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // 인기 점수
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red[400],
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${model.popularityScore}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 16),
                    Icon(
                      Icons.visibility,
                      color: Colors.blue[400],
                      size: 20,
                    ),
                    SizedBox(width: 4),
                    Text(
                      '${model.viewCount}',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 16),
                
                // 설명
                Text(
                  '설명',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  model.description,
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // 안내 텍스트
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가상 한복 생성 안내',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '아래 버튼을 눌러 내 사진에 이 한복을 입혀볼 수 있습니다. 얼굴이 보이는 정면 사진을 사용하면 더 나은 결과를 얻을 수 있습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            // 이미지 생성 화면으로 이동
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GenerateScreen(hanbokModel: _model!),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(
            '이 한복 입어보기',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
} 