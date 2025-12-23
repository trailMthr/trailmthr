import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/trail.dart';

enum NavigationStyle { bottom, top, sidebar }

class AppState extends ChangeNotifier {
  static const _navStyleKey = "nav_style";

  NavigationStyle _navStyle = NavigationStyle.bottom;
  int _currentIndex = 0;

  // Selected activity for viewing on MapScreen
  Trail? _selectedTrail;
  Trail? get selectedTrail => _selectedTrail;

  NavigationStyle get navStyle => _navStyle;
  int get currentIndex => _currentIndex;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_navStyleKey);

    // For now force bottom until others are stable
    if (saved == "bottom") {
      _navStyle = NavigationStyle.bottom;
    } else {
      _navStyle = NavigationStyle.bottom;
      await prefs.setString(_navStyleKey, NavigationStyle.bottom.name);
    }

    notifyListeners();
  }

  Future<void> setNavStyle(NavigationStyle style) async {
    _navStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_navStyleKey, style.name);
    notifyListeners();
  }

  void setIndex(int i) {
    _currentIndex = i;
    notifyListeners();
  }

  void setSelectedTrail(Trail? t) {
    _selectedTrail = t;
    notifyListeners();
  }
}
