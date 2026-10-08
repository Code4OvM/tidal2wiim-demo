# M07 · Sortiernamen gemeinsam in SQLite schreiben

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/data/kuenstler_sortierung_speichern.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/data/kuenstler_sortierung_speichern.dart)

**Aufgabe:** Ergänzt LokaleDatenbank um die Sammelspeicherung. Prüft IDs vorab und führt alle Änderungen in einer Transaktion aus. Verändert vorhandene eigene Anzeigenamen nicht.

**Eingaben:** List<KuenstlerSortierAenderung> aus dem Entwurf.

**Ausgaben:** Future<void>; bei Fehlern Exception und Rollback statt eines halben Änderungsstands.

**Verbindungen:** HomePage bindet die Extension-Methode als onSpeichern-Callback an die Editor-Seite. Geschrieben wird artist_preferences.

**Wichtige Namen:** extension KuenstlerSortierungSpeichern on LokaleDatenbank; kuenstlerSortiernamenSpeichern()

**Hinweis:** Eine Extension ist keine Unterklasse. Beim Zurücksetzen wird ein Präferenzsatz nur gelöscht, wenn kein eigener Anzeigename erhalten werden muss.

**Diagramme:** [04 – Künstlereditor: Eingabe, Entwurf und Speicherung](../SVG/04_Klassen_Kuenstlereditor.svg) · [11 – Sortiernamen gesammelt bearbeiten und speichern](../SVG/11_Sequenz_Kuenstlereditor.svg)
