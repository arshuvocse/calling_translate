import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client.dart';
import 'models.dart';

class AppState extends ChangeNotifier {
  static const _authUserKey = 'auth_user';

  final api = ApiClient();
  AuthUser? currentUser;
  List<AppUser> users = [];
  bool loading = false;
  bool initialized = false;
  String? error;

  bool get isAuthenticated => currentUser != null;

  Future<void> restoreSession() async {
    loading = true;
    notifyListeners();

    try {
      final preferences = await SharedPreferences.getInstance();
      final savedAuth = preferences.getString(_authUserKey);
      if (savedAuth != null) {
        currentUser = AuthUser.fromJson(jsonDecode(savedAuth) as Map<String, dynamic>);
        await loadUsers();
      }
    } catch (_) {
      await _clearSavedSession();
      currentUser = null;
      users = [];
    } finally {
      initialized = true;
      loading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    await _run(() async {
      currentUser = await api.login(email, password);
      await _saveSession(currentUser!);
      await loadUsers();
    });
  }

  Future<void> register(String displayName, String email, String password, String sourceLanguage, String targetLanguage) async {
    await _run(() async {
      currentUser = await api.register(
        displayName: displayName,
        email: email,
        password: password,
        sourceLanguage: sourceLanguage,
        targetLanguage: targetLanguage,
      );
      await _saveSession(currentUser!);
      await loadUsers();
    });
  }

  Future<void> loadUsers() async {
    final token = currentUser?.token;
    if (token == null) return;
    users = await api.users(token);
    notifyListeners();
  }

  Future<void> updateLanguagesAndRegion(String sourceLanguage, String targetLanguage) async {
    if (currentUser == null) return;
    currentUser = AuthUser(
      userId: currentUser!.userId,
      displayName: currentUser!.displayName,
      email: currentUser!.email,
      token: currentUser!.token,
      preferredSourceLanguage: sourceLanguage,
      preferredTargetLanguage: targetLanguage,
    );
    await _saveSession(currentUser!);
    notifyListeners();
  }

  Future<void> logout() async {
    await _clearSavedSession();
    currentUser = null;
    users = [];
    notifyListeners();
  }

  Future<void> _saveSession(AuthUser user) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_authUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearSavedSession() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_authUserKey);
  }

  Future<void> _run(Future<void> Function() action) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}
