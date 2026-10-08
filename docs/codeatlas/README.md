# Tidal2WiiM - Codeatlas

[Dokumentationsübersicht](../README.md) · [Projektübersicht](../../README.md)

**Version vom 08.10.2026**

Der Codeatlas beschreibt die App vom Programmeinstieg über lokale Speicherung und TIDAL-Anbindung bis zum Künstlereditor. Er erläutert die Aufgaben der Module, ihre Verbindungen und den Datenaustausch.

## Dokumentierter Quellstand

Quellcode: `Code4OvM/tidal2wiim-demo`, Commit `851304ffd33e6ed9f65d74a29d146311e9a6265b`. Die Quellenlinks führen zu diesem festgehaltenen Stand.

## Inhalt und Einstieg

- [PDF-Lesefassung](Tidal2WiiM_Codeatlas_2026-10-08.pdf)
- [Schnelle Orientierung](00_Kurzueberblick.md)
- [Architektur und Leseführung](01_Architektur.md)
- [19 Modulsteckbriefe](02_Modulhandbuch.md), zusätzlich einzeln unter `Module/`
- [Datenaustausch und Speicherung](03_Datenaustausch.md)
- [14 PlantUML-Diagramme](04_Diagrammuebersicht.md)
- [Fremdpakete und Tests](05_Tests_und_Pruefhinweise.md)
- [Klassenverzeichnis](06_Klassenverzeichnis.md)

Die Diagramme liegen als PlantUML-Quellen, SVG und PNG vor. Die [vorhandenen ER-/Tabellenmodelle](../README.md#datenmodelle) bilden eine eigene Sicht; die Klassen- und Sequenzmodelle ergänzen sie um die Sicht auf den Programmcode.

## Module und Bibliotheken

Ein Modulsteckbrief beschreibt eine Dart-Datei unter `lib/`. Das Projekt ist ein Dart-Paket mit drei eigenen Bibliotheken: `main.dart` und 16 `part`-Dateien sowie die eigenständigen Bibliotheken `models/kuenstler_sortierung.dart` und `services/tidal_auth_service.dart`.

## Diagramme erneut erzeugen

Mit Java und einer vorhandenen `plantuml.jar`:

```powershell
.\Modelle_rendern.ps1 -PlantUmlJar "C:\Tools\plantuml\plantuml.jar"
```

Oder mit Python und Java:

```text
python Modelle_rendern.py /pfad/zu/plantuml.jar
```

Die Skripte schreiben nach `SVG/` und `PNG/`. Komponenten- und Klassenmodelle verwenden Smetana. Die vorliegenden Grafiken wurden lokal mit PlantUML 1.2025.10 erzeugt.

**Smetana** ist eine in PlantUML eingebaute Layout-Engine. Sie berechnet die Anordnung der Diagrammelemente und den Verlauf ihrer Verbindungslinien.
