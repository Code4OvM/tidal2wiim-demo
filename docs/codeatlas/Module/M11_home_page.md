# M11 · Appzustand und Abläufe koordinieren

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/home_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/home_page.dart)

**Aufgabe:** Das zentrale StatefulWidget HomePage und sein Zustand _HomePageState verwalten Startansicht, Labor und Sammlung. Sie koordinieren Login, Cache, API-Seiten, Hintergrundabgleich, Suche, Künstlerordner, Kategorien und Navigation zum Sortiernameneditor.

**Eingaben:** Optionale Test-Abhängigkeiten, Nutzeraktionen, Dienstmeldungen, API- und Datenbankergebnisse.

**Ausgaben:** Aktueller UI-Zustand; Daten und AuthService an Unterseiten; Callbacks zum Neuladen.

**Verbindungen:** Zentraler Auftraggeber für Datenbank, Auth, API und Covercache. Baut StartPage; öffnet Künstler-, Kategorie-, Album- und Editor-Seiten.

**Wichtige Namen:** HomePage, _HomePageState; _initialisieren(), _seiteLesen(), _albenLaden(), _bibliothekImHintergrundAktualisieren(), _kuenstlerSortiernamenOeffnen()

**Hinweis:** Die Aufteilung in Dateien trennt noch nicht sämtliche UI- und Fachlogik. Labor und Sammlung sind hier Widget-Methoden, keine eigenen Seitenklassen.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [06 – Appstart: Cache und gespeicherte Sitzung](../SVG/06_Sequenz_Appstart.svg) · [08 – Bibliothek laden: Vordergrund und Hintergrund](../SVG/08_Sequenz_Bibliothek.svg) · [09 – Von JSON-Ressourcen zu Album-Objekten](../SVG/09_Sequenz_Albumseite.svg) · [11 – Sortiernamen gesammelt bearbeiten und speichern](../SVG/11_Sequenz_Kuenstlereditor.svg)
