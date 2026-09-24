import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/services/api_client.dart';
import 'package:pool_man/services/auth_service.dart';

void main() {
  test('password reset check extracts the one-time reset authorization', () {
    expect(
      resetAuthorizationFromResponse({
        'ok': true,
        'reset_token': 'short-lived-one-time-token',
      }),
      'short-lived-one-time-token',
    );
  });

  test('missing reset authorization is rejected before password submission',
      () {
    expect(
      () => resetAuthorizationFromResponse({'ok': true}),
      throwsA(isA<ApiException>()),
    );
  });
}
