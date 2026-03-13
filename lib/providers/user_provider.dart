// lib/providers/user_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/api/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  String get greetingName => _currentUser?.firstName ?? 'Guest';
  String get userInitials => _currentUser?.initials ?? '?';

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('🔐 UserProvider: محاولة تسجيل الدخول للإيميل: $email');
      final user = await ApiService.login(email, password);
      _currentUser = user;

      // Persist token so ApiService can attach it to authenticated requests
      if (user.token != null && user.token!.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', user.token!);
        print('💾 UserProvider: تم حفظ التوكن في SharedPreferences');
      }

      _setLoading(false);
      print('✅ UserProvider: تم تسجيل الدخول بنجاح للمستخدم: ${user.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      print('❌ UserProvider: فشل تسجيل الدخول: $e');
      return false;
    }
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      print('📝 UserProvider: محاولة تسجيل مستخدم جديد: $name - $email');
      final user = await ApiService.register(name, email, password);
      _currentUser = user;
      _setLoading(false);
      print('✅ UserProvider: تم التسجيل بنجاح للمستخدم: ${user.name}');
      notifyListeners();
      return true;
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
      print('❌ UserProvider: فشل التسجيل: $e');
      return false;
    }
  }

  void logout() {
    print(
        '👋 UserProvider: تسجيل خروج المستخدم: ${_currentUser?.name ?? 'غير معروف'}');
    _currentUser = null;
    _clearError();
    notifyListeners();
    // Clear persisted token
    SharedPreferences.getInstance().then(
      (prefs) => prefs.remove('auth_token'),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
