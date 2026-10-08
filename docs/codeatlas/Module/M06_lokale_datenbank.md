# M06 · Strukturierte Daten lokal speichern

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/data/lokale_datenbank.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/data/lokale_datenbank.dart)

**Aufgabe:** Öffnet tidal2wiim.db mit Schema 3 und aktiviert Fremdschlüssel. Kapselt Cache, Künstlerpräferenzen, Kategorien und Albumzuordnungen; übernimmt Migrationen und Transaktionen.

**Eingaben:** Albumlisten mit Zeitstempel, KuenstlerEinstellung, Kategorienamen sowie Album- und Kategorie-IDs.

**Ausgaben:** Future<LokaleBibliothekCache?>, Einstellungs-Map, Kategorienlisten, ID-Mengen oder Future<void>.

**Verbindungen:** HomePage, KategoriePage und AlbumDetailPage nutzen LokaleDatenbank.instance. sqflite führt SQL aus; path bildet den Dateipfad.

**Wichtige Namen:** LokaleDatenbank, albumCacheLaden(), albumCacheSpeichern(), kategorienLaden(), albumKategorienSetzen()

**Hinweis:** Cacheaustausch und Zuordnungswechsel sind atomar. Nur category_albums.category_id ist ein SQL-Fremdschlüssel; Künstlerdaten liegen im Cache als JSON vor.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [08 – Bibliothek laden: Vordergrund und Hintergrund](../SVG/08_Sequenz_Bibliothek.svg) · [12 – Ein Album mehreren Kategorien zuordnen](../SVG/12_Sequenz_Kategorien.svg)
