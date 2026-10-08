# M13 · Album, Titel und lokale Zuordnungen anzeigen

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/album_detail_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/album_detail_page.dart)

**Aufgabe:** Lädt die Titelliste aus TIDAL und Kategorien aus SQLite unabhängig voneinander. Ermöglicht Kategoriezuordnung und öffnet Album-, Track- oder Videolinks extern.

**Eingaben:** Album, gemeinsamer AuthService, **optionaler Ländercode des TIDAL-Kontos, beispielsweise DE für Deutschland** sowie Callbacks für Anmeldung und Kategorieänderungen.

**Ausgaben:** List<AlbumTitel> im Seitenzustand, lokale Kategorieauswahl und externe URLs; Rückmeldung nach gespeicherter Zuordnung.

**Verbindungen:** Aufruf durch HomePage oder AlbumGrid; nutzt _apiLesen(), LokaleDatenbank, AlbumCover und Dialoge.

**Wichtige Namen:** AlbumDetailPage, _AlbumDetailPageState; _titelLaden(), _kategorienBearbeiten(), _inTidalOeffnen(), _titelInTidalOeffnen()

**Hinweis:** Die Titelliste wird nicht dauerhaft gecacht. launchUrl() startet einen externen Handler; Play und WiiM-Auswahl erfolgen anschließend außerhalb unserer App.

**Diagramme:** [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [12 – Ein Album mehreren Kategorien zuordnen](../SVG/12_Sequenz_Kategorien.svg) · [14 – Albumdetails laden und an TIDAL übergeben](../SVG/14_Sequenz_Details_Wiedergabe.svg)
