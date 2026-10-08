# M10 · Albumcover als Dateien zwischenspeichern

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/services/cover_cache.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/cover_cache.dart)

**Aufgabe:** Findet oder lädt Coverdateien im lokalen cover_cache-Verzeichnis. Bündelt laufende Downloads für denselben Zielpfad, schreibt zunächst .tmp und räumt beim Abgleich überholte Dateien auf.

**Eingaben:** Album mit ID und Cover-URL oder List<Album> zum Vorladen; optionaler HTTP-Client.

**Ausgaben:** Future<File?> für ein Cover oder Future<void> nach synchronisieren().

**Verbindungen:** AlbumCover fragt einzelne Dateien an. HomePage startet das Vorladen nach Cacheübernahme oder vollständiger Aktualisierung.

**Wichtige Namen:** LokalerCoverCache.instance, dateiFuer(), synchronisieren(), _herunterladen()

**Hinweis:** Bis zu vier Worker gelten für synchronisieren(), nicht als globale Grenze aller Einzelabrufe. Bildbytes liegen im Dateisystem und nie als BLOB in SQLite.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [06 – Appstart: Cache und gespeicherte Sitzung](../SVG/06_Sequenz_Appstart.svg) · [13 – Coveranzeige: Datei, Download und Ersatzanzeige](../SVG/13_Sequenz_Cover.svg)
