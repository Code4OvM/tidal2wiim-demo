# M12 · Startbild mit echten Bedienelementen verbinden

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/start_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/start_page.dart)

**Aufgabe:** Zeigt die Startgrafik, dynamische Albumzahl und Statusleiste. Skaliert Bild, Texte und Trefferflächen gemeinsam und löst vier vom Elternwidget bereitgestellte Aktionen aus.

**Eingaben:** Albumanzahl, Sitzung-/Ladeflags, Aktualisierungszeit sowie vier Callbacks.

**Ausgaben:** Aufrufe von onSammlungOeffnen, onLaborOeffnen, onAktualisieren und onTidalStatus.

**Verbindungen:** Wird von HomePage konfiguriert. _StartAktion, _StartStatusLeiste und zwei CustomPainter bilden interne UI-Bausteine.

**Wichtige Namen:** StartPage, _StartAktion, _StartStatusLeiste, _StartTidalZeichen, _StartBibliothekZeichen

**Hinweis:** StartPage liest selbst weder SQLite noch die API. Sie zeigt den gelieferten Zustand und delegiert Aktionen zurück an HomePage.

**Diagramme:** [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [06 – Appstart: Cache und gespeicherte Sitzung](../SVG/06_Sequenz_Appstart.svg)
