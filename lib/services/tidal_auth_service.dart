import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// Nur diese Schnittstelle schreibt Zugangsdaten. Keine Tokens in SQLite,
/// normalen Preferences, Dateinamen oder Diagnoseausgaben ablegen.
abstract interface class TidalSessionStore {
  Future<String?> read();
  Future<void> write(String? value);
}

class SecureTidalSessionStore implements TidalSessionStore {
  const SecureTidalSessionStore();

  static const _key = 'tidal2wiim.oauth.session.v1';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() => _storage.read(key: _key);

  @override
  Future<void> write(String? value) => value == null
      ? _storage.delete(key: _key)
      : _storage.write(key: _key, value: value);
}

/// Ein zusammengehöriger Token-Satz wird als EIN verschlüsselter Wert abgelegt.
/// TIDALs Refresh-Antwort darf das bisherige Refresh-Token unverändert lassen.
class TidalSession {
  const TidalSession({
    required this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;

  bool usableAt(DateTime time) =>
      accessToken.isNotEmpty && expiresAt != null && expiresAt!.isAfter(time);

  Map<String, Object?> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresAt': expiresAt?.toUtc().toIso8601String(),
  };

  factory TidalSession.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'];
    final refresh = json['refreshToken'];
    final expiry = json['expiresAt'];
    if (access is! String ||
        access.trim().isEmpty ||
        (refresh != null && refresh is! String) ||
        (expiry != null && expiry is! String)) {
      throw const FormatException('Gespeicherte Anmeldung ist unvollständig.');
    }
    final date = expiry is String ? DateTime.tryParse(expiry) : null;
    if (expiry != null && date == null) {
      throw const FormatException('Ungültiger Ablaufzeitpunkt.');
    }
    return TidalSession(
      accessToken: access,
      refreshToken: refresh is String && refresh.isNotEmpty ? refresh : null,
      expiresAt: date,
    );
  }
}

class TidalSignInRequired implements Exception {
  const TidalSignInRequired();
  @override
  String toString() => 'Bitte erneut bei TIDAL anmelden.';
}

class TidalAuthUnavailable implements Exception {
  const TidalAuthUnavailable(this.message);
  final String message;
  @override
  String toString() => message;
}

class TidalSessionChanged implements Exception {
  const TidalSessionChanged();
  @override
  String toString() => 'Die Anmeldung wurde zwischenzeitlich geändert.';
}

/// Eine gemeinsame Sitzung für Startseite, Sammlung UND bereits geöffnete
/// Detailseiten. Jede API-Anfrage holt ihren Zugang hier ab, nicht aus einer
/// beim Öffnen einer Seite kopierten (später veralteten) Token-Zeichenkette.
class TidalAuthService extends ChangeNotifier {
  TidalAuthService({
    required this.clientId,
    TidalSessionStore? store,
    http.Client Function()? clientFactory,
    DateTime Function()? clock,
  }) : _store = store ?? const SecureTidalSessionStore(),
       _clientFactory = clientFactory ?? http.Client.new,
       _clock = clock ?? DateTime.now;

  final String clientId;
  final TidalSessionStore _store;
  final http.Client Function() _clientFactory;
  final DateTime Function() _clock;

  TidalSession? _session;
  Future<void>? _restoring;
  Future<String>? _refreshing;
  Future<void> _storageQueue = Future<void>.value();
  bool _initialized = false;
  bool _disposed = false;
  int _epoch = 0;
  String? _storageWarning;

  bool get initialized => _initialized;
  bool get hasSession => _session != null;
  bool get hasRefreshToken => _session?.refreshToken?.isNotEmpty ?? false;
  bool get hasUsableAccessToken => _session?.usableAt(_clock()) ?? false;
  bool get isRefreshing => _refreshing != null;
  DateTime? get expiresAt => _session?.expiresAt;
  String? get storageWarning => _storageWarning;
  int get epoch => _epoch;

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  void _checkEpoch(int expected) {
    if (_disposed || _epoch != expected) {
      throw const TidalSessionChanged();
    }
  }

  Future<void> restore() {
    if (_initialized) return Future<void>.value();
    return _restoring ??= _restore();
  }

