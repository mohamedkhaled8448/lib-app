import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/book.dart';

/// Custom exception for API errors with a user-friendly message.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiService {
  static const String baseUrl =
      'https://graduation-project-one-xi.vercel.app/api';

  static const Duration timeout = Duration(seconds: 15);

  static const Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

// ================= AUTH HEADERS =================
  static Future<Map<String, String>> authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');

    print("🔑 TOKEN USED: $token");

    if (token != null && token.isNotEmpty) {
      return {
        ...headers,
        "Authorization": "Bearer $token",
      };
    }

    return headers;
  }

// ================= LOGIN =================
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    final url = Uri.parse('$baseUrl/User/login');

    print("🔐 LOGIN START");

    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            "email": email,
            "password": password,
          }),
        )
        .timeout(timeout);

    print("📥 LOGIN STATUS: ${response.statusCode}");
    print("📥 LOGIN BODY: ${response.body}");

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      print("🔥 TOKEN SAVED: $token");

      return {"token": token, "user": user};
    } else {
      throw Exception(data['message'] ?? 'Login failed');
    }
  }

// ================= REGISTER =================
  static Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/User/register');

    final response = await http
        .post(
          url,
          headers: headers,
          body: jsonEncode({
            "Name": name,
            "Email": email,
            "password": password,
          }),
        )
        .timeout(timeout);

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 || response.statusCode == 200) {
      final token = data['token'];
      final user = data['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', token);

      print("🔥 TOKEN SAVED: $token");

      return {"token": token, "user": user};
    } else {
      throw Exception(data['message'] ?? 'Registration failed');
    }
  }

// ================= GET BOOKS =================
  static Future<List<Book>> getBooks() async {
    final url = Uri.parse('$baseUrl/Books');

    print("📚 GET BOOKS START");

    final response = await http
        .get(url, headers: await authHeaders())
        .timeout(timeout);

    print("📥 STATUS: ${response.statusCode}");
    print("📥 BODY: ${response.body}");

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      List list;

      if (decoded is List) {
        list = decoded;
      } else {
        list = decoded['books'] ?? [];
      }

      return list.map((e) => Book.fromJson(e)).toList();
    } else {
      throw ApiException("Failed to load books (${response.statusCode})");
    }
  }

// ================= CHECKOUT BOOK =================
  static Future<void> checkoutBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/$bookId/checkout');

    print("📤 CHECKOUT: userId=$userId bookId=$bookId");

    final response = await http
        .post(
          url,
          headers: await authHeaders(),
          body: jsonEncode({"userId": userId}),
        )
        .timeout(timeout);

    print("📥 CHECKOUT STATUS: ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw ApiException(data['message'] ?? 'Checkout failed');
    }
  }

// ================= RETURN BOOK =================
  static Future<void> returnBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/$bookId/return');

    print("📤 RETURN: userId=$userId bookId=$bookId");

    final response = await http
        .post(
          url,
          headers: await authHeaders(),
          body: jsonEncode({"userId": userId}),
        )
        .timeout(timeout);

    print("📥 RETURN STATUS: ${response.statusCode}");

    if (response.statusCode != 200 && response.statusCode != 201) {
      final data = jsonDecode(response.body);
      throw ApiException(data['message'] ?? 'Return failed');
    }
  }
}
