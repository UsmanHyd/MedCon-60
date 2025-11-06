import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class ChatbotService {
  // Use the API config for chatbot server
  static String get baseUrl => ApiConfig.chatbotServer;

  /// Send a message to the chatbot API and get response
  static Future<ChatbotResponse> sendMessage(String message) async {
    try {
      print('🌐 Sending request to: $baseUrl/get');
      print('📝 Message: $message');

      // First test if server is reachable
      print('🏥 Testing server health first...');
      final healthResponse = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print(
          '🏥 Health check result: ${healthResponse.statusCode} - ${healthResponse.body}');

      if (healthResponse.statusCode != 200) {
        return ChatbotResponse(
          answer: '',
          status: 'error',
          error: 'Server health check failed: ${healthResponse.statusCode}',
        );
      }

      final response = await http
          .post(
        Uri.parse('$baseUrl/get'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'msg': message,
        }),
      )
          .timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📡 Response status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ChatbotResponse(
          answer: data['answer'] ?? 'No response received',
          status: data['status'] ?? 'success',
          error: null,
        );
      } else {
        final data = jsonDecode(response.body);
        return ChatbotResponse(
          answer: '',
          status: 'error',
          error:
              data['error'] ?? 'Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Connection error: $e');
      return ChatbotResponse(
        answer: '',
        status: 'error',
        error: 'Failed to connect to chatbot server: ${e.toString()}',
      );
    }
  }

  /// Check if the chatbot server is healthy
  static Future<bool> checkServerHealth() async {
    try {
      print('🏥 Checking server health at: $baseUrl/health');
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Health check timeout after 10 seconds');
        },
      );
      print('🏥 Health check status: ${response.statusCode}');
      print('🏥 Health check response: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ Health check failed: $e');
      return false;
    }
  }
}

class ChatbotResponse {
  final String answer;
  final String status;
  final String? error;

  ChatbotResponse({
    required this.answer,
    required this.status,
    this.error,
  });

  bool get isSuccess => status == 'success';
  bool get hasError => status == 'error';
}
