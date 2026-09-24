import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/services/api_client.dart';

Response<dynamic> response(int status, [Object? data]) => Response(
      requestOptions: RequestOptions(path: '/test'),
      statusCode: status,
      data: data,
    );

void main() {
  test('only 2xx responses are successful', () {
    expect(validateApiResponse(response(200)).statusCode, 200);
    expect(validateApiResponse(response(204)).statusCode, 204);
  });

  for (final entry in <int, ApiFailureType>{
    401: ApiFailureType.unauthorized,
    403: ApiFailureType.forbidden,
    404: ApiFailureType.notFound,
    429: ApiFailureType.rateLimited,
    500: ApiFailureType.server,
    503: ApiFailureType.server,
  }.entries) {
    test('${entry.key} is mapped to ${entry.value.name}', () {
      expect(
        () => validateApiResponse(response(entry.key)),
        throwsA(
          isA<ApiException>()
              .having((error) => error.statusCode, 'statusCode', entry.key)
              .having((error) => error.type, 'type', entry.value),
        ),
      );
    });
  }

  test('sanitized backend message is allowed only for client-safe status', () {
    expect(
      () => validateApiResponse(response(400, {'error': 'درخواست نامعتبر'})),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'درخواست نامعتبر',
        ),
      ),
    );
  });

  for (final status in [401, 403, 429, 500, 503]) {
    test('$status ignores backend error details', () {
      final exception = ApiException.fromResponse(response(status, {
        'error': 'SQL exception: SELECT password FROM users',
      }));

      expect(exception.message, isNot(contains('SQL')));
      expect(exception.message, isNot(contains('password')));
    });
  }

  test('technical backend details are rejected for client-safe statuses', () {
    for (final detail in [
      'SQL exception: SELECT * FROM users',
      'Stack trace\nat handler.dart:42',
      '<html>proxy failure</html>',
      '{"exception":"database"}',
    ]) {
      final exception = ApiException.fromResponse(
        response(400, {'error': detail}),
      );
      expect(exception.message, 'درخواست نامعتبر بود.');
    }
  });

  test('malformed and unexpected responses use fixed messages', () {
    expect(
      ApiException.fromResponse(response(418, 'SQL exception')).message,
      'درخواست ناموفق بود.',
    );
    expect(
      () => apiJsonObject({'unexpected': true}['missing']),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          'پاسخ نامعتبر از سرور دریافت شد.',
        ),
      ),
    );
  });

  test('only 401 and 403 are unauthenticated failures', () {
    expect(ApiException.fromResponse(response(401)).isUnauthenticated, isTrue);
    expect(ApiException.fromResponse(response(403)).isUnauthenticated, isTrue);
    expect(ApiException.fromResponse(response(429)).isUnauthenticated, isFalse);
    expect(ApiException.fromResponse(response(503)).isUnauthenticated, isFalse);
    expect(
      ApiException('offline', type: ApiFailureType.network).isUnauthenticated,
      isFalse,
    );
  });
}
