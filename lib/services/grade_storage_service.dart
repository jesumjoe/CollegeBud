import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attcalci/models/grade_subject.dart';

class GradeStorageService {
  static const String _key = 'grade_subjects_data';

  // Save list
  Future<void> saveSubjects(List<GradeSubject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(subjects.map((e) => e.toJson()).toList());
    await prefs.setString(_key, data);
  }

  // Load list
  Future<List<GradeSubject>> loadSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];

    try {
      final List<dynamic> jsonList = jsonDecode(data);
      return jsonList.map((e) => GradeSubject.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  // Add or Update
  Future<List<GradeSubject>> saveSubject(GradeSubject subject) async {
    List<GradeSubject> current = await loadSubjects();
    int index = current.indexWhere((s) => s.id == subject.id);

    if (index != -1) {
      current[index] = subject; // Update
    } else {
      current.add(subject); // Add
    }

    await saveSubjects(current);
    return current;
  }

  // Delete
  Future<List<GradeSubject>> deleteSubject(String id) async {
    List<GradeSubject> current = await loadSubjects();
    current.removeWhere((s) => s.id == id);
    await saveSubjects(current);
    return current;
  }
}
