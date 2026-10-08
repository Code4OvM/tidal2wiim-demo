# Fremdpakete und Tests

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

## Direkte externe Pakete

Die angegebenen Paketversionen stammen aus dem pubspec.lock des dokumentierten Quellstands.

| Paket | Lockfile-Version | Aufgabe |
| --- | --- | --- |
| flutter | SDK | Widgets, MaterialApp, Navigator, setState, ChangeNotifier und Lebenszyklus. |
| flutter_appauth | 12.1.0 | Interaktive TIDAL-Anmeldung; liefert den ersten Token-Satz an HomePage. |
| http | 1.6.0 | OpenAPI-GET, Token-POST und Coverdownload; austauschbare Clients ermöglichen Tests. |
| sqflite | 2.4.4 | SQLite-Abfragen, Migrationen und Transaktionen auf dem Gerät. |
| path | 1.9.1 | Plattformgerechtes Verbinden von Datenbank- und Coverpfaden. |
| flutter_secure_storage | 11.2.0 | Sicherer Plattform-Speicher für das JSON-Tokenpaket. |
| url_launcher | 6.3.2 | Album-, Track- und Videolinks an eine externe Anwendung übergeben. |
| cupertino_icons | 1.0.9 | Im Projekt deklariert; im untersuchten lib-Code kein CupertinoIcons-Aufruf. |
| flutter_test | SDK | Unit-/Widget-Tests, WidgetTester und Flutter-Testumgebung. |
| flutter_lints | 6.0.0 | Statische Stil-/Analyse-Regeln über analysis_options.yaml; kein Laufzeitdienst. |
| flutter_launcher_icons | 0.14.4 | Entwicklungswerkzeug zum Erzeugen der App-Icons; kein Laufzeitdienst. |

Die Dart-SDK-Bibliotheken dart:async, dart:convert und dart:io liefern asynchrone Abläufe, JSON/UTF-8 sowie Dateizugriffe. Flutter stellt unter anderem material.dart, services.dart und foundation.dart bereit. Diese Imports sind keine weiteren selbst entwickelten Projektpakete.

## Konfiguration und Plattformordner

pubspec.yaml beschreibt Paket, Abhängigkeiten und Assets. pubspec.lock hält aufgelöste Versionen fest. analysis_options.yaml konfiguriert die statische Analyse. assets/ enthält Startbild und Icon. docs/datenmodell/ enthält die bereits vorhandenen Planungsmodelle.

android/ enthält die native Android-Einbettung, Gradle-Konfiguration, Manifest, OAuth-Rücksprung und Ressourcen. ios/, macos/, linux/ und web/ sind zusätzliche Plattformgerüste. Ihre Existenz belegt keine getestete Unterstützung dieser Plattformen. Das erklärte Zielgerät bleibt Android.

## Vorhandene Tests

| Datei | Schwerpunkt | Was sie prüfen / bereitstellen |
| --- | --- | --- |
| test/kuenstler_sortierung_test.dart | Entwurfslogik | Nur geänderte IDs, Leerwert-Rückfall, stabile Filter/Reihenfolge, getrennte IDs trotz gleicher Namen und ungültige Eingaben. |
| test/kuenstler_sortiernamen_page_test.dart | Editor-Oberfläche | Speichern/Abbrechen, Android-Zurück, Speicherfehler, erhaltene Eingaben, Tastaturfokus und verschiedene Bildschirm-/Textgrößen. |
| test/tidal_auth_service_test.dart | Sitzungsdienst | Wiederherstellung, Ablaufzeit, gemeinsamer Refresh, Netz-/Serverfehler, invalid_grant, Speicherwarnung und genau ein 401-Retry. |
| test/widget_test.dart | Start/Labor | Startaktionen und Trefferflächen, dynamische Statuswerte, Wiederherstellung/Anmeldung vergessen und Layoutvarianten. |
| test/support/memory_session_store.dart | Test-Doppel | MemorySessionStore speichert nur im RAM, zählt Schreibvorgänge und simuliert Schreibfehler; kein eigenständiger Testfall. |

Die Übersicht beschreibt die vorhandenen Testquellen. Ergebnisse einer erneuten Test- oder Build-Ausführung sind nicht Bestandteil dieser Dokumentation. Widget-Tests mit injizierten Daten oder Mock-Clients prüfen isolierte Abläufe; eine reale API-, SQLite- oder Tablet-Integration erfordert zusätzliche Integrationstests.

Für SQLite-Transaktionen und den Covercache liegt im untersuchten test/-Ordner kein eigener direkter Integrationstest vor. Ein kompletter Ende-zu-Ende-Nachweis mit TIDAL und WiiM wäre eine zusätzliche Prüfung.
