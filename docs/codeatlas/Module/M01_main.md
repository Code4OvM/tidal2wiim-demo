# M01 · App starten und Dateien verbinden

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/main.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/main.dart)

**Aufgabe:** Startet Flutter mit Tidal2WiiMApp. Baut MaterialApp, dunkles Theme und HomePage auf. Verbindet 16 part-Dateien zu einer gemeinsamen Dart-Bibliothek und importiert zwei weitere eigene Bibliotheken.

**Eingaben:** Optional: bibliothekLaden-Callback und TidalAuthService für isolierte Tests.

**Ausgaben:** Widget-Baum mit HomePage; selbst keine Albumdaten oder SQL-Abfragen.

**Verbindungen:** Bindet alle part-Dateien ein; importiert models/kuenstler_sortierung.dart und services/tidal_auth_service.dart.

**Wichtige Namen:** main(), Tidal2WiiMApp.build()

**Hinweis:** Die Ordner sind fachliche Bereiche. Technisch ist tidal2wiim ein Dart-Paket mit drei eigenen Bibliotheken.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [06 – Appstart: Cache und gespeicherte Sitzung](../SVG/06_Sequenz_Appstart.svg)