  Future<void> _restore() async {
    try {
      final value = await _store.read();
      if (_disposed) return;
      if (value != null) {
        final json = jsonDecode(value);
        if (json is! Map<String, dynamic> ||
            json['version'] != 1 ||
            json['clientId'] != clientId ||
            json['session'] is! Map<String, dynamic>) {
          throw const FormatException(
            'Gespeicherte Anmeldung passt nicht zur App.',
          );
        }
        _session = TidalSession.fromJson(
          json['session'] as Map<String, dynamic>,
        );
      }
    } on FormatException {
      _session = null;
      _storageWarning =
          'Gespeicherte Anmeldung war nicht lesbar. Bitte neu anmelden.';
      await _persist(); // Entfernt ausschließlich unseren Token-Eintrag.
    } catch (_) {
      // Keine Rohmeldung aus dem Plugin anzeigen: Sie könnte Nutzdaten enthalten.
      _storageWarning =
          'Sicherer Anmeldungsspeicher ist momentan nicht zugänglich.';
    } finally {
      _initialized = true;
      _changed();
    }
  }

  Future<void> acceptLogin(TidalSession session) async {
    await restore();
    if (_disposed) throw const TidalSessionChanged();
    if (session.accessToken.trim().isEmpty) {
      throw const TidalAuthUnavailable(
        'TIDAL hat kein Access-Token geliefert.',
      );
    }
    _epoch++;
    _session = session;
    await _persist();
    _changed();
  }

  Future<void> forget() async {
    await restore();
    _epoch++;
    _session = null;
    // Ein noch laufender Refresh darf die gelöschte Anmeldung nicht zurückholen.
    await _persist();
    _changed();
  }

  Future<void> _persist() {
    final snapshot = _session;
    final value = snapshot == null
        ? null
        : jsonEncode({
            'version': 1,
            'clientId': clientId,
            'session': snapshot.toJson(),
          });
    // Schreibreihenfolge ist auch bei Logout während eines Refreshs eindeutig.
    final operation = _storageQueue.then((_) async {
      try {
        await _store.write(value);
        _storageWarning = null;
      } catch (_) {
        _storageWarning = snapshot == null
            ? 'Anmeldung lokal beendet; gespeicherte Zugangsdaten konnten nicht '
                  'entfernt werden. Bitte „Anmeldung vergessen“ erneut ausführen.'
            : 'Anmeldung funktioniert, konnte aber nicht sicher gespeichert werden. '
                  'Nach einem Neustart kann eine Neuanmeldung nötig sein.';
      }
    });
    _storageQueue = operation;
    return operation;
  }

  Future<String> accessToken({String? rejectedToken}) async {
    await restore();
    final expected = _epoch;
    final session = _session;
    if (session == null) throw const TidalSignInRequired();

    // Auch dann warten, wenn der Refresh das neue Token schon im Speicher hat:
    // Der zugehörige verschlüsselte Schreibvorgang muss erst fertig sein.
    final running = _refreshing;
    if (running != null) {
      try {
        final token = await running;
        _checkEpoch(expected);
        return token;
      } on TidalAuthUnavailable {
        if (rejectedToken == null && session.usableAt(_clock())) {
          _checkEpoch(expected);
          return session.accessToken;
        }
        rethrow;
      }
    }

    // Eine andere Anfrage hat bereits erneuert: dasselbe neue Token verwenden.
    if (rejectedToken != null &&
        rejectedToken != session.accessToken &&
        session.usableAt(_clock())) {
      return session.accessToken;
    }
    if (rejectedToken == null &&
        session.usableAt(_clock().add(const Duration(seconds: 60)))) {
      return session.accessToken;
    }

    final refresh = session.refreshToken;
    if (refresh == null || refresh.isEmpty) {
      if (rejectedToken == null &&
          (session.expiresAt == null || session.usableAt(_clock()))) {
        return session.accessToken;
      }
      await forget();
      throw const TidalSignInRequired();
    }

    final future = _refresh(session, expected);
    _refreshing = future;
    _changed();
    try {
      return await future;
    } on TidalAuthUnavailable {
      // Vorablaufpuffer: Ein noch gültiges Token bleibt im Fehlerfall nutzbar.
      if (rejectedToken == null && session.usableAt(_clock())) {
        _checkEpoch(expected);
        return session.accessToken;
      }
      rethrow;
    } finally {
      if (identical(_refreshing, future)) _refreshing = null;
      _changed();
    }
  }

