// Bearbeitungsmodell ohne Flutter-, Datenbank- oder TIDAL-Abhängigkeit.
// Änderungen werden zunächst nur im Arbeitsspeicher gesammelt.

class KuenstlerSortierZeile {
  const KuenstlerSortierZeile({
    required this.id,
    required this.tidalName,
    required this.anzeigename,
    this.gespeicherterSortiername,
  });

  final String id;
  final String tidalName;
  final String anzeigename;
  final String? gespeicherterSortiername;

  String get startwert {
    final vorhanden = gespeicherterSortiername?.trim();
    return vorhanden == null || vorhanden.isEmpty ? tidalName : vorhanden;
  }
}

class KuenstlerSortierAenderung {
  const KuenstlerSortierAenderung({
    required this.kuenstlerId,
    required this.tidalName,
    required this.sortiername,
  });

  final String kuenstlerId;
  final String tidalName;
  final String sortiername;
}

class KuenstlerSortierEntwurf {
  KuenstlerSortierEntwurf(Iterable<KuenstlerSortierZeile> eingabe) {
    final sortiert = eingabe.toList();
    for (final zeile in sortiert) {
      if (zeile.id.trim().isEmpty || zeile.tidalName.trim().isEmpty) {
        throw ArgumentError(
          'Künstler-ID und TIDAL-Name dürfen nicht leer sein.',
        );
      }
      if (_nachId.containsKey(zeile.id)) {
        throw ArgumentError('Die Künstler-ID kommt mehrfach vor: ${zeile.id}');
      }
      _nachId[zeile.id] = zeile;
      _werte[zeile.id] = zeile.startwert;
    }
    // Feste Reihenfolge nach dem Anzeigenamen, NICHT nach den gerade
    // bearbeiteten Sortiernamen. So springt beim Schreiben keine Zeile weg.
    sortiert.sort((a, b) {
      final vergleich = _suchform(a.anzeigename)
          .compareTo(_suchform(b.anzeigename));
      return vergleich != 0 ? vergleich : a.id.compareTo(b.id);
    });
    zeilen = List.unmodifiable(sortiert);
  }

  late final List<KuenstlerSortierZeile> zeilen;
  final Map<String, KuenstlerSortierZeile> _nachId = {};
  final Map<String, String> _werte = {};

  String wertFuer(String id) {
    if (!_nachId.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Unbekannter Künstler');
    }
    return _werte[id]!;
  }

  void setzen(String id, String wert) {
    if (!_nachId.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'Unbekannter Künstler');
    }
    // Rohtext behalten: Cursor und Eingabemethode dürfen nicht durch
    // Trimmen während des Tippens verändert werden.
    _werte[id] = wert;
  }

  String _effektiverWert(KuenstlerSortierZeile zeile) {
    final wert = _werte[zeile.id]!.trim();
    return wert.isEmpty ? zeile.tidalName.trim() : wert;
  }

  bool istGeaendert(String id) {
    final zeile = _nachId[id];
    if (zeile == null) {
      throw ArgumentError.value(id, 'id', 'Unbekannter Künstler');
    }
    return _effektiverWert(zeile) != zeile.startwert.trim();
  }

  List<KuenstlerSortierAenderung> get aenderungen => List.unmodifiable([
    for (final zeile in zeilen)
      if (istGeaendert(zeile.id))
        KuenstlerSortierAenderung(
          kuenstlerId: zeile.id,
          tidalName: zeile.tidalName,
          sortiername: _effektiverWert(zeile),
        ),
  ]);

  bool get hatAenderungen => zeilen.any((zeile) => istGeaendert(zeile.id));
  int get anzahlAenderungen =>
      zeilen.where((zeile) => istGeaendert(zeile.id)).length;

  List<KuenstlerSortierZeile> filtern(String suche) {
    final woerter = _suchform(suche)
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty);
    return [
      for (final zeile in zeilen)
        // Nur feste Ausgangswerte durchsuchen. Eine gerade geänderte Eingabe
        // darf nicht dazu führen, dass das aktive Feld aus dem Filter fällt.
        if (woerter.every(
          _suchform(
            '${zeile.anzeigename} ${zeile.tidalName} ${zeile.startwert}',
          ).contains,
        ))
          zeile,
    ];
  }

  static String _suchform(String wert) => wert
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
}
