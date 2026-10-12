import 'dart:convert';

/// Unabhängige Exportdaten: keine Tokens, Coverdateien oder Datenbank-Handles.
class AlbumExportZeile {
  AlbumExportZeile({
    required this.id,
    required this.titel,
    required Iterable<String> kuenstler,
    this.erscheinungsdatum,
    Iterable<String> kategorien = const [],
    this.version,
    Iterable<String> mediaTags = const [],
  }) : kuenstler = List<String>.unmodifiable(kuenstler),
       kategorien = List<String>.unmodifiable(kategorien),
       mediaTags = List<String>.unmodifiable(mediaTags) {
    if (id.trim().isEmpty) {
      throw const FormatException('Album-ID fehlt.');
    }
  }

  final String id;
  final String titel;
  final List<String> kuenstler;
  final DateTime? erscheinungsdatum;
  final List<String> kategorien;
  final String? version;

  /// Unveränderte Katalog-Tags, NICHT die aktuelle Wiedergabequalität.
  final List<String> mediaTags;

  String get albumname {
    final zusatz = version?.trim() ?? '';
    if (zusatz.isEmpty) {
      return titel;
    }
    final name = titel.trimRight();
    final lower = name.toLowerCase();
    final v = zusatz.toLowerCase();
    // Ein bereits im Titel enthaltener Zusatz wird nicht noch einmal angehängt.
    if (lower == v ||
        lower.endsWith('($v)') ||
        lower.endsWith('[$v]') ||
        lower.endsWith(' - $v')) {
      return name;
    }
    return '$name ($zusatz)';
  }

  String get link => Uri(
    scheme: 'https',
    host: 'tidal.com',
    pathSegments: ['album', id],
  ).toString();

  AlbumExportZeile mitTidalAttributen(Map<String, dynamic> attribute) {
    String? text(Object? value) =>
        value is String && value.trim().isNotEmpty ? value.trim() : null;
    final tags = attribute['mediaTags'];
    return AlbumExportZeile(
      id: id,
      titel: text(attribute['title']) ?? titel,
      kuenstler: kuenstler,
      erscheinungsdatum: erscheinungsdatum,
      kategorien: kategorien,
      version: text(attribute['version']),
      mediaTags: tags is List
          ? tags
                .whereType<String>()
                .map((s) => s.trim())
                .where((s) => s.isNotEmpty)
                .toSet()
                .toList()
          : const [],
    );
  }
}

class AlbumExportSnapshot {
  AlbumExportSnapshot({
    required Iterable<AlbumExportZeile> alben,
    required this.cacheStand,
  }) : alben = List<AlbumExportZeile>.unmodifiable(alben);
  final List<AlbumExportZeile> alben;
  final DateTime? cacheStand;
}

/// Nur der Export wird abgebrochen; die gespeicherte Sammlung wird nie geändert.
class AlbumExportAbbruch {
  bool _abgebrochen = false;
  bool get abgebrochen => _abgebrochen;
  void abbrechen() => _abgebrochen = true;
  void pruefen() {
    if (_abgebrochen) {
      throw const AlbumExportAbgebrochen();
    }
  }
}

class AlbumExportAbgebrochen implements Exception {
  const AlbumExportAbgebrochen();
}

typedef AlbumExportJsonLesen = Future<Map<String, dynamic>> Function(Uri uri);

String albumExportVergleich(String text) => text
    .trim()
    .toLowerCase()
    .replaceAll('ä', 'a')
    .replaceAll('ö', 'o')
    .replaceAll('ü', 'u')
    .replaceAll('ß', 'ss');

/// Mehrere Künstler/Kategorien vervielfachen keine Albumzeile.
/// Verschiedene Album-IDs bleiben auch bei identischen Titeln getrennt.
List<AlbumExportZeile> albumExportSortieren(Iterable<AlbumExportZeile> alben) {
  final nachId = <String, AlbumExportZeile>{};
  for (final album in alben) {
    nachId.putIfAbsent(album.id, () => album);
  }
  final result = nachId.values.toList();
  result.sort((a, b) {
    final artist = albumExportVergleich(a.kuenstler.join('; '))
        .compareTo(albumExportVergleich(b.kuenstler.join('; ')));
    if (artist != 0) {
      return artist;
    }
    final title = albumExportVergleich(a.albumname)
        .compareTo(albumExportVergleich(b.albumname));
    return title != 0 ? title : a.id.compareTo(b.id);
  });
  return List<AlbumExportZeile>.unmodifiable(result);
}

/// Reine Abbildung des vorhandenen SQLite-Schemas; getrennt testbar.
AlbumExportSnapshot albumExportAusDatenbankzeilen(
  List<Map<String, Object?>> albumZeilen,
  List<Map<String, Object?>> zuordnungen,
) {
  final kategorien = <String, Set<String>>{};
  for (final row in zuordnungen) {
    final id = row['album_id'];
    final name = row['name'];
    if (id is! String || name is! String) {
      throw const FormatException('Kategoriezuordnung ist unvollständig.');
    }
    kategorien.putIfAbsent(id, () => <String>{}).add(name);
  }
  final alben = <AlbumExportZeile>[];
  int? cacheZeit;
  for (final row in albumZeilen) {
    final id = row['album_id'];
    final title = row['title'];
    final artistJson = row['artists_json'];
    if (id is! String || title is! String || artistJson is! String) {
      throw const FormatException('Albumdaten sind unvollständig.');
    }
    final decoded = jsonDecode(artistJson);
    if (decoded is! List) {
      throw const FormatException('Künstlerliste ist ungültig.');
    }
    final artists = <String>[];
    for (final item in decoded) {
      if (item is! Map || item['name'] is! String) {
        throw const FormatException('Künstlername fehlt.');
      }
      artists.add(item['name'] as String);
    }
    final cats = (kategorien[id] ?? <String>{}).toList()
      ..sort(
        (a, b) => albumExportVergleich(a).compareTo(albumExportVergleich(b)),
      );
    final time = row['cached_at'];
    if (time is int && (cacheZeit == null || time > cacheZeit)) {
      cacheZeit = time;
    }
    final date = row['release_date'];
    alben.add(
      AlbumExportZeile(
        id: id,
        titel: title,
        kuenstler: artists,
        kategorien: cats,
        erscheinungsdatum: date is String ? DateTime.tryParse(date) : null,
      ),
    );
  }
  return AlbumExportSnapshot(
    alben: albumExportSortieren(alben),
    cacheStand: cacheZeit == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(cacheZeit),
  );
}