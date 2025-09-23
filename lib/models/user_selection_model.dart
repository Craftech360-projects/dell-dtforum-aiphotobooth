import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserSelectionModel extends ChangeNotifier {
  String? _theme; // 'linkedin', 'diwali_costume', 'diwali_celebration', 'crackers', 'pooja'
  String? _gender; // 'male' or 'female'
  String? _userName; // User's name
  String? _userEmail; // User's email
  String? _processedImageUrl; // URL of processed image from backend
  Uint8List? _capturedImage;

  // Getters
  String? get theme => _theme;
  String? get gender => _gender;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get processedImageUrl => _processedImageUrl;
  Uint8List? get capturedImage => _capturedImage;

  // Setters
  void setTheme(String theme) {
    _theme = theme;
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setCapturedImage(Uint8List image) {
    _capturedImage = image;
    notifyListeners();
  }

  void setUserInfo(String name, String email) {
    _userName = name;
    _userEmail = email;
    notifyListeners();
  }

  void setProcessedImageUrl(String url) {
    _processedImageUrl = url;
    notifyListeners();
  }

  void clearAll() {
    _theme = null;
    _gender = null;
    _userName = null;
    _userEmail = null;
    _processedImageUrl = null;
    _capturedImage = null;
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': _theme,
      'gender': _gender,
      'hasImage': _capturedImage != null,
    };
  }
}