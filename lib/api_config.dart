class ApiConfig {
  // Base IP address - update this when you run any backend server
  static const String baseIp = '192.168.0.108';

  // Server URLs - each server uses a different port
  static String get nutritionServer => 'http://$baseIp:5000';
  static String get diseaseDetectionServer => 'http://$baseIp:8003';
  static String get chatbotServer => 'http://$baseIp:8001';
  static String get consultationServer =>
      'http://$baseIp:5001'; // Changed from 5000
  static String get reminderServer => 'http://$baseIp:3000';
  static String get doctorRecommendationServer => 'http://$baseIp:8004';

  // Default server (for backward compatibility)
  static String get baseUrl => nutritionServer;

  // Helper method to easily update the IP for all servers
  static void updateDeviceIp(String newIp) {
    print('Update baseIp to: $newIp');
    print('All servers will use:');
    print('  - Nutrition: http://$newIp:5000');
    print('  - Disease Detection: http://$newIp:8003');
    print('  - Chatbot: http://$newIp:8001');
    print('  - Consultation: http://$newIp:5001');
    print('  - Reminder: http://$newIp:3000');
    print('  - Doctor Recommendation: http://$newIp:8004');
  }
}
