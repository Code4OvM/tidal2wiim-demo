# M16 · Mehrere Sortiernamen bequem bearbeiten

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/kuenstler_sortiernamen_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kuenstler_sortiernamen_page.dart)

**Aufgabe:** Stellt Suche, Eingabefelder, Änderungszähler und Speichern bereit. Verwaltet Controller, Fokuswechsel und Schutz vor dem Verlassen mit ungespeicherten Änderungen.

**Eingaben:** List<KuenstlerSortierZeile> und onSpeichern-Callback.

**Ausgaben:** Änderungsliste an den Callback; Navigator-Ergebnis true nach erfolgreichem Speichern. Bei Abbruch kein true.

**Verbindungen:** HomePage liefert Zeilen und Speicherfunktion. KuenstlerSortierEntwurf hält die Fachlogik getrennt von Flutter.

**Wichtige Namen:** KuenstlerSortiernamenPage, _KuenstlerSortiernamenPageState; _speichern(), _verlassen(), _fokusVerschieben()

**Hinweis:** Bei einem Speicherfehler bleiben die Eingaben auf der Seite. Während des Speicherns sind Bearbeitung und unbeabsichtigtes Schließen gesperrt.

**Diagramme:** [04 – Künstlereditor: Eingabe, Entwurf und Speicherung](../SVG/04_Klassen_Kuenstlereditor.svg) · [11 – Sortiernamen gesammelt bearbeiten und speichern](../SVG/11_Sequenz_Kuenstlereditor.svg)