  Future<String> _refresh(TidalSession old, int expected) async {
    final client = _clientFactory();
    try {
      final request =
          http.Request(
              'POST',
              Uri.parse('https://auth.tidal.com/v1/oauth2/token'),
            )
            ..followRedirects = false
            ..headers['Accept'] = 'application/json'
            ..bodyFields = {
              'grant_type': 'refresh_token',
              'client_id': clientId,
              'refresh_token': old.refreshToken!,
            };
      final response = await _send(client, request);
      _checkEpoch(expected);

      Map<String, dynamic>? json;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map<String, dynamic>) json = decoded;
      } on FormatException {
        // HTML-Fehlerseite oder kaputte Antwort ist KEIN ungültiges Refresh-Token.
      }
      if (response.statusCode != 200) {
        if ((response.statusCode == 400 || response.statusCode == 401) &&
            json?['error'] == 'invalid_grant') {
          await forget();
          throw const TidalSignInRequired();
        }
        throw TidalAuthUnavailable(
          'TIDAL-Anmeldung momentan nicht erneuerbar (HTTP ${response.statusCode}). '
          'Die gespeicherte Anmeldung bleibt erhalten.',
        );
      }

      final access = json?['access_token'];
      final seconds = num.tryParse('${json?['expires_in']}');
      final rotated = json?['refresh_token'];
      final type = json?['token_type'];
      if (access is! String ||
          access.isEmpty ||
          seconds == null ||
          !seconds.isFinite ||
          seconds < 1 ||
          seconds > 315360000 ||
          (rotated != null && rotated is! String) ||
          (type != null && type.toString().toLowerCase() != 'bearer')) {
        throw const TidalAuthUnavailable(
          'TIDAL hat keine verwertbare Token-Antwort geliefert. Anmeldung bleibt erhalten.',
        );
      }
      _session = TidalSession(
        accessToken: access,
        refreshToken: rotated is String && rotated.isNotEmpty
            ? rotated
            : old.refreshToken,
        expiresAt: _clock().add(Duration(seconds: seconds.toInt())),
      );
      await _persist(); // Rotierte Tokens vor der nächsten API-Nutzung sichern.
      _checkEpoch(expected);
      _changed();
      return access;
    } on TidalSignInRequired {
      rethrow;
    } on TidalSessionChanged {
      rethrow;
    } on TidalAuthUnavailable {
      rethrow;
    } catch (_) {
      throw const TidalAuthUnavailable(
        'TIDAL ist momentan nicht erreichbar. Gespeicherte Anmeldung bleibt erhalten.',
      );
    } finally {
      client.close();
    }
  }

  /// API-GET mit genau EINEM Wiederholungsversuch nach HTTP 401.
  /// 403, 429 und Serverfehler lösen weder Logout noch Refresh-Schleifen aus.
  Future<http.Response> get(http.Client client, Uri uri) async {
    if (uri.scheme != 'https' ||
        uri.host != 'openapi.tidal.com' ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty) {
      throw ArgumentError('Authentifizierte Anfrage nur an die TIDAL OpenAPI.');
    }
    await restore();
    final expected = _epoch;
    var token = await accessToken();
    _checkEpoch(expected);

    Future<http.Response> request() {
      final req = http.Request('GET', uri)
        ..followRedirects = false
        ..headers.addAll({
          'Authorization': 'Bearer $token',
          'Accept': 'application/vnd.api+json',
        });
      return _send(client, req);
    }

    var response = await request();
    _checkEpoch(expected);
    if (response.statusCode != 401) return response;

    token = await accessToken(rejectedToken: token);
    _checkEpoch(expected);
    response = await request();
    _checkEpoch(expected);
    if (response.statusCode == 401) {
      // Auch das frisch ermittelte Token wurde ausdrücklich abgelehnt.
      await forget();
      throw const TidalSignInRequired();
    }
    return response;
  }

  static Future<http.Response> _send(http.Client client, http.Request request) {
    return (() async {
      final stream = await client.send(request);
      return http.Response.fromStream(stream);
    })().timeout(const Duration(seconds: 20));
  }

  @override
  void dispose() {
    _disposed = true;
    _epoch++;
    super.dispose();
  }
}
