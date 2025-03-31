import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'env_service.dart';
import 'supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InferenceService {
  static final InferenceService _instance = InferenceService._internal();
  factory InferenceService() => _instance;
  InferenceService._internal();
  
  final EnvService _envService = EnvService();
  final SupabaseService _supabaseService = SupabaseService();
  
  // Task IDs from submitted requests
  final List<String> _taskIds = [];
  List<String> get taskIds => _taskIds;
  
  // Map of task IDs to their result URLs
  final Map<String, String> _resultUrls = {};
  Map<String, String> get resultUrls => _resultUrls;
  
  // Generate Hanbok image by sending a request to our Edge Function
  Future<String?> generateHanbokFitting({
    required String sourcePath, 
    required String targetPath,
    String? webhookUrl,
  }) async {
    try {
      // Get auth token
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        throw Exception('Authentication token required for image generation');
      }
      
      // Edge function endpoint
      final String apiUrl = '${_envService.getOrDefault('supabase-url', 'https://awxineofxcvdpsxlvtxv.supabase.co')}/functions/v1/generate-hanbok-image';
      
      debugPrint('Calling edge function: $apiUrl');
      debugPrint('Source Path: $sourcePath');
      debugPrint('Target Path: $targetPath');
      
      final Map<String, dynamic> requestBody = {
        'sourceImageUrl': sourcePath,
        'targetImageUrl': targetPath,
      };
      
      debugPrint('Request Body: ${jsonEncode(requestBody)}');
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      debugPrint('Response Status: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        
        // If we got a cached result, return it immediately
        if (data['cached'] == true && data['image_url'] != null) {
          debugPrint('Cached result found: ${data['image_url']}');
          return data['image_url'];
        }
        
        // Store the task ID for polling
        final String taskId = data['task_id'];
        
        // Add task ID to list, limited to 5 most recent
        _taskIds.add(taskId);
        if (_taskIds.length > 5) {
          _taskIds.removeAt(0); // Remove oldest task
        }
        
        debugPrint('Task submitted with ID: $taskId');
        debugPrint('Current task IDs: $_taskIds');
        
        // Start polling for the result
        // We return null here, and the UI should handle polling for the result
        // using the check-status endpoint
        return null;
      } else {
        debugPrint('Image generation request failed: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to submit image generation request');
      }
    } catch (e) {
      debugPrint('Error during image generation request: $e');
      rethrow;
    }
  }
  
  // Check status of a task
  Future<Map<String, dynamic>> checkTaskStatus(String taskId) async {
    try {
      // Get auth token
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null) {
        debugPrint('No auth token available for status check');
        throw Exception('Authentication token required for status check');
      }
      
      // Edge function endpoint
      final String apiUrl = '${_envService.getOrDefault('supabase-url', 'https://awxineofxcvdpsxlvtxv.supabase.co')}/functions/v1/check-status?task_id=$taskId';
      
      debugPrint('Checking status for task: $taskId');
      debugPrint('API URL: $apiUrl');
      
      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      debugPrint('Status check response code: ${response.statusCode}');
      debugPrint('Status check response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        debugPrint('Parsed response data: $data');
        
        // If completed, store the result URL
        if (data['status'] == 'completed' && data['image_url'] != null) {
          // Use the image URL directly without modification
          final imageUrl = data['image_url'];          
          debugPrint('Task completed with image URL: $imageUrl');
          _resultUrls[taskId] = imageUrl;
        } else {
          debugPrint('Task not completed yet. Status: ${data['status']}');
        }
        
        return data;
      } else {
        debugPrint('Status check failed: ${response.statusCode}, ${response.body}');
        return {
          'status': 'error',
          'error': 'Failed to check task status: ${response.statusCode}',
          'error_message': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error checking task status: $e');
      return {
        'status': 'error',
        'error': 'Error checking task status: $e',
        'error_message': e.toString(),
      };
    }
  }
  
  // Get result for a specific task ID if available
  String? getResultForTask(String taskId) {
    return _resultUrls[taskId];
  }
  
  // Clear task history
  void clearTasks() {
    _taskIds.clear();
    _resultUrls.clear();
  }
} 