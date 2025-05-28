import 'package:flutter/material.dart';

class UserProvider extends ChangeNotifier {
  String? _userId;
  String? _userName;
  String? _userEmail;
  bool _isLoggedIn = false;
  
  String? get userId => _userId;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  bool get isLoggedIn => _isLoggedIn;
  
  void login(String id, String name, String email) {
    _userId = id;
    _userName = name;
    _userEmail = email;
    _isLoggedIn = true;
    notifyListeners();
  }
  
  void logout() {
    _userId = null;
    _userName = null;
    _userEmail = null;
    _isLoggedIn = false;
    notifyListeners();
  }
  
  void updateProfile(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }
}