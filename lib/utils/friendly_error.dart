import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../services/api_client.dart';

/// Turns whatever exception an auth/network call threw into a short,
/// clean Persian sentence safe to show in the UI. The backend's own
/// [ApiException] messages are already Persian and specific (e.g. "این
/// ایمیل قبلاً ثبت شده") so those pass straight through unchanged —
/// this only steps in for raw technical failures (DioException, socket
/// errors, etc.) that would otherwise leak a stack-trace-looking string
/// to the person using the app.
///
/// The original error is still printed via [debugPrint] so it's not
/// lost for debugging — it's just not shown on screen.
String friendlyError(Object error) {
  // Deliberately log only the error's type/message, never the full
  // object — DioException carries the original RequestOptions (which
  // could include the password field for login/register calls), and a
  // careless `debugPrint(error)` could end up echoing that into the
  // console. Logging just runtimeType + a short description keeps this
  // useful for debugging without ever touching request bodies.
  debugPrint('[auth error] ${error.runtimeType}: ${_shortDescription(error)}');

  if (error is ApiException) {
    return error.message;
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
        return 'اتصال به اینترنت برقرار نیست. دوباره امتحان کن.';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'سرور دیر جواب داد. یه بار دیگه امتحان کن.';
      case DioExceptionType.badResponse:
        final data = error.response?.data;
        if (data is Map && data['error'] is String) {
          return data['error'] as String;
        }
        return 'مشکلی تو ارتباط با سرور پیش اومد.';
      default:
        return 'یه مشکل غیرمنتظره پیش اومد. دوباره امتحان کن.';
    }
  }

  return 'یه مشکل غیرمنتظره پیش اومد. دوباره امتحان کن.';
}

String friendlyAuthError(Object error) => friendlyError(error);

/// A safe, short description for logs — never touches request bodies
/// (where a password could live), only status codes / error types.
String _shortDescription(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final status = error.response?.statusCode;
    return 'type=${error.type}${status != null ? ', status=$status' : ''}';
  }
  return error.runtimeType.toString();
}
