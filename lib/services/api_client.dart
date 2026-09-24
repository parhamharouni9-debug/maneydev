import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'secure_cookie_storage.dart';

const _defaultApiBaseUrl = 'https://money-tracker.example.workers.dev';

class _ApiBuildConfiguration {
  const _ApiBuildConfiguration()
      : assert(
          !const bool.fromEnvironment('dart.vm.product') ||
              (const bool.hasEnvironment('API_BASE_URL') &&
                  const String.fromEnvironment('API_BASE_URL') != '' &&
                  const String.fromEnvironment('API_BASE_URL') !=
                      _defaultApiBaseUrl),
          'Release builds require a real API_BASE_URL. '
          'Use --dart-define=API_BASE_URL=https://your-worker.example',
        );
}

/// Thin wrapper around the Cloudflare Workers API.
/// Handles the HttpOnly session cookie automatically via a persisted
/// cookie jar, so login survives app restarts just like it does in a browser.
class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();
  static const _buildConfiguration = _ApiBuildConfiguration();

  late final Dio dio;
  PersistCookieJar? _cookieJar;
  bool _ready = false;
  final SingleFlightInitializer _initializer = SingleFlightInitializer();

  /// Set this to your deployed Worker URL, e.g.
  /// "https://money-tracker.your-subdomain.workers.dev"
  static final String baseUrl = validateApiBaseUrl(
    const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: _defaultApiBaseUrl,
    ),
    isRelease: const bool.fromEnvironment('dart.vm.product'),
  );

  Future<void> ensureReady() => _initializer.run(_initialize);

  Future<void> _initialize() async {
    // Referencing the const guard makes release compilation evaluate it.
    _buildConfiguration;
    final validatedBaseUrl = baseUrl;
    if (_ready) return;
    if (!kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      final legacyStorage = FileStorage('${dir.path}/.cookies/');
      _cookieJar = PersistCookieJar(
        // Native platforms persist session cookies in protected storage.
        storage: SecureCookieStorage.platform(legacyStorage: legacyStorage),
      );
    }
    dio = Dio(BaseOptions(
      baseUrl: validatedBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      // Response classification is centralized in [_request].
      validateStatus: (_) => true,
    ));
    // On web, the browser owns the HttpOnly cookie. It cannot be read by Dart
    // and must never be copied into local storage.
    if (!kIsWeb) dio.interceptors.add(CookieManager(_cookieJar!));
    _ready = true;
  }

  Future<void> clearSession() async {
    await ensureReady();
    await _cookieJar?.deleteAll();
  }

  Future<Response> get(String path, {Map<String, dynamic>? query}) async {
    return _request('GET', path, query: query);
  }

  Future<Response> post(String path, {Object? data}) async {
    return _request('POST', path, data: data);
  }

  Future<Response> patch(String path, {Object? data}) async {
    return _request('PATCH', path, data: data);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? query,
    Object? data,
  }) async {
    return _request('DELETE', path, query: query, data: data);
  }

  Future<Response> _request(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? data,
  }) async {
    await ensureReady();
    try {
      final response = await dio.request(
        path,
        data: data,
        queryParameters: query,
        options: Options(method: method),
      );
      return validateApiResponse(response);
    } on ApiException {
      rethrow;
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) return validateApiResponse(response);
      throw ApiException.fromDio(error);
    }
  }
}

class SingleFlightInitializer {
  Future<void>? _pending;
  bool _completed = false;

  Future<void> run(Future<void> Function() initialize) {
    if (_completed) return Future<void>.value();
    final pending = _pending;
    if (pending != null) return pending;

    late final Future<void> operation;
    operation = Future<void>.sync(initialize).then(
      (_) {
        _completed = true;
        if (identical(_pending, operation)) _pending = null;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_pending, operation)) _pending = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _pending = operation;
    return operation;
  }
}

String validateApiBaseUrl(String value, {required bool isRelease}) {
  if (!isRelease) return value;
  final normalized = value.trim();
  Uri? uri;
  try {
    uri = Uri.parse(normalized);
  } on FormatException {
    uri = null;
  }
  if (normalized.isEmpty ||
      normalized == _defaultApiBaseUrl ||
      uri == null ||
      uri.scheme != 'https' ||
      !uri.hasAuthority ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      _isDevelopmentOrPrivateHost(uri.host)) {
    throw StateError(
      'Release builds require an absolute public HTTPS API_BASE_URL.',
    );
  }
  return uri.toString();
}

