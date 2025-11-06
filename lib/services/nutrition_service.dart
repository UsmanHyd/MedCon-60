import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class NutritionService {
  // Use the API config for nutrition server
  static String get baseUrl => ApiConfig.nutritionServer;
  
  // Timeout for Gemini API calls (can take 60-120 seconds)
  static const Duration requestTimeout = Duration(seconds: 120);
  static const Duration healthCheckTimeout = Duration(seconds: 10);

  /// Generate a weekly nutrition and fitness plan
  static Future<Map<String, dynamic>> generateWeeklyPlan(
      Map<String, dynamic> userData) async {
    final url = '$baseUrl/generate-plan';
    print('🌐 Attempting to connect to: $url');
    
    // First check if server is reachable
    try {
      final isHealthy = await checkHealth();
      if (!isHealthy) {
        throw Exception('Server is not reachable. Please make sure the fitness server is running on port 5000');
      }
    } catch (e) {
      print('⚠️ Health check failed: $e');
      // Continue anyway, might be a temporary issue
    }

    int retryCount = 0;
    const maxRetries = 2;
    
    while (retryCount <= maxRetries) {
      try {
        print('🔄 Attempt ${retryCount + 1} of ${maxRetries + 1}...');
        
        final response = await http.post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: json.encode(userData),
        ).timeout(
          requestTimeout,
          onTimeout: () {
            throw Exception('Request timeout after ${requestTimeout.inSeconds} seconds. Gemini API might be slow. Please try again.');
          },
        );

        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('✅ Plan generated successfully');
          return data;
        } else {
          print('❌ Server error: ${response.statusCode} - ${response.body}');
          throw Exception('Failed to generate plan: ${response.statusCode}');
        }
      } catch (e) {
        retryCount++;
        print('❌ Connection error (attempt $retryCount): $e');
        
        if (retryCount > maxRetries) {
          // Final failure
          if (e.toString().contains('timeout') || e.toString().contains('Connection timed out')) {
            throw Exception('Connection timeout. The Gemini API is taking too long to respond. Please check:\n1. Your internet connection\n2. Gemini API key is valid\n3. Server is running on $url\n\nTry again in a few moments.');
          } else if (e.toString().contains('SocketException') || e.toString().contains('Connection refused')) {
            throw Exception('Cannot connect to server. Please make sure:\n1. Fitness server is running (python fitness.py)\n2. Server is on the correct IP: $baseUrl\n3. Firewall is not blocking the connection');
          } else {
            throw Exception('Error generating plan: $e');
          }
        }
        
        // Wait before retrying
        if (retryCount <= maxRetries) {
          print('⏳ Waiting 3 seconds before retry...');
          await Future.delayed(const Duration(seconds: 3));
        }
      }
    }
    
    throw Exception('Failed to generate plan after $maxRetries retries');
  }

  /// Check if the API is healthy
  static Future<bool> checkHealth() async {
    try {
      final url = '$baseUrl/health';
      print('🔍 Checking health at: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        healthCheckTimeout,
        onTimeout: () {
          print('⏱️ Health check timeout');
          throw Exception('Health check timeout');
        },
      );

      print('💚 Health check response: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('💔 Health check failed: $e');
      return false;
    }
  }
}
