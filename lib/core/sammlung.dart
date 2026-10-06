part of '../main.dart';

// ============================================================================
// Sortierung und Filter
// ============================================================================

enum Sortierung {
  kuenstler('Künstler A–Z, dann Jahr'),
  titel('Albumtitel A–Z'),
  jahrAuf('Jahr – älteste zuerst'),
  jahrAb('Jahr – neueste zuerst'),
  sammlung('Zuletzt hinzugefügt');

  const Sortierung(this.bezeichnung);

  final String bezeichnung;
}

enum SammlungAnsicht { alben, kuenstler, kategorien }

enum AppSeite { start, labor, sammlung }

int _jahreVergleichen(int? a, int? b, {bool absteigend = false}) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return absteigend ? b.compareTo(a) : a.compareTo(b);
}

int _albenVergleichen(Album a, Album b, Sortierung sortierung) {
  if (sortierung == Sortierung.sammlung) return 0;

  final kuenstler = _vergleichstext(a.kuenstler)
      .compareTo(_vergleichstext(b.kuenstler));
  final titel = _vergleichstext(a.titel).compareTo(_vergleichstext(b.titel));
  final jahr = _jahreVergleichen(
    a.jahr,
    b.jahr,
    absteigend: sortierung == Sortierung.jahrAb,
  );

  final kriterien = switch (sortierung) {
    Sortierung.kuenstler => [kuenstler, jahr, titel],
    Sortierung.titel => [titel, kuenstler, jahr],
    Sortierung.jahrAuf || Sortierung.jahrAb => [jahr, kuenstler, titel],
    Sortierung.sammlung => <int>[],
  };

  for (final vergleich in kriterien) {
    if (vergleich != 0) return vergleich;
  }

  return a.id.compareTo(b.id);
}

List<Album> _ansichtErstellen(
  List<Album> alben,
  String suche,
  Sortierung sortierung,
) {
  final begriffe = _vergleichstext(suche)
      .split(RegExp(r'\s+'))
      .where((wort) => wort.isNotEmpty)
      .toList();

  final auswahl = alben.where((album) {
    final text = _vergleichstext('${album.kuenstler} ${album.titel}');
    return begriffe.every(text.contains);
  }).toList();

  if (sortierung != Sortierung.sammlung) {
    auswahl.sort((a, b) => _albenVergleichen(a, b, sortierung));
  }

  return auswahl;
}

List<KuenstlerOrdner> _kuenstlerOrdnerErstellen(
  List<Album> alben,
  String suche,
  Map<String, KuenstlerEinstellung> einstellungen,
) {
  final gruppen = <String, Map<String, Album>>{};
  final kuenstlerNachId = <String, Kuenstler>{};

  for (final album in alben) {
    var artists = album.kuenstlerListe;

    if (artists.isEmpty) {
      artists = const [
        Kuenstler(id: '__unbekannt__', name: 'Unbekannter Künstler'),
      ];
    }

    for (final artist in artists) {
      kuenstlerNachId[artist.id] = artist;
      gruppen.putIfAbsent(artist.id, () => <String, Album>{})[album.id] = album;
    }
  }

  final suchtext = _vergleichstext(suche);
  final ordner = <KuenstlerOrdner>[];

  for (final eintrag in gruppen.entries) {
    final artist = kuenstlerNachId[eintrag.key];
    if (artist == null) continue;

    final ordnerEintrag = KuenstlerOrdner(
      kuenstler: artist,
      alben: eintrag.value.values.toList(),
      einstellung: einstellungen[artist.id],
    );

    if (suchtext.isNotEmpty) {
      final suchraum = _vergleichstext(
        '${ordnerEintrag.anzeigename} '
        '${ordnerEintrag.sortiername} '
        '${artist.name}',
      );

      if (!suchraum.contains(suchtext)) continue;
    }

    ordnerEintrag.alben.sort((a, b) {
      final jahr = _jahreVergleichen(a.jahr, b.jahr);
      if (jahr != 0) return jahr;

      final titel = _vergleichstext(a.titel)
          .compareTo(_vergleichstext(b.titel));
      if (titel != 0) return titel;

      return a.id.compareTo(b.id);
    });

    ordner.add(ordnerEintrag);
  }

  ordner.sort((a, b) {
    final sortierung = _vergleichstext(a.sortiername)
        .compareTo(_vergleichstext(b.sortiername));
    if (sortierung != 0) return sortierung;

    return a.kuenstler.id.compareTo(b.kuenstler.id);
  });

  return ordner;
}

// ============================================================================
// Alphabet-Navigation
// ============================================================================

const List<String> _alphabet = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  '#',
];

String _alphabetBuchstabe(String sortiername) {
  final text = _vergleichstext(sortiername);
  if (text.isEmpty) return '#';

  final erstesZeichen = text.substring(0, 1).toUpperCase();
  final code = erstesZeichen.codeUnitAt(0);

  if (code >= 65 && code <= 90) {
    return erstesZeichen;
  }

  return '#';
}

Map<String, int> _kuenstlerAlphabetIndex(List<KuenstlerOrdner> ordner) {
  final result = <String, int>{};

  for (var i = 0; i < ordner.length; i++) {
    result.putIfAbsent(_alphabetBuchstabe(ordner[i].sortiername), () => i);
  }

  return result;
}
