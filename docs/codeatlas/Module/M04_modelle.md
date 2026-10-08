# M04 · Gemeinsame Datenobjekte beschreiben

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/models/modelle.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/models/modelle.dart)

**Aufgabe:** Definiert acht Fach- und Transportmodelle für Album, Künstler, Kategorie, Einstellungen, Titel, Ordner, API-Seite und lokalen Cache. Album.ausRessourcen() setzt API-Ressourcen zu einem Album zusammen.

**Eingaben:** Konstruktorwerte; Ressourcenindex nach type:id; SQLite-Map für KuenstlerEinstellung.

**Ausgaben:** Typisierte Dart-Objekte; abgeleitete Werte wie Jahr, Anzeigename und Albumanzahl.

**Verbindungen:** Gemeinsame Sprache von HomePage, Detailseiten, SQLite, Sammlung und Coveranzeige.

**Wichtige Namen:** Album, Kuenstler, Kategorie, KuenstlerEinstellung, KuenstlerOrdner, AlbumTitel, AlbumSeite, LokaleBibliothekCache

**Hinweis:** Kategorie hält Album-IDs. Album enthält Künstler, aber keine Titelliste. Ein final-Feld macht eine darin referenzierte Liste nicht automatisch unveränderlich.

**Diagramme:** [02 – Fachmodelle im Arbeitsspeicher](../SVG/02_Klassen_Datenmodelle.svg) · [09 – Von JSON-Ressourcen zu Album-Objekten](../SVG/09_Sequenz_Albumseite.svg)
