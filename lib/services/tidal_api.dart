part of '../main.dart';

// ============================================================================
// Cover
// ============================================================================

String? _coverUrlLesen(Json beziehungen, Map<String, Json> ressourcen) {
  final verweise = _optionalObjekt(beziehungen['coverArt'])['data'];
  if (verweise is! List) return null;

  const zielBreite = 640;

  String? passendeUrl;
  int? passendeBreite;
  String? ersatzUrl;
  var groessteBreite = 0;

  for (final wert in verweise) {
    final verweis = _optionalObjekt(wert);
    final artwork = ressourcen['${verweis['type']}:${verweis['id']}'];
    final attribute = _optionalObjekt(artwork?['attributes']);

    if (attribute['mediaType'] != 'IMAGE') continue;

    final dateien = attribute['files'];
    if (dateien is! List) continue;

    for (final wert in dateien) {
      final datei = _optionalObjekt(wert);
      final adresse = _text(datei['href']);
      final uri = adresse == null ? null : Uri.tryParse(adresse);
      final breite = _optionalObjekt(datei['meta'])['width'];

      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          breite is! num ||
          breite <= 0) {
        continue;
      }

      final pixel = breite.toInt();

      if (pixel > groessteBreite) {
        groessteBreite = pixel;
        ersatzUrl = uri.toString();
      }

      if (pixel >= zielBreite &&
          (passendeBreite == null || pixel < passendeBreite)) {
        passendeBreite = pixel;
        passendeUrl = uri.toString();
      }
    }
  }

  return passendeUrl ?? ersatzUrl;
}

class ApiFehler implements Exception {
  const ApiFehler(this.code, this.pfad);

  final int code;
  final String pfad;
}

// ============================================================================
// API
// ============================================================================

Future<Json> _apiLesen(
  http.Client client,
  TidalAuthService authService,
  List<String> pfadSegmente, [
  Map<String, String> parameter = const {},
]) async {
  await Future<void>.delayed(const Duration(milliseconds: 300));

  final uri = Uri(
    scheme: 'https',
    host: 'openapi.tidal.com',
    pathSegments: pfadSegmente,
    queryParameters: parameter.isEmpty ? null : parameter,
  );

  final response = await authService.get(client, uri);

  debugPrint('TIDAL: GET ${uri.path} -> HTTP ${response.statusCode}');

  if (response.statusCode != 200) {
    throw ApiFehler(response.statusCode, uri.path);
  }

  return _objekt(jsonDecode(utf8.decode(response.bodyBytes)));
}

bool _istAnmeldeFehler(Object e) {
  return e is TidalSignInRequired || (e is ApiFehler && e.code == 401);
}

String _fehlerText(Object e) {
  if (e is TidalAuthUnavailable) return e.message;
  if (e is TidalSessionChanged) {
    return 'Anmeldung wurde geändert. Bitte erneut versuchen.';
  }
  if (e is TidalSignInRequired) {
    return 'Anmeldung abgelaufen. Bitte erneut anmelden.';
  }

  if (e is ApiFehler) {
    final hinweis = switch (e.code) {
      400 => 'Anfrage abgelehnt.',
      401 => 'Token nicht akzeptiert.',
      403 => 'Zugriff verweigert.',
      404 => 'Ressource nicht gefunden.',
      429 => 'Zu viele Anfragen.',
      >= 500 => 'TIDAL-Serverfehler.',
      _ => 'Unerwartete HTTP-Antwort.',
    };

    return 'HTTP ${e.code}: $hinweis\n${e.pfad}';
  }

  if (e is TimeoutException) {
    return 'Zeitüberschreitung nach 20 Sekunden.';
  }

  if (e is http.ClientException) {
    return 'Verbindungsfehler. Internetverbindung prüfen.';
  }

  if (e is FormatException) {
    return 'Unerwartetes Datenformat. ${e.message}';
  }

  return 'Unerwarteter Fehler: ${e.runtimeType}';
}

String? _cursorLesen(Json dokument) {
  final links = _optionalObjekt(dokument['links']);

  final cursor = _text(_optionalObjekt(links['meta'])['nextCursor']);

  if (cursor != null) return cursor;

  final next = links['next'];
  if (next == null || next == '') return null;

  final href = next is String ? next : _text(_optionalObjekt(next)['href']);
  if (href == null) return null;

  return _text(Uri.tryParse(href)?.queryParameters['page[cursor]']);
}
