import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  String? _userId;
  String? _email;
  String? _name;

  String? get userId => _userId;
  String? get email => _email;
  String? get name => _name;
  bool get isLoggedIn => _userId != null;

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    _email = prefs.getString('email');
    _name = prefs.getString('name');
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final userData = await ApiService.login(email, password);
    _userId = userData['id'];
    _email = userData['email'];
    _name = userData['name'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _userId!);
    await prefs.setString('email', _email!);
    if (_name != null) {
      await prefs.setString('name', _name!);
    }

    notifyListeners();
  }

  Future<void> register(String email, String password) async {
    final userData = await ApiService.register(email, password);
    _userId = userData['id'];
    _email = userData['email'];
    _name = userData['name'];

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', _userId!);
    await prefs.setString('email', _email!);
    if (_name != null) {
      await prefs.setString('name', _name!);
    }

    notifyListeners();
  }

  Future<void> logout() async {
    _userId = null;
    _email = null;
    _name = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  Future<void> updateName(String newName) async {
    final userData = await ApiService.updateUserName(_userId!, newName);
    _name = userData['name'];

    final prefs = await SharedPreferences.getInstance();
    if (_name != null) {
      await prefs.setString('name', _name!);
    } else {
      await prefs.remove('name');
    }

    notifyListeners();
  }
}
