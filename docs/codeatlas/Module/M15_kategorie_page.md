# M15 · Gespeicherte Zuordnung mit geladenen Alben verbinden

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/kategorie_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kategorie_page.dart)

**Aufgabe:** Liest die Kategorie samt Album-IDs und filtert die übergebene Albumliste. Zeigt sowohl sichtbare Alben als auch die Zahl gespeicherter Zuordnungen.

**Eingaben:** Kategorie-ID/-Name, alle aktuell geladenen Alben, AuthService und Callbacks.

**Ausgaben:** Nach Jahr und Titel sortierte List<Album> für AlbumGrid; Aktualisierung nach Kategorieänderungen.

**Verbindungen:** Nutzt LokaleDatenbank.kategorienLaden(); AlbumGrid öffnet Details. Der Callback lädt zunächst diese Seite und danach die Elternansicht neu.

**Wichtige Namen:** KategoriePage, _KategoriePageState; _neuLaden()

**Hinweis:** Eine gespeicherte Album-ID muss nicht mehr im aktuellen Cache liegen. Deshalb können Gesamtzahl und sichtbare Anzahl voneinander abweichen.

**Diagramme:** [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [12 – Ein Album mehreren Kategorien zuordnen](../SVG/12_Sequenz_Kategorien.svg)