bool _isDevelopmentOrPrivateHost(String host) {
  final normalized = host.toLowerCase();
  if (normalized == 'localhost' ||
      normalized.endsWith('.localhost') ||
      normalized.endsWith('.local') ||
      normalized.endsWith('.internal') ||
      normalized.endsWith('.test') ||
      normalized.endsWith('.invalid') ||
      normalized == '::1' ||
      (normalized.contains(':') &&
          (normalized.startsWith('fc') ||
              normalized.startsWith('fd') ||
              normalized.startsWith('fe8'))) ||
      normalized.endsWith('.example') ||
      normalized == 'example.com' ||
      normalized.endsWith('.example.com')) {
    return true;
  }
  if (normalized.startsWith('::ffff:')) {
    return _isDevelopmentOrPrivateHost(
      normalized.substring(normalized.lastIndexOf(':') + 1),
    );
  }
  final parts = normalized.split('.');
  if (parts.length != 4) return false;
  final octets = parts.map(int.tryParse).toList();
  if (octets.any((part) => part == null || part < 0 || part > 255)) {
    return false;
  }
  final first = octets[0]!;
  final second = octets[1]!;
  return first == 10 ||
      first == 127 ||
      (first == 169 && second == 254) ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168) ||
      first == 0;
}

enum ApiFailureType {
  unauthorized,
  forbidden,
  notFound,
  rateLimited,
  server,
  network,
  timeout,
  unexpected,
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final ApiFailureType type;

  ApiException(
    this.message, {
    this.statusCode,
    this.type = ApiFailureType.unexpected,
  });

  bool get isUnauthenticated => statusCode == 401 || statusCode == 403;

  factory ApiException.fromResponse(Response response) {
    final status = response.statusCode;
    final (type, fallback) = switch (status) {
      400 => (ApiFailureType.unexpected, 'درخواست نامعتبر بود.'),
      401 => (ApiFailureType.unauthorized, 'نشست شما منقضی شده است.'),
      403 => (ApiFailureType.forbidden, 'اجازه انجام این عملیات را ندارید.'),
      404 => (ApiFailureType.notFound, 'اطلاعات درخواستی پیدا نشد.'),
      409 => (
          ApiFailureType.unexpected,
          'این درخواست با وضعیت فعلی سازگار نیست.'
        ),
      422 => (ApiFailureType.unexpected, 'اطلاعات واردشده معتبر نیست.'),
      429 => (
          ApiFailureType.rateLimited,
          'درخواست‌ها بیش از حد مجاز است. کمی بعد دوباره امتحان کنید.'
        ),
      final code? when code >= 500 => (
          ApiFailureType.server,
          'سرور موقتاً در دسترس نیست. دوباره امتحان کنید.'
        ),
      _ => (ApiFailureType.unexpected, 'درخواست ناموفق بود.'),
    };
    final backendMessage = switch (status) {
      400 || 404 || 409 || 422 => sanitizedBackendError(response.data),
      _ => null,
    };
    return ApiException(
      backendMessage ?? fallback,
      statusCode: status,
      type: type,
    );
  }

  factory ApiException.fromDio(DioException error) {
    final isTimeout = error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout;
    return ApiException(
      isTimeout
          ? 'سرور دیر پاسخ داد. دوباره امتحان کنید.'
          : 'اتصال به سرور برقرار نشد. اینترنت را بررسی کنید.',
      type: isTimeout ? ApiFailureType.timeout : ApiFailureType.network,
    );
  }

  @override
  String toString() => message;
}

String? sanitizedBackendError(Object? data) {
  if (data is! Map || data['error'] is! String) return null;
  final message = (data['error'] as String).trim();
  if (message.isEmpty || message.length > 160) return null;
  if (RegExp(r'[\x00-\x1f\x7f]').hasMatch(message)) return null;
  if (!RegExp(r'[\u0600-\u06ff]').hasMatch(message)) return null;
  if (RegExp(
    r'\b(stack|trace|exception|sql|select|insert|update|delete|syntax|database|query|'
    r'password|token|secret|credential|constraint|column|table|sqlite|postgres|mysql|errno|debug)\b|'
    r'https?://|<[^>]+>|[A-Za-z]:\\|\.dart:\d|\.js:\d|\{.*\}',
    caseSensitive: false,
  ).hasMatch(message)) {
    return null;
  }
  return message;
}

Response validateApiResponse(Response response) {
  final status = response.statusCode;
  if (status != null && status >= 200 && status < 300) return response;
  throw ApiException.fromResponse(response);
}

Map<String, dynamic> apiJsonObject(Object? data) {
  if (data is Map<String, dynamic>) return data;
  throw ApiException(
    'پاسخ نامعتبر از سرور دریافت شد.',
    type: ApiFailureType.unexpected,
  );
}

List<Map<String, dynamic>> apiJsonObjectList(Object? data) {
  if (data is! List) {
    throw ApiException(
      'پاسخ نامعتبر از سرور دریافت شد.',
      type: ApiFailureType.unexpected,
    );
  }
  final result = <Map<String, dynamic>>[];
  for (final item in data) {
    if (item is! Map<String, dynamic>) {
      throw ApiException(
        'پاسخ نامعتبر از سرور دریافت شد.',
        type: ApiFailureType.unexpected,
      );
    }
    result.add(item);
  }
  return result;
}
