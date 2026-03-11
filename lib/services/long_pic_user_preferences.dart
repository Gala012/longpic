import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
class UserPreferences extends GetxService {
  static UserPreferences get to => Get.find();
  late SharedPreferences _prefs;
  static const String _keyHasCompletedGuide = 'has_completed_guide';
  static const String _keyVerticalTemplate = 'vertical_template';
  static const String _keyHorizontalTemplate = 'horizontal_template';
  static const String _keyGridTemplate = 'grid_template';
  static const String _keyPosterTemplate = 'poster_template';
  Future<UserPreferences> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }
  bool get hasCompletedGuide =>
      _prefs.getBool(_keyHasCompletedGuide) ?? false;
  Future<void> markGuideCompleted() async {
    await _prefs.setBool(_keyHasCompletedGuide, true);
  }
  Future<void> resetGuide() async {
    await _prefs.setBool(_keyHasCompletedGuide, false);
  }
  Future<bool> saveVerticalTemplate(EditTemplate template) async {
    try {
      final jsonStr = json.encode(template.toJson());
      return await _prefs.setString(_keyVerticalTemplate, jsonStr);
    } catch (e) {
      return false;
    }
  }
  EditTemplate? loadVerticalTemplate() {
    try {
      final jsonStr = _prefs.getString(_keyVerticalTemplate);
      if (jsonStr == null) return null;
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return EditTemplate.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }
  Future<bool> saveHorizontalTemplate(EditTemplate template) async {
    try {
      final jsonStr = json.encode(template.toJson());
      return await _prefs.setString(_keyHorizontalTemplate, jsonStr);
    } catch (e) {
      return false;
    }
  }
  EditTemplate? loadHorizontalTemplate() {
    try {
      final jsonStr = _prefs.getString(_keyHorizontalTemplate);
      if (jsonStr == null) return null;
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return EditTemplate.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }
  Future<bool> saveGridTemplate(GridEditTemplate template) async {
    try {
      final jsonStr = json.encode(template.toJson());
      return await _prefs.setString(_keyGridTemplate, jsonStr);
    } catch (e) {
      return false;
    }
  }
  GridEditTemplate? loadGridTemplate() {
    try {
      final jsonStr = _prefs.getString(_keyGridTemplate);
      if (jsonStr == null) return null;
      final jsonMap = json.decode(jsonStr) as Map<String, dynamic>;
      return GridEditTemplate.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }
  Future<void> clearAllTemplates() async {
    await _prefs.remove(_keyVerticalTemplate);
    await _prefs.remove(_keyHorizontalTemplate);
    await _prefs.remove(_keyGridTemplate);
    await _prefs.remove(_keyPosterTemplate);
  }
}
class EditTemplate {
  final String name;
  final int borderColor;
  final double padding;
  final DateTime createdAt;
  EditTemplate({
    required this.name,
    required this.borderColor,
    required this.padding,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'name': name,
        'borderColor': borderColor,
        'padding': padding,
        'createdAt': createdAt.toIso8601String(),
      };
  factory EditTemplate.fromJson(Map<String, dynamic> json) {
    return EditTemplate(
      name: json['name'] as String,
      borderColor: json['borderColor'] as int,
      padding: (json['padding'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
class GridEditTemplate {
  final String name;
  final int borderColor;
  final double padding;
  final int picsPerRow;
  final String aspectRatio;
  final bool autoFill;
  final DateTime createdAt;
  GridEditTemplate({
    required this.name,
    required this.borderColor,
    required this.padding,
    required this.picsPerRow,
    required this.aspectRatio,
    required this.autoFill,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  Map<String, dynamic> toJson() => {
        'name': name,
        'borderColor': borderColor,
        'padding': padding,
        'picsPerRow': picsPerRow,
        'aspectRatio': aspectRatio,
        'autoFill': autoFill,
        'createdAt': createdAt.toIso8601String(),
      };
  factory GridEditTemplate.fromJson(Map<String, dynamic> json) {
    return GridEditTemplate(
      name: json['name'] as String,
      borderColor: json['borderColor'] as int,
      padding: (json['padding'] as num).toDouble(),
      picsPerRow: json['picsPerRow'] as int,
      aspectRatio: json['aspectRatio'] as String,
      autoFill: json['autoFill'] as bool,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
