import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'app_state.dart';

String resetAuthorizationFromResponse(dynamic data) {
  final body = apiJsonObject(data);
  final token = body['reset_token'];
  if (token is! String || token.isEmpty) {
    throw ApiException('پاسخ بازیابی رمز عبور نامعتبر است.');
  }
  return token;
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();
  final _api = ApiClient.instance;

  AppUser? currentUser;

  Future<AppUser?> tryResumeSession() async {
    final sessionGeneration = _beginAuthenticationTransition();
    try {
      final res = await _api.get('/api/auth/me');
      final body = apiJsonObject(res.data);
      final user = AppUser.fromJson(apiJsonObject(body['user']));
      _activateSession(sessionGeneration, user);
      return currentUser;
    } on ApiException catch (error) {
      if (!error.isUnauthenticated) rethrow;
      if (!AppState.instance.isSessionTransitionCurrent(sessionGeneration)) {
        return currentUser;
      }
      currentUser = null;
      AppState.instance.reset();
      return null;
    }
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final sessionGeneration = _beginAuthenticationTransition();
    final res = await _api.post('/api/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final body = apiJsonObject(res.data);
    final user = AppUser.fromJson(apiJsonObject(body['user']));
    _activateSession(sessionGeneration, user);
    return currentUser!;
  }

  Future<AppUser> login(
      {required String email, required String password}) async {
    final sessionGeneration = _beginAuthenticationTransition();
    final res = await _api.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });
    final body = apiJsonObject(res.data);
    final user = AppUser.fromJson(apiJsonObject(body['user']));
    _activateSession(sessionGeneration, user);
    return currentUser!;
  }

  Future<void> logout() async {
    if (kIsWeb) {
      // Only the server can clear the browser's HttpOnly cookie. If it is
      // unreachable, keep the authenticated UI so a refresh cannot silently
      // sign the person straight back in after showing a logged-out screen.
      await _api.post('/api/auth/logout');
      currentUser = null;
      AppState.instance.reset();
      return;
    }
    currentUser = null;
    AppState.instance.reset();
    await completeLocalLogout(
      remoteLogout: () async {
        await _api.post('/api/auth/logout');
      },
      clearLocalSession: () async {
        await _api.clearSession();
      },
    );
  }

  Future<void> requestResetOtp(String email) async {
    await _api.post('/api/auth/forgot/request-otp', data: {'email': email});
  }

  Future<String> checkResetOtp(
      {required String email, required String code}) async {
    final response = await _api.post('/api/auth/forgot/check-otp', data: {
      'email': email,
      'code': code,
    });
    return resetAuthorizationFromResponse(response.data);
  }

  Future<void> resetPassword({
    required String email,
    required String resetToken,
    required String newPassword,
  }) async {
    await _api.post('/api/auth/forgot/verify', data: {
      'email': email,
      'reset_token': resetToken,
      'new_password': newPassword,
    });
  }

  Future<void> deleteAccount(String password) async {
    final sessionGeneration = AppState.instance.currentSessionGeneration;
    await _api.delete('/api/auth/account', data: {'password': password});
    if (!AppState.instance.isSessionGenerationCurrent(sessionGeneration)) {
      return;
    }
    currentUser = null;
    AppState.instance.reset();
    await _api.clearSession();
  }

  int _beginAuthenticationTransition() {
    currentUser = null;
    return AppState.instance.beginAuthenticationTransition();
  }

  void _activateSession(int generation, AppUser user) {
    if (!AppState.instance.activateSession(generation)) {
      throw ApiException('فرایند ورود لغو شد. دوباره امتحان کنید.');
    }
    currentUser = user;
  }
}

Future<void> completeLocalLogout({
  required Future<void> Function() remoteLogout,
  required Future<void> Function() clearLocalSession,
}) async {
  try {
    await remoteLogout();
  } catch (error) {
    final status = error is ApiException ? error.statusCode : null;
    debugPrint(
      '[logout remote error] ${error.runtimeType}'
      '${status == null ? '' : ', status=$status'}',
    );
  }
  await clearLocalSession();
}
