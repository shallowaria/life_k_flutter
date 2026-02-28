import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_input.dart';
import '../models/life_destiny_result.dart';

class StorageService {
  static const String _userInputKey = 'userInput';
  static const String _lifeDestinyResultKey = 'lifeDestinyResult';
  static const String _userNameKey = 'userName';

  // Save user input
  Future<void> saveUserInput(UserInput input) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userInputKey, jsonEncode(input.toJson()));
  }

  // Load user input
  Future<UserInput?> loadUserInput() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_userInputKey);
    if (str == null) return null;
    return UserInput.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  // Save destiny result
  Future<void> saveDestinyResult(LifeDestinyResult result) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lifeDestinyResultKey, jsonEncode(result.toJson()));
  }

  // Load destiny result
  Future<LifeDestinyResult?> loadDestinyResult() async {
    final prefs = await SharedPreferences.getInstance();
    final str = prefs.getString(_lifeDestinyResultKey);
    if (str == null) return null;
    return LifeDestinyResult.fromJson(jsonDecode(str) as Map<String, dynamic>);
  }

  // Save user name
  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
  }

  // Load user name
  Future<String> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '未命名';
  }

  // Clear all data
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userInputKey);
    await prefs.remove(_lifeDestinyResultKey);
    await prefs.remove(_userNameKey);
  }
}
