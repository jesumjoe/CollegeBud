import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/subject_stats.dart';
import '../services/login_service.dart';
import '../services/attendance_repository.dart';

class AttendanceProvider with ChangeNotifier {
  final _storage = const FlutterSecureStorage();
  final _loginService = LoginService();
  final _repository = AttendanceRepository();

  List<SubjectStats> _subjects = [];
  bool _isLoading = false;
  bool _isAuthChecking = true; // New state
  String? _error;
  bool _isLoggedIn = false;
  Map<String, String>? _sessionHeaders;

  // Login State
  Uint8List? _captchaImage;
  Map<String, String> _loginCookies = {};
  Map<String, String> _loginHiddenFields = {};

  List<SubjectStats> get subjects => _subjects;
  bool get isLoading => _isLoading;
  bool get isAuthChecking => _isAuthChecking;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  Uint8List? get captchaImage => _captchaImage;

  AttendanceProvider() {
    checkSession(); // Auto-check on create
  }

  // Initialize Login Page (Get Captcha)
  Future<void> initLogin() async {
    _setLoading(true);
    _error = null;
    try {
      final data = await _loginService.fetchLoginPage();
      _loginCookies = data.cookies;
      _loginHiddenFields = data.hiddenFields;
      _captchaImage = data.captchaImage;

      if (_captchaImage == null) {
        _error = "Failed to load Captcha image";
      }
    } catch (e) {
      _error = "Connection Error: ${e.toString()}";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String username, String password, String captcha,
      {bool keepLoggedIn = false}) async {
    _setLoading(true);
    _error = null;
    try {
      _sessionHeaders = await _loginService.login(
          username, password, captcha, _loginCookies, _loginHiddenFields);
      _isLoggedIn = true;

      if (keepLoggedIn && _sessionHeaders != null) {
        await _storage.write(
            key: 'session_cookie', value: _sessionHeaders!['Cookie']);
      } else {
        await _storage.delete(key: 'session_cookie');
      }

      // Auto fetch data on login
      await refreshData();
    } catch (e) {
      print('ERROR: Login Exception: $e');
      _error = e.toString();
      _isLoggedIn = false;
      // Refresh captcha on failure? Probably a good idea but let's let user manual refresh for now or just initLogin again
      await initLogin();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> checkSession() async {
    // Don't set _isLoading here to avoid UI flicker, just internal check
    // or use _isAuthChecking
    _isAuthChecking = true;
    notifyListeners();

    try {
      final String? cookie = await _storage.read(key: 'session_cookie');
      if (cookie != null) {
        _sessionHeaders = {'Cookie': cookie};
        // Try to fetch data with this cookie
        await refreshData();

        if (_error == null && _subjects.isNotEmpty) {
          _isLoggedIn = true;
        } else {
          // Cookie likely expired
          _sessionHeaders = null;
          _isLoggedIn = false;
          await _storage.delete(key: 'session_cookie');
          await initLogin(); // Load login page so user can log in
        }
      } else {
        await initLogin();
      }
    } catch (e) {
      await initLogin(); // Fallback
    } finally {
      _isAuthChecking = false;
      _isLoading = false; // Ensure loading off
      notifyListeners();
    }
  }

  String _studentName = "Student";
  String get studentName => _studentName;

  // Global Stats
  double get overallPercentage {
    if (_subjects.isEmpty) return 0.0;
    int totalHours = 0;
    int totalAttended = 0;

    for (var s in _subjects) {
      totalHours += s.totalHours;
      int realAbsents =
          (s.blueAbsents - s.greenDutyLeaves).clamp(0, s.totalHours);
      totalAttended += (s.totalHours - realAbsents);
    }

    if (totalHours == 0) return 0.0;
    return (totalAttended / totalHours) * 100;
  }

  Future<void> refreshData() async {
    if (_sessionHeaders == null) return;

    _setLoading(true);
    try {
      final result =
          await _repository.fetchAttendance(_sessionHeaders!['Cookie']!);

      final statsMap = result['stats'] as Map<String, SubjectStats>;
      _studentName = result['name'] as String;

      if (statsMap.isEmpty) {
        _error =
            "Attendance data could not be parsed. Please check the logs/console for details.";
      }
      _subjects = statsMap.values.toList();
      _subjects.sort((a, b) => a.code.compareTo(b.code));

      // Load saved name if any
      final String? savedName = await _storage.read(key: 'student_name');
      if (savedName != null && savedName.isNotEmpty) {
        _studentName = savedName;
      } else if (_studentName != "Student") {
        // Save scraped name if valid
        await _storage.write(key: 'student_name', value: _studentName);
      }
    } catch (e) {
      _error = "Failed to fetch data: ${e.toString()}";

      // Try load cached name even on error
      final String? savedName = await _storage.read(key: 'student_name');
      if (savedName != null) _studentName = savedName;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateName(String newName) async {
    _studentName = newName;
    await _storage.write(key: 'student_name', value: newName);
    notifyListeners();
  }

  void logout() {
    _storage.delete(key: 'session_cookie');
    _sessionHeaders = null;
    _isLoggedIn = false;
    _subjects = [];
    _captchaImage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
