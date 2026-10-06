part of '../main.dart';

// ============================================================================
// Modelle
// ============================================================================

class KuenstlerEinstellung {
  const KuenstlerEinstellung({
    required this.kuenstlerId,
    required this.sortiername,
    this.eigenerName,
  });

  final String kuenstlerId;
  final String? eigenerName;
  final String sortiername;

  factory KuenstlerEinstellung.ausMap(Map<String, Object?> map) {
    return KuenstlerEinstellung(
      kuenstlerId: map['artist_id'] as String,
      eigenerName: _text(map['custom_name']),
      sortiername: (map['sort_name'] as String).trim(),
    );
  }

  Map<String, Object?> zuMap() {
    return {
      'artist_id': kuenstlerId,
      'custom_name': eigenerName,
      'sort_name': sortiername,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}

class Kategorie {
  Kategorie({required this.id, required this.name, Set<String>? albumIds})
    : albumIds = albumIds ?? <String>{};

  final int id;
  final String name;
  final Set<String> albumIds;

  int get albumAnzahl => albumIds.length;
}

class Kuenstler {
  const Kuenstler({required this.id, required this.name});

  final String id;
  final String name;
}

class Album {
  const Album({
    required this.id,
    required this.titel,
    required this.kuenstlerListe,
    this.erscheinungsdatum,
    this.coverUrl,
    this.metadatenFehlen = false,
  });

  final String id;
  final String titel;
  final List<Kuenstler> kuenstlerListe;
  final DateTime? erscheinungsdatum;
  final String? coverUrl;
  final bool metadatenFehlen;

  int? get jahr => erscheinungsdatum?.year;

  String get kuenstler {
    if (kuenstlerListe.isEmpty) {
      return 'Künstler nicht übermittelt';
    }
    return kuenstlerListe.map((k) => k.name).join(', ');
  }

  factory Album.ausRessourcen(String id, Map<String, Json> ressourcen) {
    final album = ressourcen['albums:$id'];
    final attribute = _optionalObjekt(album?['attributes']);
    final titel = _text(attribute['title']);
    final datum = _text(attribute['releaseDate']);
    final beziehungen = _optionalObjekt(album?['relationships']);
    final artists = _optionalObjekt(beziehungen['artists']);

    final kuenstler = <Kuenstler>[];
    final bekannteKuenstler = <String>{};

    for (final verweis in _liste(artists['data'] ?? [])) {
      final artistId = _text(verweis['id']);
      final typ = _text(verweis['type']);

      if (artistId == null || typ == null) continue;

      final artist = ressourcen['$typ:$artistId'];
      final name = _text(_optionalObjekt(artist?['attributes'])['name']);

      if (name == null) continue;

      if (bekannteKuenstler.add(artistId)) {
        kuenstler.add(Kuenstler(id: artistId, name: name));
      }
    }

    return Album(
      id: id,
      titel: titel ?? 'Album $id',
      kuenstlerListe: kuenstler,
      erscheinungsdatum: datum == null ? null : DateTime.tryParse(datum),
      coverUrl: _coverUrlLesen(beziehungen, ressourcen),
      metadatenFehlen: titel == null,
    );
  }
}

class LokaleBibliothekCache {
  const LokaleBibliothekCache({
    required this.alben,
    required this.gespeichertAm,
  });

  final List<Album> alben;
  final DateTime gespeichertAm;
}

class AlbumTitel {
  const AlbumTitel({
    required this.id,
    required this.typ,
    required this.titel,
    this.nummer,
    this.teil,
    this.dauer,
  });

  final String id;
  final String typ;
  final String titel;
  final int? nummer;
  final int? teil;
  final Duration? dauer;
}

class KuenstlerOrdner {
  const KuenstlerOrdner({
    required this.kuenstler,
    required this.alben,
    this.einstellung,
  });

  final Kuenstler kuenstler;
  final List<Album> alben;
  final KuenstlerEinstellung? einstellung;

  String get anzeigename {
    final eigenerName = einstellung?.eigenerName?.trim();
    if (eigenerName != null && eigenerName.isNotEmpty) {
      return eigenerName;
    }
    return kuenstler.name;
  }

  String get sortiername {
    final lokal = einstellung?.sortiername.trim();
    if (lokal != null && lokal.isNotEmpty) {
      return lokal;
    }
    return anzeigename;
  }
}

class AlbumSeite {
  const AlbumSeite(this.alben, this.naechsterCursor);

  final List<Album> alben;
  final String? naechsterCursor;
}
