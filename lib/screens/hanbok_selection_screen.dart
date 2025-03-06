import 'package:flutter/material.dart';
import 'package:hanbok_app/constants/app_constants.dart';
import 'package:hanbok_app/models/hanbok_model.dart';
import 'package:hanbok_app/screens/image_generation_screen.dart';
import 'package:hanbok_app/services/api_service.dart';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

class HanbokSelectionScreen extends StatefulWidget {
  final File userImage;

  const HanbokSelectionScreen({super.key, required this.userImage});

  @override
  _HanbokSelectionScreenState createState() => _HanbokSelectionScreenState();
}

class _HanbokSelectionScreenState extends State<HanbokSelectionScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<HanbokModel>> _hanbokModelsFuture;
  HanbokModel? _selectedModel;

  @override
  void initState() {
    super.initState();
    _hanbokModelsFuture = _apiService.getHanbokModels().then((models) {
      print('Received models: ${models.length}');
      models.forEach((model) {
        print('Model: ${model.name}, URL: ${model.imageUrl}');
      });
      return models;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          '한복 모델 선택',
          style: TextStyle(
            fontFamily: AppConstants.koreanFontFamily,
            color: AppConstants.textColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppConstants.primaryColor),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // User image preview
          Container(
            height: 200,
            margin: const EdgeInsets.all(AppConstants.paddingMedium),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              child: Image.file(
                widget.userImage,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
            child: Text(
              '아래에서 원하는 한복 모델을 선택하세요',
              style: AppConstants.subheadingStyle,
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Hanbok models grid
          Expanded(
            child: FutureBuilder<List<HanbokModel>>(
              future: _hanbokModelsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return GridView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingMedium),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.75,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: 4,
                    itemBuilder: (context, index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '한복 모델을 불러오는 중 오류가 발생했습니다.',
                      style: AppConstants.bodyStyle,
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      '사용 가능한 한복 모델이 없습니다.',
                      style: AppConstants.bodyStyle,
                    ),
                  );
                }
                
                final models = snapshot.data!;
                
                return GridView.builder(
                  padding: const EdgeInsets.all(AppConstants.paddingMedium),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final isSelected = _selectedModel?.id == model.id;
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedModel = model;
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                          border: Border.all(
                            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium - (isSelected ? 1 : 0)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: CachedNetworkImage(
                                  imageUrl: model.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[200],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[200],
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.error, color: AppConstants.errorColor),
                                        const SizedBox(height: 4),
                                        Text(
                                          '이미지 로드 실패',
                                          style: TextStyle(
                                            color: AppConstants.errorColor,
                                            fontSize: 12,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                                color: Colors.white,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      model.name,
                                      style: TextStyle(
                                        fontFamily: AppConstants.koreanFontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      model.description,
                                      style: TextStyle(
                                        fontFamily: AppConstants.koreanFontFamily,
                                        fontSize: 12,
                                        color: AppConstants.lightTextColor,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // Generate button
          Padding(
            padding: const EdgeInsets.all(AppConstants.paddingMedium),
            child: ElevatedButton(
              onPressed: _selectedModel == null
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageGenerationScreen(
                            userImage: widget.userImage,
                            hanbokModel: _selectedModel!,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Text(
                '이미지 생성하기',
                style: TextStyle(
                  fontFamily: AppConstants.koreanFontFamily,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 