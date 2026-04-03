import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../core/api/api_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool isLoading = false;
  String? error;

  User? get currentUser => _user;

// ================= AUTO LOGIN =================
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final token = prefs.getString('auth_token');

    if (userJson == null || token == null || token.isEmpty) return false;

    try {
      _user = User.fromJson(jsonDecode(userJson));
      notifyListeners();
      return true;
    } catch (e) {
      print("❌ AUTO LOGIN ERROR: $e");
      return false;
    }
  }

// ================= LOGIN =================
  Future<bool> login(String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ApiService.login(email, password);

      _user = User.fromJson(result['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      print("❌ LOGIN ERROR: $e");
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

// ================= REGISTER =================
  Future<bool> register(String name, String email, String password) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final result = await ApiService.register(name, email, password);

      _user = User.fromJson(result['user']);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(_user!.toJson()));

      return true;
    } catch (e) {
      print("❌ REGISTER ERROR: $e");
      error = e.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

// ================= LOGOUT =================
  Future<void> logout() async {
    _user = null;
    error = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    await prefs.remove('auth_token');
    notifyListeners();
  }
}
