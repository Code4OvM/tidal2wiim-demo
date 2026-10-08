# M18 · Coverdatei laden und Bildfehler abfangen

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/widgets/album_cover.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/album_cover.dart)

**Aufgabe:** Fordert ein Cover vom Dateicache an und zeigt Ladeanzeige, Datei oder Netzbild. Bei fehlender URL bzw. erfolglosem Netzbild erscheint ein Platzhalter.

**Eingaben:** Album; beim Widget-Update werden geänderte ID oder Cover-URL erkannt.

**Ausgaben:** Bilddarstellung mit FutureBuilder; kein geändertes Albumobjekt.

**Verbindungen:** Verwendet LokalerCoverCache.dateiFuer(), Image.file und als Ersatz Image.network. Eingesetzt in Hauptsammlung, AlbumGrid und Detailseite.

**Wichtige Namen:** AlbumCover, _AlbumCoverState; initState(), didUpdateWidget(), _netzFallback()

**Hinweis:** Ein vorhandener Dateipfad garantiert noch kein decodierbares Bild. Darum besitzt auch Image.file eine Fehlerbehandlung.

**Diagramme:** [13 – Coveranzeige: Datei, Download und Ersatzanzeige](../SVG/13_Sequenz_Cover.svg)
