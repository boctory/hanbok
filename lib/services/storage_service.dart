import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hanbok_app/models/generated_image.dart';

class StorageService {
  static const String _galleryKey = 'user_gallery';
  
  // Save a generated image to local storage
  Future<void> saveGeneratedImage(GeneratedImage image) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing gallery
      final List<GeneratedImage> gallery = await getGallery();
      
      // Add new image
      gallery.add(image);
      
      // Convert to JSON and save
      final List<String> jsonList = gallery.map((img) => jsonEncode(img.toJson())).toList();
      await prefs.setStringList(_galleryKey, jsonList);
    } catch (e) {
      print('Error saving generated image: $e');
    }
  }
  
  // Get all generated images from local storage
  Future<List<GeneratedImage>> getGallery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get saved gallery
      final List<String>? jsonList = prefs.getStringList(_galleryKey);
      
      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }
      
      // Convert from JSON
      return jsonList.map((jsonString) {
        final Map<String, dynamic> json = jsonDecode(jsonString);
        return GeneratedImage.fromJson(json);
      }).toList();
    } catch (e) {
      print('Error getting gallery: $e');
      return [];
    }
  }
  
  // Delete a generated image from local storage
  Future<void> deleteGeneratedImage(String imageId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing gallery
      final List<GeneratedImage> gallery = await getGallery();
      
      // Remove image with matching ID
      gallery.removeWhere((img) => img.id == imageId);
      
      // Convert to JSON and save
      final List<String> jsonList = gallery.map((img) => jsonEncode(img.toJson())).toList();
      await prefs.setStringList(_galleryKey, jsonList);
    } catch (e) {
      print('Error deleting generated image: $e');
    }
  }
  
  // Clear all generated images from local storage
  Future<void> clearGallery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_galleryKey);
    } catch (e) {
      print('Error clearing gallery: $e');
    }
  }
} 