import 'package:mvp_2/models/category.dart' as category;
import 'package:mvp_2/models/hanbok_model.dart';
import 'package:mvp_2/models/generated_image.dart' as gen_image;

class MockData {
  static final List<category.HanbokCategory> categories = [
    category.HanbokCategory(
      id: 1,
      name: '전통 한복',
      slug: 'traditional',
      description: '전통적인 스타일의 한복 모델',
    ),
    category.HanbokCategory(
      id: 2,
      name: '모던 한복',
      slug: 'modern',
      description: '현대적으로 재해석된 스타일의 한복 모델',
    ),
  ];

  static final List<HanbokModel> hanbokModels = [
    // 전통 한복 모델
    HanbokModel(
      id: 1,
      name: '청자색 저고리와 분홍 치마',
      description: '전통 스타일의 여성 한복',
      imageUrl: 'https://i.imgur.com/1fjx25G.jpeg',
      categoryId: 1,
      gender: '여성',
      style: 'traditional',
      popularityScore: 95,
    ),
    HanbokModel(
      id: 2,
      name: '홍색 두루마기',
      description: '전통 스타일의 남성 한복',
      imageUrl: 'https://i.imgur.com/zqLDQva.jpeg',
      categoryId: 1,
      gender: '남성',
      style: 'traditional',
      popularityScore: 88,
    ),
    HanbokModel(
      id: 3,
      name: '연두색 저고리와 자주색 치마',
      description: '전통 스타일의 여성 한복',
      imageUrl: 'https://i.imgur.com/Ug5YFti.jpeg',
      categoryId: 1,
      gender: '여성',
      style: 'traditional',
      popularityScore: 92,
    ),
    HanbokModel(
      id: 4,
      name: '남색 도포',
      description: '전통 스타일의 남성 한복',
      imageUrl: 'https://i.imgur.com/trgQK0d.jpeg',
      categoryId: 1,
      gender: '남성',
      style: 'traditional',
      popularityScore: 82,
    ),

    // 모던 한복 모델
    HanbokModel(
      id: 5,
      name: '모던 퓨전 원피스형 한복',
      description: '현대적으로 재해석된 여성 한복',
      imageUrl: 'https://i.imgur.com/VaTQoTF.jpeg',
      categoryId: 2,
      gender: '여성',
      style: 'modern',
      popularityScore: 97,
    ),
    HanbokModel(
      id: 6,
      name: '생활한복 남성 세트',
      description: '일상에서 입을 수 있는 남성 생활한복',
      imageUrl: 'https://i.imgur.com/M9HkJAx.jpeg',
      categoryId: 2,
      gender: '남성',
      style: 'modern',
      popularityScore: 85,
    ),
    HanbokModel(
      id: 7,
      name: '모던 숏 저고리와 치마',
      description: '현대적 감각의 여성 한복',
      imageUrl: 'https://i.imgur.com/1rp0xeu.jpeg',
      categoryId: 2,
      gender: '여성',
      style: 'modern',
      popularityScore: 94,
    ),
    HanbokModel(
      id: 8,
      name: '캐주얼 남성 생활한복',
      description: '캐주얼한 스타일의 남성 한복',
      imageUrl: 'https://i.imgur.com/xjM9Eos.jpeg',
      categoryId: 2,
      gender: '남성',
      style: 'modern',
      popularityScore: 89,
    ),
  ];

  static final List<gen_image.GeneratedImage> generatedImages = [
    gen_image.GeneratedImage(
      id: '1',
      userId: 'user123',
      sourceImageUrl: 'https://i.imgur.com/USER_PHOTO1.jpg',
      presetImageUrl: 'https://i.imgur.com/1fjx25G.jpeg',
      resultImageUrl: 'https://i.imgur.com/RESULT_IMAGE1.jpg',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2, hours: 1)),
    ),
    gen_image.GeneratedImage(
      id: '2',
      userId: 'user123',
      sourceImageUrl: 'https://i.imgur.com/USER_PHOTO2.jpg',
      presetImageUrl: 'https://i.imgur.com/VaTQoTF.jpeg',
      resultImageUrl: 'https://i.imgur.com/RESULT_IMAGE2.jpg',
      status: 'completed',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1, hours: 1)),
    ),
    gen_image.GeneratedImage(
      id: '3',
      userId: 'user123',
      sourceImageUrl: 'https://i.imgur.com/USER_PHOTO3.jpg',
      presetImageUrl: 'https://i.imgur.com/zqLDQva.jpeg',
      status: 'processing',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // 카테고리별 한복 모델 가져오기
  static List<HanbokModel> getHanbokModelsByCategory(String categorySlug) {
    if (categorySlug.isEmpty) {
      return hanbokModels;
    }
    return hanbokModels.where((model) => 
      categories.firstWhere((cat) => cat.id == model.categoryId).slug == categorySlug
    ).toList();
  }

  // ID로 한복 모델 찾기
  static HanbokModel? getHanbokModelById(int id) {
    try {
      return hanbokModels.firstWhere((model) => model.id == id);
    } catch (e) {
      return null;
    }
  }

  // 사용자의 생성된 이미지 가져오기
  static List<gen_image.GeneratedImage> getUserGeneratedImages(String userId) {
    return generatedImages.where((image) => image.userId == userId).toList();
  }
} 