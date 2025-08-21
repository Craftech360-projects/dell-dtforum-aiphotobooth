import 'dart:typed_data';
import 'package:flutter/material.dart';

class UserSelectionModel extends ChangeNotifier {
  String? _category; // 'linkedin' or 'ai_transformation'
  String? _gender; // 'male' or 'female'
  String? _transformationType; // 'Professional Edge', 'Futuristic Vision', 'Playful Fun'
  String? _transformationOption; // Specific option selected
  String? _selectedCharacter; // Selected character for AI transformation
  String? _userName; // User's name
  String? _userEmail; // User's email
  String? _processedImageUrl; // URL of processed image from backend
  Uint8List? _capturedImage;

  // Getters
  String? get category => _category;
  String? get gender => _gender;
  String? get transformationType => _transformationType;
  String? get transformationOption => _transformationOption;
  String? get selectedCharacter => _selectedCharacter;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get processedImageUrl => _processedImageUrl;
  Uint8List? get capturedImage => _capturedImage;

  // Setters
  void setCategory(String category) {
    _category = category;
    notifyListeners();
  }

  void setGender(String gender) {
    _gender = gender;
    notifyListeners();
  }

  void setTransformation(String type, String option) {
    _transformationType = type;
    _transformationOption = option;
    notifyListeners();
  }

  void setCapturedImage(Uint8List image) {
    _capturedImage = image;
    notifyListeners();
  }

  void setSelectedCharacter(String character) {
    _selectedCharacter = character;
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
    _category = null;
    _gender = null;
    _transformationType = null;
    _transformationOption = null;
    _selectedCharacter = null;
    _userName = null;
    _userEmail = null;
    _processedImageUrl = null;
    _capturedImage = null;
    notifyListeners();
  }

  Map<String, dynamic> toMap() {
    return {
      'category': _category,
      'gender': _gender,
      'transformationType': _transformationType,
      'transformationOption': _transformationOption,
      'hasImage': _capturedImage != null,
    };
  }
}