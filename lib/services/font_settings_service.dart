import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FontSettingsService extends ChangeNotifier {
  static const String _fontSizeKey = 'font_size_setting';
  
  String _fontSize = '보통';
  double _textScaleFactor = 1.0;

  String get fontSize => _fontSize;
  double get textScaleFactor => _textScaleFactor;

  // 싱글톤 패턴
  static final FontSettingsService _instance = FontSettingsService._internal();
  factory FontSettingsService() => _instance;
  FontSettingsService._internal();

  // 초기화 - 앱 시작 시 호출
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getString(_fontSizeKey) ?? '보통';
    _updateTextScaleFactor();
    notifyListeners();
  }

  // 글꼴 크기 변경
  Future<void> setFontSize(String fontSize) async {
    _fontSize = fontSize;
    _updateTextScaleFactor();
    
    // SharedPreferences에 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontSizeKey, fontSize);
    
    notifyListeners();
  }

  // 글꼴 크기에 따른 TextScaleFactor 계산
  void _updateTextScaleFactor() {
    switch (_fontSize) {
      case '작게':
        _textScaleFactor = 0.85;
        break;
      case '보통':
        _textScaleFactor = 1.0;
        break;
      case '크게':
        _textScaleFactor = 1.2;
        break;
      default:
        _textScaleFactor = 1.0;
    }
  }

  // 접근성을 위한 더 큰 크기 옵션들
  static List<String> get fontSizeOptions => ['작게', '보통', '크게'];
  
  // 각 크기에 대한 설명
  static String getFontSizeDescription(String fontSize) {
    switch (fontSize) {
      case '작게':
        return '작은 글씨 (85%)';
      case '보통':
        return '기본 글씨 (100%)';
      case '크게':
        return '큰 글씨 (120%)';
      default:
        return '기본 글씨';
    }
  }
}
