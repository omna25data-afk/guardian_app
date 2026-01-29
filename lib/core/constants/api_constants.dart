class ApiConstants {
  // Base URL is now dynamic, initialized by main_common.dart
  static String _baseUrl = "https://darkturquoise-lark-306795.hostingersite.com/api"; 

  static void init(String baseUrl) {
    _baseUrl = baseUrl;
  }

  static String get baseUrl => _baseUrl;
  
  // Auth Endpoints
  static String get login => "$_baseUrl/login";
  static String get logout => "$_baseUrl/logout";
  
  // Dashboard Endpoint
  static String get dashboard => "$_baseUrl/dashboard";
  
  // Records & Registry Endpoints
  static String get recordBooks => "$_baseUrl/record-books";
  static String get registryEntries => "$_baseUrl/registry-entries";
  
  // New Endpoints
  static String get profile => "$_baseUrl/profile";
  static String get contractTypes => "$_baseUrl/contract-types";
  static String myRecordBook(int contractTypeId) => "$_baseUrl/my-record-books/$contractTypeId";
  static String formFields(int contractTypeId) => "$_baseUrl/form-fields/$contractTypeId";
}
