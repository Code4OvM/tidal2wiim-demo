import '../models/album_export.dart';

class AlbumExportMetadatenErgebnis {
  const AlbumExportMetadatenErgebnis({
    required this.alben,
    required this.ergaenzt,
    this.hinweis,
  });
  final List<AlbumExportZeile> alben;
  final int ergaenzt;
  final String? hinweis;
}

/// Nur beim Excel-Export: title, version und mediaTags aus /v2/albums lesen.
/// Keine Stream-Manifeste, keine Genreabfragen und keine Schreibzugriffe.
Future<AlbumExportMetadatenErgebnis> albumExportMetadatenErgaenzen({
  required List<AlbumExportZeile> alben,
  required AlbumExportAbbruch abbruch,
  AlbumExportJsonLesen? lesen,
  String? land,
  void Function(int fertig, int gesamt)? fortschritt,
}) async {
  abbruch.pruefen();
  if (lesen == null) {
    return AlbumExportMetadatenErgebnis(
      alben: alben,
      ergaenzt: 0,
      hinweis:
          'Nur lokaler Stand: Separate Versionszusätze und Audioqualität '
          'sind im bisherigen Cache nicht gespeichert. Bereits im Albumtitel '
          'enthaltene Zusätze bleiben erhalten.',
    );
  }
  final result = List<AlbumExportZeile>.of(alben);
  var ergaenzt = 0;
  String? hinweis;
  for (var start = 0; start < result.length; start += 20) {
    abbruch.pruefen();
    final gruppe = result.skip(start).take(20).toList();
    final ids = gruppe.map((a) => a.id).toSet();
    final attribute = <String, Map<String, dynamic>>{};
    final cursorGesehen = <String>{};
    String? cursor;
    try {
      do {
        abbruch.pruefen();
        if (cursor != null && !cursorGesehen.add(cursor)) {
          throw const FormatException('Wiederholter Metadaten-Cursor.');
        }
        if (cursorGesehen.length > 100) {
          throw const FormatException('Unerwartet viele Metadatenseiten.');
        }
        final parameter = <String, String>{'filter[id]': ids.join(',')};
        if (land != null && land.isNotEmpty) {
          parameter['countryCode'] = land;
        }
        if (cursor != null) {
          parameter['page[cursor]'] = cursor;
        }
        final uri = Uri(
          scheme: 'https',
          host: 'openapi.tidal.com',
          path: '/v2/albums',
          queryParameters: parameter,
        );
        final dokument = await lesen(uri);
        abbruch.pruefen();
        final data = dokument['data'];
        if (data is! List) {
          throw const FormatException('Albumliste fehlt.');
        }
        for (final value in data) {
          if (value is! Map) {
            continue;
          }
          final id = value['id'];
          final attrs = value['attributes'];
          if (value['type'] == 'albums' &&
              id is String &&
              ids.contains(id) &&
              attrs is Map<String, dynamic>) {
            attribute[id] = attrs;
          }
        }
        cursor = _naechsterCursor(dokument);
      } while (cursor != null);
      // Erst nach vollständig gelesener Gruppe anwenden.
      for (var index = 0; index < gruppe.length; index++) {
        final attrs = attribute[gruppe[index].id];
        if (attrs != null) {
          result[start + index] = gruppe[index].mitTidalAttributen(attrs);
          ergaenzt++;
        }
      }
      fortschritt?.call(start + gruppe.length, result.length);
    } on AlbumExportAbgebrochen {
      rethrow;
    } catch (_) {
      // Keine Rohfehler/Tokenantworten in Tabelle oder Benutzeranzeige kopieren.
      hinweis =
          'TIDAL-Zusatzabfrage nicht vollständig abgeschlossen. '
          'Alle lokalen Alben bleiben im Export; nicht ergaenzte Angaben '
          'werden nicht geschätzt. Bei Bedarf später erneut exportieren.';
      break;
    }
  }
  abbruch.pruefen();
  if (hinweis == null && ergaenzt < result.length) {
    hinweis =
        'TIDAL hat nicht für jede Album-ID Zusatzmetadaten geliefert. '
        'Die betreffenden Alben bleiben mit ihren lokalen Daten enthalten.';
  }
  return AlbumExportMetadatenErgebnis(
    alben: albumExportSortieren(result),
    ergaenzt: ergaenzt,
    hinweis: hinweis,
  );
}

String? _naechsterCursor(Map<String, dynamic> dokument) {
  final links = dokument['links'];
  if (links is! Map) {
    return null;
  }
  final meta = links['meta'];
  final direct = meta is Map ? meta['nextCursor'] : null;
  if (direct is String && direct.trim().isNotEmpty) {
    return direct.trim();
  }
  final next = links['next'];
  if (next == null || next == '') {
    return null;
  }
  final href = next is String ? next : (next is Map ? next['href'] : null);
  if (href is! String) {
    throw const FormatException('Ungültige Folgeseite.');
  }
  final cursor = Uri.tryParse(href)?.queryParameters['page[cursor]'];
  if (cursor == null || cursor.isEmpty) {
    throw const FormatException('Cursor für Folgeseite fehlt.');
  }
  // Nur den Cursor übernehmen, nicht einem fremden Host folgen.
  return cursor;
}