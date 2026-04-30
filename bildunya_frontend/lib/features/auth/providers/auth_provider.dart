import 'package:flutter/foundation.dart';

import '../../../data/models/auth_response.dart';
import '../../../data/models/login_request.dart';
import '../../../data/models/register_request.dart';
import '../../../data/models/user_dto.dart';
import '../../../data/repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository);

  final AuthRepository _repository;

  UserDto? _user;
  bool _hasToken = false;
  bool _sessionRestored = false;
  bool _busy = false;

  UserDto? get user => _user;
  bool get isAuthenticated => _hasToken;
  bool get sessionRestored => _sessionRestored;
  bool get busy => _busy;

  Future<void> restoreSession() async {
    _busy = true;
    notifyListeners();
    try {
      final token = await _repository.readToken();
      _hasToken = token != null && token.isNotEmpty;
      if (_hasToken) {
        _user = await _repository.readCachedUser();
      }
    } finally {
      _sessionRestored = true;
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> login(LoginRequest request) async {
    _busy = true;
    notifyListeners();
    try {
      final auth = await _repository.login(request);
      _applyAuth(auth);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<String?> register(RegisterRequest request) async {
    _busy = true;
    notifyListeners();
    try {
      final auth = await _repository.register(request);
      _applyAuth(auth);
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  void _applyAuth(AuthResponse auth) {
    _hasToken = auth.accessToken.isNotEmpty;
    _user = auth.user;
  }

  Future<void> logout() async {
    await _repository.clearSession();
    _user = null;
    _hasToken = false;
    notifyListeners();
  }
}
