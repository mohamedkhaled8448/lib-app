// lib/core/api/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/user.dart';
import '../../models/book.dart';

class ApiService {
  // ✅ Vercel Production URL
  static const String baseUrl =
      'https://graduation-project-one-xi.vercel.app/api';

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  /// Returns headers with the stored JWT token if available.
  static Future<Map<String, String>> _authHeaders() async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==================== دوال المصادقة ====================

  /// ✅ تسجيل مستخدم جديد
  static Future<User> register(
      String name, String email, String password) async {
    final url = Uri.parse('$baseUrl/User/register');
    try {
      print('📝 Register Request to: $url');
      print('Name: $name, Email: $email');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          "Name": name, // لاحظ: بحرف كبير N
          "Email": email.trim(), // لاحظ: بحرف كبير E
          "password": password, // بحرف صغير p
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return User.fromJson(responseData);
      } else if (response.statusCode == 400) {
        throw ApiException(
            responseData['message'] ?? 'البيانات المرسلة غير صحيحة');
      } else {
        throw ApiException(responseData['message'] ?? 'فشل التسجيل');
      }
    } catch (e) {
      print('❌ Register error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('تعذّر الاتصال بالخادم، تأكد من الاتصال بالإنترنت');
    }
  }

  /// ✅ تسجيل الدخول
  static Future<User> login(String email, String password) async {
    final url = Uri.parse('https://graduation-project-one-xi.vercel.app/api/User/login');
    try {
      print('🔑 Login Request to: $url');
      print('Email: $email');

      final response = await http.post(
        url,
        headers: _headers,
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      print('📥 Response status: ${response.statusCode}');
      print('📥 Response body: ${response.body}');

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else {
        final data = jsonDecode(response.body);
        throw ApiException(
            data['message'] ?? 'البريد الإلكتروني أو كلمة المرور غير صحيحة');
      }
    } catch (e) {
      print('❌ Login error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('تعذّر الاتصال بالخادم، تأكد من الاتصال بالإنترنت');
    }
  }

  /// ✅ تحديث حالة المستخدم
  static Future<bool> updateUserStatus(String userId) async {
    final url = Uri.parse('$baseUrl/User/update-status/$userId');
    try {
      print('🔄 Updating user status for: $userId');

      final response = await http.put(url, headers: _headers);

      print('📥 Response status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Update status error: $e');
      return false;
    }
  }

  // ==================== دوال الكتب ====================

  /// ✅ جلب جميع الكتب
  static Future<List<Book>> getBooks() async {
    final url = Uri.parse('$baseUrl/Books');
    try {
      print('📚 Fetching books from: $url');

      final response = await http.get(url, headers: await _authHeaders());

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Book.fromJson(json)).toList();
      } else {
        throw ApiException('فشل في جلب الكتب');
      }
    } catch (e) {
      print('❌ Get books error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('تعذّر جلب الكتب، تأكد من الاتصال بالإنترنت');
    }
  }

  // ==================== دوال الإحصائيات والإشعارات ====================

  /// ✅ جلب إشعارات النظام
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final url = Uri.parse('\$baseUrl/stats/notifications');
    try {
      print('🔔 Fetching notifications from: \$url');

      final response = await http.get(url, headers: _headers);

      print('📥 Response status: \${response.statusCode}');
      print('📥 Response body: \${response.body}');

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(response.body);
        // الاستجابة قد تكون List أو Map يحتوي على List
        if (decoded is List) {
          return decoded.cast<Map<String, dynamic>>();
        } else if (decoded is Map && decoded.containsKey('notifications')) {
          return (decoded['notifications'] as List)
              .cast<Map<String, dynamic>>();
        }
        return [];
      } else {
        throw ApiException('فشل في جلب الإشعارات');
      }
    } catch (e) {
      print('❌ Get notifications error: \$e');
      if (e is ApiException) rethrow;
      throw ApiException('تعذّر جلب الإشعارات، تأكد من الاتصال بالإنترنت');
    }
  }

  /// ✅ البحث عن الكتب
  static Future<List<Book>> searchBooks(String query) async {
    try {
      final books = await getBooks();
      return books
          .where((b) =>
              b.title.toLowerCase().contains(query.toLowerCase()) ||
              b.author.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      print('❌ Search books error: $e');
      rethrow;
    }
  }

  /// ✅ استعارة كتاب
  static Future<void> checkoutBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/checkout');
    try {
      print('📖 Checking out book: $bookId for user: $userId');

      final response = await http.post(
        url,
        headers: await _authHeaders(),
        body: jsonEncode({
          'userId': userId,
          'bookId': bookId,
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ApiException('فشل استعارة الكتاب');
      }
    } catch (e) {
      print('❌ Checkout error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  /// ✅ إرجاع كتاب
  static Future<void> returnBook(String userId, String bookId) async {
    final url = Uri.parse('$baseUrl/Books/return');
    try {
      print('📤 Returning book: $bookId from user: $userId');

      final response = await http.post(
        url,
        headers: await _authHeaders(),
        body: jsonEncode({
          'userId': userId,
          'bookId': bookId,
        }),
      );

      print('📥 Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw ApiException('فشل إرجاع الكتاب');
      }
    } catch (e) {
      print('❌ Return error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('حدث خطأ أثناء الاتصال بالخادم');
    }
  }

  // ==================== دوال المساعدة ====================

  /// ✅ التحقق من اتصال السيرفر
  static Future<bool> checkServerConnection() async {
    try {
      final url = Uri.parse('$baseUrl/Books');
      final response = await http.get(url, headers: _headers);
      return response.statusCode != 0;
    } catch (e) {
      return false;
    }
  }
}

// ==================== كلاس مخصص للأخطاء ====================

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
