import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tidal2wiim/services/tidal_auth_service.dart';

import 'support/memory_session_store.dart';

void main() {
  final now = DateTime.utc(2030, 1, 1, 12);
  final endpoint = Uri.parse('https://openapi.tidal.com/v2/users/me');

  TidalSession session({
    bool expired = false,
    String? refresh = 'refresh-demo',
  }) {
    return TidalSession(
      accessToken: 'access-demo',
      refreshToken: refresh,
      expiresAt: now.add(
        expired ? const Duration(seconds: -1) : const Duration(hours: 1),
      ),
    );
  }

  http.Response renewed({String? refresh}) {
    final json = <String, Object>{
      'access_token': 'access-neu',
      'expires_in': 3600,
      'token_type': 'Bearer',
    };
    if (refresh != null) json['refresh_token'] = refresh;
    return http.Response(jsonEncode(json), 200);
  }

  TidalAuthService auth(
    MemorySessionStore store, {
    Future<http.Response> Function(http.Request)? onRefresh,
  }) {
    final service = TidalAuthService(
      clientId: 'test-client',
      store: store,
      clock: () => now,
      clientFactory: () => MockClient(
        onRefresh ??
            (_) async {
              throw StateError('Unerwarteter Netzwerkzugriff im Test.');
            },
      ),
    );
    addTearDown(service.dispose);
    return service;
  }

  test(
    'Gespeicherter Zugang wird nach Neustart ohne Login verwendet',
    () async {
      final store = MemorySessionStore();
      final first = auth(store);
      await first.acceptLogin(session());
      final second = auth(store);
      await second.restore();
      expect(second.hasSession, isTrue);
      expect(second.hasUsableAccessToken, isTrue);
      expect(await second.accessToken(), 'access-demo');
    },
  );

  test('Abgelaufenes Token wird am dokumentierten Endpunkt erneuert', () async {
    final store = MemorySessionStore();
    final service = auth(
      store,
      onRefresh: (request) async {
        expect(
          request.url.toString(),
          'https://auth.tidal.com/v1/oauth2/token',
        );
        expect(request.method, 'POST');
        expect(request.followRedirects, isFalse);
        final data = Uri.splitQueryString(request.body);
        expect(data['grant_type'], 'refresh_token');
        expect(data['refresh_token'], 'refresh-demo');
        expect(data.containsKey('client_secret'), isFalse);
        return renewed(refresh: 'refresh-neu');
      },
    );
    await service.acceptLogin(session(expired: true));
    expect(await service.accessToken(), 'access-neu');
    final disk = jsonDecode(store.value!) as Map<String, dynamic>;
    expect(disk['session']['refreshToken'], 'refresh-neu');
    expect(service.hasUsableAccessToken, isTrue);
  });

  test(
    'Fehlendes Refresh-Token in Antwort überschreibt das alte nicht',
    () async {
      final store = MemorySessionStore();
      final service = auth(store, onRefresh: (_) async => renewed());
      await service.acceptLogin(session(expired: true));
      await service.accessToken();
      final disk = jsonDecode(store.value!) as Map<String, dynamic>;
      expect(disk['session']['refreshToken'], 'refresh-demo');
    },
  );

  test('Parallele API-Zugriffe teilen sich genau einen Refresh', () async {
    final store = MemorySessionStore();
    final started = Completer<void>();
    final result = Completer<http.Response>();
    var requests = 0;
    final service = auth(
      store,
      onRefresh: (_) {
        requests++;
        if (!started.isCompleted) started.complete();
        return result.future;
      },
    );
    await service.acceptLogin(session(expired: true));
    final pending = List.generate(8, (_) => service.accessToken());
    await started.future;
    result.complete(renewed(refresh: 'refresh-rotation'));
    expect(await Future.wait(pending), everyElement('access-neu'));
    expect(requests, 1);
  });

  test('Internetfehler löscht die gespeicherte Anmeldung nicht', () async {
    final store = MemorySessionStore();
    final service = auth(
      store,
      onRefresh: (_) async {
        throw http.ClientException('simulierter Internetausfall');
      },
    );
    await service.acceptLogin(session(expired: true));
    final previous = store.value;
    await expectLater(
      service.accessToken(),
      throwsA(isA<TidalAuthUnavailable>()),
    );
    expect(store.value, previous);
    expect(service.hasSession, isTrue);
  });

  test('HTTP 503 beim Erneuern ist kein Logout', () async {
    final store = MemorySessionStore();
    final service = auth(
      store,
      onRefresh: (_) async => http.Response('Service unavailable', 503),
    );
    await service.acceptLogin(session(expired: true));
    final previous = store.value;
    await expectLater(
      service.accessToken(),
      throwsA(isA<TidalAuthUnavailable>()),
    );
    expect(store.value, previous);
  });

  test('Defektes Erfolgs-JSON ist kein widerrufenes Refresh-Token', () async {
    final store = MemorySessionStore();
    final service = auth(
      store,
      onRefresh: (_) async => http.Response('{}', 200),
    );
    await service.acceptLogin(session(expired: true));
    final previous = store.value;
    await expectLater(
      service.accessToken(),
      throwsA(isA<TidalAuthUnavailable>()),
    );
    expect(store.value, previous);
  });

  test('invalid_grant verlangt Neuanmeldung und entfernt Tokens', () async {
    final store = MemorySessionStore();
    final service = auth(
      store,
      onRefresh: (_) async => http.Response('{"error":"invalid_grant"}', 400),
    );
    await service.acceptLogin(session(expired: true));
    await expectLater(
      service.accessToken(),
      throwsA(isA<TidalSignInRequired>()),
    );
    expect(store.value, isNull);
    expect(service.hasSession, isFalse);
  });

  test(
    'Fehlendes Refresh-Token verlangt erst nach Ablauf Neuanmeldung',
    () async {
      final store = MemorySessionStore();
      final service = auth(store);
      await service.acceptLogin(session(refresh: null));
      expect(await service.accessToken(), 'access-demo');
      await service.acceptLogin(session(expired: true, refresh: null));
      await expectLater(
        service.accessToken(),
        throwsA(isA<TidalSignInRequired>()),
      );
      expect(store.value, isNull);
    },
  );

  test('Vergessen entfernt den eigenen Token-Eintrag', () async {
    final store = MemorySessionStore();
    final service = auth(store);
    await service.acceptLogin(session());
    await service.forget();
    expect(store.value, isNull);
    expect(service.hasSession, isFalse);
    await expectLater(
      auth(store).accessToken(),
      throwsA(isA<TidalSignInRequired>()),
    );
  });

  test(
    'Laufender Refresh holt eine vergessene Anmeldung nicht zurück',
    () async {
      final store = MemorySessionStore();
      final started = Completer<void>();
      final result = Completer<http.Response>();
      final service = auth(
        store,
        onRefresh: (_) {
          started.complete();
          return result.future;
        },
      );
      await service.acceptLogin(session(expired: true));
      final pending = service.accessToken();
      final assertion = expectLater(
        pending,
        throwsA(isA<TidalSessionChanged>()),
      );
      await started.future;
      await service.forget();
      result.complete(renewed());
      await assertion;
      expect(store.value, isNull);
      expect(service.hasSession, isFalse);
    },
  );

  test('API 401 erneuert und wiederholt genau einmal', () async {
    final store = MemorySessionStore();
    var refreshes = 0;
    var gets = 0;
    final service = auth(
      store,
      onRefresh: (_) async {
        refreshes++;
        return renewed();
      },
    );
    await service.acceptLogin(session());
    final client = MockClient((request) async {
      gets++;
      expect(request.followRedirects, isFalse);
      expect(
        request.headers['Authorization'],
        gets == 1 ? 'Bearer access-demo' : 'Bearer access-neu',
      );
      return http.Response('{}', gets == 1 ? 401 : 200);
    });
    addTearDown(client.close);
    expect((await service.get(client, endpoint)).statusCode, 200);
    expect(gets, 2);
    expect(refreshes, 1);
  });

  test('Auch zweites API 401 führt zu keiner Endlosschleife', () async {
    final store = MemorySessionStore();
    var gets = 0;
    final service = auth(store, onRefresh: (_) async => renewed());
    await service.acceptLogin(session());
    final client = MockClient((_) async {
      gets++;
      return http.Response('{}', 401);
    });
    addTearDown(client.close);
    await expectLater(
      service.get(client, endpoint),
      throwsA(isA<TidalSignInRequired>()),
    );
    expect(gets, 2);
    expect(service.hasSession, isFalse);
  });

  test(
    'API 403 und 429 erneuern nicht und löschen die Sitzung nicht',
    () async {
      for (final status in [403, 429]) {
        final store = MemorySessionStore();
        final service = auth(store);
        await service.acceptLogin(session());
        final client = MockClient((_) async => http.Response('{}', status));
        addTearDown(client.close);
        expect((await service.get(client, endpoint)).statusCode, status);
        expect(service.hasSession, isTrue);
      }
    },
  );

  test(
    'Tokens werden nicht an fremde Hosts oder Klartext-HTTP geschickt',
    () async {
      final service = auth(MemorySessionStore());
      final client = MockClient(
        (_) async => throw StateError('Darf nicht angefragt werden'),
      );
      addTearDown(client.close);
      for (final url in [
        'http://openapi.tidal.com/v2/users/me',
        'https://example.com/test',
      ]) {
        await expectLater(
          service.get(client, Uri.parse(url)),
          throwsArgumentError,
        );
      }
    },
  );

  test(
    'Schreibfehler wird angezeigt, nicht als dauerhafte Speicherung ausgegeben',
    () async {
      final store = MemorySessionStore()..failWrites = true;
      final service = auth(store);
      await service.acceptLogin(session());
      expect(service.hasSession, isTrue);
      expect(service.storageWarning, isNotNull);
      expect(store.value, isNull);
    },
  );

  test('Nicht passende Client-ID wird nicht still wiederverwendet', () async {
    final store = MemorySessionStore();
    await auth(store).acceptLogin(session());
    final other = TidalAuthService(clientId: 'other-client', store: store);
    addTearDown(other.dispose);
    await other.restore();
    expect(other.hasSession, isFalse);
    expect(store.value, isNull);
  });
}
