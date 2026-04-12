import 'package:flutter/foundation.dart';

class AuthNotifier extends ChangeNotifier {
  bool _isLoggedIn = false;

  bool get isLoggedIn => _isLoggedIn;

  void setLoggedIn(bool value) {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    notifyListeners();
  }

  void logout() => setLoggedIn(false);
}
