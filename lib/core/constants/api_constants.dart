class ApiConstants {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String authBaseUrl = 'https://reqres.in/api';
  
  // Auth endpoints
  static const String loginEndpoint = '/login';
  
  // Post endpoints
  static const String postsEndpoint = '/posts';
  static String postDetailsEndpoint(int id) => '/posts/$id';
  static String postCommentsEndpoint(int id) => '/posts/$id/comments';
  
  // Request timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
}
