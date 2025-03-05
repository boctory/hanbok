import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  // Pick image from gallery
  static Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }
  
  // Pick image from gallery for web
  static Future<Uint8List?> pickImageFromGalleryWeb() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery (web): $e');
      return null;
    }
  }
  
  // Take photo with camera
  static Future<File?> takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }
  
  // Take photo with camera for web
  static Future<Uint8List?> takePhotoWeb() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return await pickedFile.readAsBytes();
      }
      return null;
    } catch (e) {
      print('Error taking photo (web): $e');
      return null;
    }
  }
  
  // Save image to gallery
  static Future<bool> saveImageToGallery(String imageUrl) async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        return false;
      }
      
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/hanbok_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Save to temporary file
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);
      
      // Save to gallery
      final result = await GallerySaver.saveImage(file.path);
      return result ?? false;
    } catch (e) {
      print('Error saving image to gallery: $e');
      return false;
    }
  }
  
  // Share image
  static Future<void> shareImage(String imageUrl) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/hanbok_share_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Save to temporary file
      final file = File(tempPath);
      await file.writeAsBytes(response.bodyBytes);
      
      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '한복 AI로 만든 나의 한복 이미지를 확인해보세요!',
      );
    } catch (e) {
      print('Error sharing image: $e');
    }
  }
} 