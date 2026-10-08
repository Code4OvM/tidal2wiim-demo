# Dokumentation

[Projektübersicht](../README.md)

Die Dokumentation verbindet die Sicht auf den Programmcode mit den vorhandenen Datenmodellen. Die Diagramme liegen als lesbare Grafiken und als bearbeitbare PlantUML-Quellen vor.

## Codeatlas

Der [Codeatlas](codeatlas/README.md) beschreibt die 19 eigenen Dart-Module, ihre Aufgaben, Beziehungen und den Datenaustausch.

| Einstieg | Inhalt |
| --- | --- |
| [Schnelle Orientierung](codeatlas/00_Kurzueberblick.md) | Alle Module und die wichtigsten Datenwege im Überblick. |
| [Architektur und Leseführung](codeatlas/01_Architektur.md) | Bibliotheken, Zuständigkeiten und Verbindungen. |
| [Modulhandbuch](codeatlas/02_Modulhandbuch.md) | Beschreibungen aller 19 Module mit Quellcodeverweisen. |
| [Datenaustausch und Speicherung](codeatlas/03_Datenaustausch.md) | Datenverträge, SQLite, Dateicache und Sitzungsspeicher. |
| [Diagrammübersicht](codeatlas/04_Diagrammuebersicht.md) | Ein Komponentenmodell, vier Klassenmodelle und neun Sequenzmodelle. |
| [Codeatlas als PDF](codeatlas/Tidal2WiiM_Codeatlas_2026-10-08.pdf) | Zusammenhängende Lesefassung mit 38 Seiten. |

Ein einfacher Leseweg führt vom Überblick über die Architektur zu einem Modul und dem passenden Diagramm. Auf den einzelnen Modulseiten führen Links zurück zur Modulübersicht und direkt zu den zugehörigen Modellen.

## Datenmodelle

Die vorhandenen Datenmodelle ergänzen den Codeatlas um die Sicht auf Entitäten und Tabellen. Ihre Darstellungen bleiben als eigenständige Dokumentation erhalten.

| Modell | Leseansicht | Bearbeitbare Quelle |
| --- | --- | --- |
| ER-Modell in Chen-Notation | [SVG](datenmodell/Leseansichten/01_ER_Modell_Chen_Leseansicht.svg) | [PlantUML](datenmodell/PlantUML/01_ER_Modell_Chen.puml) |
| Relationales Tabellenmodell | [SVG](datenmodell/Leseansichten/02_Relationales_Tabellenmodell_Leseansicht.svg) | [PlantUML](datenmodell/PlantUML/02_Relationales_Tabellenmodell.puml) |

Beide Leseansichten sind außerdem in der [Datenmodelle-PDF](datenmodell/Tidal2WiiM_Datenmodelle_Leseansicht.pdf) zusammengefasst.
