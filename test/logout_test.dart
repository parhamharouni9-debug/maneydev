import 'package:flutter_test/flutter_test.dart';
import 'package:pool_man/services/api_client.dart';
import 'package:pool_man/services/auth_service.dart';

void main() {
  test('successful remote logout clears the local session', () async {
    var remoteCalled = false;
    var localCleared = false;

    await completeLocalLogout(
      remoteLogout: () async => remoteCalled = true,
      clearLocalSession: () async => localCleared = true,
    );

    expect(remoteCalled, isTrue);
    expect(localCleared, isTrue);
  });

  test('offline logout still clears the local session', () async {
    var localCleared = false;

    await completeLocalLogout(
      remoteLogout: () async => throw ApiException(
        'offline',
        type: ApiFailureType.network,
      ),
      clearLocalSession: () async => localCleared = true,
    );

    expect(localCleared, isTrue);
  });

  test('remote 5xx logout still clears the local session', () async {
    var localCleared = false;

    await completeLocalLogout(
      remoteLogout: () async => throw ApiException(
        'server detail',
        statusCode: 503,
        type: ApiFailureType.server,
      ),
      clearLocalSession: () async => localCleared = true,
    );

    expect(localCleared, isTrue);
  });
}
