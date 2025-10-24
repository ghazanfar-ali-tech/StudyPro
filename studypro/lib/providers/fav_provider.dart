import 'package:flutter/foundation.dart';

class FavoriteProvider with ChangeNotifier {
  final List<Map<String, dynamic>> _favoriteCourses = [];

  List<Map<String, dynamic>> get favoriteCourses => _favoriteCourses;

  bool isFavorite(String courseId) {
    return _favoriteCourses.any((course) => course['courseId'] == courseId);
  }

  void toggleFavorite(Map<String, dynamic> course) {
    final existingIndex = _favoriteCourses
        .indexWhere((item) => item['courseId'] == course['courseId']);
    if (existingIndex >= 0) {
      _favoriteCourses.removeAt(existingIndex);
    } else {
      _favoriteCourses.add(course);
    }
    notifyListeners();
  }
}
