import 'package:flutter/material.dart';
import 'package:mvp_2/constants/app_constants.dart';
import 'package:mvp_2/data/mock_data.dart';
import 'package:mvp_2/models/category.dart' as category_model;
import 'package:mvp_2/models/hanbok_model.dart';

class IndexScreen extends StatefulWidget {
  const IndexScreen({Key? key}) : super(key: key);

  @override
  _IndexScreenState createState() => _IndexScreenState();
}

class _IndexScreenState extends State<IndexScreen> {
  List<HanbokModel> _hanbokModels = [];
  List<category_model.HanbokCategory> _categories = [];
  String _selectedCategorySlug = '';
  bool _isLoadingModels = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadHanbokModels();
  }

  void _loadCategories() {
    // 모의 데이터 사용
    setState(() {
      _categories = MockData.categories.cast<category_model.HanbokCategory>();
    });
  }

  void _loadHanbokModels() {
    // 데이터 로딩 지연 효과 추가
    setState(() {
      _isLoadingModels = true;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _hanbokModels = MockData.getHanbokModelsByCategory(_selectedCategorySlug);
        _isLoadingModels = false;
      });
    });
  }

  void _selectCategory(String slug) {
    if (slug == _selectedCategorySlug) return;
    
    setState(() {
      _selectedCategorySlug = slug;
    });
    
    _loadHanbokModels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppConstants.appName),
        actions: [
          IconButton(
            icon: Icon(Icons.history),
            onPressed: () {
              Navigator.pushNamed(context, '/history');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 카테고리 선택 영역
            _buildCategorySection(),
            
            // 한복 모델 그리드 뷰
            Expanded(
              child: _isLoadingModels
                  ? Center(child: CircularProgressIndicator())
                  : _buildHanbokGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 타이틀 섹션
          Text(
            '한복 스타일',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '마음에 드는 한복 스타일을 선택해보세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 16),
          
          // 카테고리 칩 목록
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 전체 카테고리 옵션
                _buildCategoryChip('', '전체'),
                SizedBox(width: 8),
                
                // 동적 카테고리 칩
                ..._categories.map((category) => Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(category.slug, category.name),
                )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String slug, String name) {
    final isSelected = slug == _selectedCategorySlug;
    
    return ChoiceChip(
      label: Text(name),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _selectCategory(slug);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Colors.indigo[400]?.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.indigo[400] : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildHanbokGrid() {
    if (_hanbokModels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              '해당 카테고리에 한복이 없습니다',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.0),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
      ),
      itemCount: _hanbokModels.length,
      itemBuilder: (context, index) {
        final model = _hanbokModels[index];
        return _buildHanbokModelCard(model);
      },
    );
  }

  Widget _buildHanbokModelCard(HanbokModel model) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/detail',
          arguments: model.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 한복 이미지
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    model.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: Icon(Icons.error, color: Colors.red),
                      );
                    },
                  ),
                  // 인기도 뱃지
                  if (model.popularityScore >= 90)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber[400],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 14,
                              color: Colors.white,
                            ),
                            SizedBox(width: 2),
                            Text(
                              '인기',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // 한복 정보
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        model.gender,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            size: 14,
                            color: Colors.red[400],
                          ),
                          SizedBox(width: 2),
                          Text(
                            '${model.popularityScore}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
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
} 