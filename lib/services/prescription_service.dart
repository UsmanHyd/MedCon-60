import 'dart:convert';
import 'package:http/http.dart' as http;

class PrescriptionService {
  // Use your PC's IP directly for fastest connection
  static const List<String> baseUrls = [
    // Android emulator → host machine
    'http://10.0.2.2:5000/api',
    // USB-connected mobile device → PC's network IP
    'http://192.168.0.110:5000/api',
    // Localhost (useful for desktop/simulator)
    'http://127.0.0.1:5000/api',
  ];
  static const int timeoutSeconds = 3; // Reduced timeout for speed

  // Cache for faster responses
  static final Map<String, Map<String, dynamic>> _cache = {};

  // Get drugs for a specific disease
  static Future<Map<String, dynamic>> getDrugsForDisease(String disease) async {
    // Check cache first for instant response
    if (_cache.containsKey(disease)) {
      print('⚡ Cache hit for $disease - instant response!');
      return _cache[disease]!;
    }

    for (String baseUrl in baseUrls) {
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
        }
      } catch (e) {
        print('❌ Error with $baseUrl: $e');
        continue; // Try next URL
      }
    }

    // If all URLs failed
    print('❌ All API URLs failed');
    return {
      'success': false,
      'message':
          'Cannot connect to prescription API. Please check if the server is running.',
      'drugs': []
    };
  }

  // Get all available diseases
  static Future<List<String>> getAllDiseases() async {
    try {
      final response = await http.get(Uri.parse('${baseUrls.first}/diseases'));

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

    for (String baseUrl in baseUrls) {
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
        }
      } catch (e) {
        print('❌ Error searching on $baseUrl: $e');
        continue;
      }
    }

    return {
      'success': false,
      'message': 'Cannot connect to prescription API for search',
      'formulas': []
    };
  }

  // Health check
  static Future<bool> isApiHealthy() async {
    for (String baseUrl in baseUrls) {
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
        }
      } catch (e) {
        print('❌ Health check failed for $baseUrl: $e');
        continue; // Try next URL
      }
    }

    print('❌ All API URLs failed health check');
    return false;
  }
}
