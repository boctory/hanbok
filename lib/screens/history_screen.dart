import 'package:flutter/material.dart';
import 'package:mvp_2/data/mock_data.dart';
import 'package:mvp_2/models/generated_image.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GeneratedImage> _generatedImages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGeneratedImages();
  }

  void _loadGeneratedImages() {
    // 데이터 로딩 지연 효과
    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        // 모의 데이터 사용
        _generatedImages = MockData.getUserGeneratedImages('user123')
            .map((img) => GeneratedImage(
                id: img.id,
                userId: img.userId,
                sourceImageUrl: img.sourceImageUrl,
                presetImageUrl: img.presetImageUrl,
                resultImageUrl: img.resultImageUrl,
                status: img.status,
                createdAt: img.createdAt,
                updatedAt: img.updatedAt))
            .toList();
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('나의 한복 기록'),
        actions: [
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              // 홈 화면으로 이동
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _generatedImages.isEmpty
              ? _buildEmptyState()
              : _buildGeneratedImagesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            '생성된 한복 이미지가 없습니다',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            '한복을 선택하고 내 모습을 생성해보세요!',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/',
                (route) => false,
              );
            },
            icon: Icon(Icons.add_photo_alternate),
            label: Text('한복 입어보기'),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedImagesList() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _generatedImages.length,
      itemBuilder: (context, index) {
        final image = _generatedImages[index];
        return _buildHistoryItem(image, index);
      },
    );
  }

  Widget _buildHistoryItem(GeneratedImage image, int index) {
    // 날짜 포맷팅
    final formattedDate = DateFormat('yyyy년 MM월 dd일 HH:mm').format(image.createdAt);
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 상태 배지
          Container(
            padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: _getStatusColor(image.status),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getStatusText(image.status),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // 이미지 섹션
          Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // 한복 이미지
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 3/4,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        image.presetImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: Icon(Icons.error, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                
                // 결과 이미지
                Expanded(
                  child: AspectRatio(
                    aspectRatio: 3/4,
                    child: image.resultImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              image.resultImageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(Icons.error, color: Colors.red),
                                );
                              },
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 32,
                                    height: 32,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.grey[400]!,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    '처리 중...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          
          // 버튼 섹션
          Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: image.status == 'completed'
                      ? () {
                          // 이미지 보기 또는 공유
                        }
                      : null,
                  icon: Icon(Icons.share, size: 18),
                  label: Text('공유'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // 항목 삭제 기능
                    _showDeleteConfirmation(index);
                  },
                  icon: Icon(Icons.delete_outline, size: 18),
                  label: Text('삭제'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return '완료';
      case 'processing':
        return '처리 중';
      case 'failed':
        return '실패';
      default:
        return '대기 중';
    }
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('기록 삭제'),
        content: Text('이 한복 생성 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('취소'),
          ),
          TextButton(
            onPressed: () {
              // 항목 삭제 후 다이얼로그 닫기
              setState(() {
                _generatedImages.removeAt(index);
              });
              Navigator.pop(context);
            },
            child: Text('삭제'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
} 