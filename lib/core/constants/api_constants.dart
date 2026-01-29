class ApiConstants {
  // Base URL for the API
  // User confirmed the domain points directly to the app via symlink/public_html
  static const String baseUrl = "https://darkturquoise-lark-306795.hostingersite.com/api";
  
  // Auth Endpoints
  static const String login = "$baseUrl/login";
  static const String logout = "$baseUrl/logout";
  
  // Dashboard Endpoint
  static const String dashboard = "$baseUrl/dashboard";
  
  // Records & Registry Endpoints
  static const String recordBooks = "$baseUrl/record-books";
  static const String registryEntries = "$baseUrl/registry-entries";
  
  // New Endpoints
  static const String profile = "$baseUrl/profile";
  static const String contractTypes = "$baseUrl/contract-types";
  static String myRecordBook(int contractTypeId) => "$baseUrl/my-record-books/$contractTypeId";
}
