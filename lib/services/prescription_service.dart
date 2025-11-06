import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class PrescriptionService {
  // Use the API config for consultation server
  static String get baseUrl => '${ApiConfig.consultationServer}/api';
  static const int timeoutSeconds = 10; // Increased timeout for reliability

  // Cache for faster responses
  static final Map<String, Map<String, dynamic>> _cache = {};

  // Get drugs for a specific disease
  static Future<Map<String, dynamic>> getDrugsForDisease(String disease) async {
    // Check cache first for instant response
    if (_cache.containsKey(disease)) {
      print('⚡ Cache hit for $disease - instant response!');
      return _cache[disease]!;
    }

    try {
      print('🔍 Trying API URL: $baseUrl/drugs-for-disease');

      final response = await http
          .post(
            Uri.parse('$baseUrl/drugs-for-disease'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'disease': disease, 'threshold': 85}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Cache the result for instant future access
        _cache[disease] = result;
        print('✅ Successfully connected to: $baseUrl');
        return result;
      } else {
        print('❌ Failed with status ${response.statusCode} on $baseUrl');
        throw Exception('API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error with $baseUrl: $e');
      throw Exception('Failed to connect to prescription API: $e');
    }
  }

  // Get all available diseases
  static Future<List<String>> getAllDiseases() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/diseases'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['diseases'] ?? []);
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching diseases: $e');
      return [];
    }
  }

  // Search formulas based on query
  static Future<Map<String, dynamic>> searchFormulas(String query,
      {int limit = 10}) async {
    // Check cache first
    final cacheKey = 'search_${query}_$limit';
    if (_cache.containsKey(cacheKey)) {
      print('⚡ Cache hit for search "$query" - instant response!');
      return _cache[cacheKey]!;
    }

    try {
      print('🔍 Searching formulas: $baseUrl/search-formulas');

      final response = await http
          .post(
            Uri.parse('$baseUrl/search-formulas'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'query': query, 'limit': limit}),
          )
          .timeout(Duration(seconds: timeoutSeconds));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        // Cache the result
        _cache[cacheKey] = result;
        print('✅ Successfully searched formulas on: $baseUrl');
        return result;
      } else {
        throw Exception('Search API request failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error searching on $baseUrl: $e');
      throw Exception('Failed to search formulas: $e');
    }
  }

  // Health check
  static Future<bool> isApiHealthy() async {
    try {
      print('🔍 Testing API health at: $baseUrl/health');
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
          )
          .timeout(Duration(seconds: 5));

      print('📡 Health check response: ${response.statusCode}');
      print('📄 Health check body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ API is healthy at: $baseUrl');
        return true;
      } else {
        print('❌ Health check failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Health check failed for $baseUrl: $e');
      return false;
    }
  }
}
