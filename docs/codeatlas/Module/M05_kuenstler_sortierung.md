# M05 · Änderungen als Entwurf sammeln

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/models/kuenstler_sortierung.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/models/kuenstler_sortierung.dart)

**Aufgabe:** Verwaltet die Ausgangszeilen und noch ungespeicherte Sortiernamen. Erkennt tatsächliche Änderungen und hält Reihenfolge sowie Suchgrundlage während des Tippens stabil.

**Eingaben:** Iterable<KuenstlerSortierZeile>; Künstler-ID und Eingabetext; Suchtext.

**Ausgaben:** Gefilterte Zeilen, Änderungsanzahl und unveränderliche List<KuenstlerSortierAenderung>.

**Verbindungen:** Eigenständige Bibliothek ohne Imports von Flutter, SQLite oder TIDAL. Die Editor-Seite verwendet sie; eigene Unit-Tests prüfen die Logik.

**Wichtige Namen:** KuenstlerSortierZeile, KuenstlerSortierAenderung, KuenstlerSortierEntwurf; setzen(), filtern(), aenderungen

**Hinweis:** Rohtext bleibt beim Tippen erhalten. Erst der effektive Speicherwert wird getrimmt; ein leeres Feld fällt auf den ursprünglichen TIDAL-Namen zurück.

**Diagramme:** [04 – Künstlereditor: Eingabe, Entwurf und Speicherung](../SVG/04_Klassen_Kuenstlereditor.svg) · [11 – Sortiernamen gesammelt bearbeiten und speichern](../SVG/11_Sequenz_Kuenstlereditor.svg)
