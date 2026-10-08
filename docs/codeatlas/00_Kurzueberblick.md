# Schnelle Orientierung

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

Die App ist ein digitales Plattenregal für TIDAL-Alben. Sie ergänzt die persönliche Ordnung nach Künstlern und Kategorien. Sie verarbeitet Metadaten und Cover; die Musik spielt anschließend die TIDAL-App ab.

## Jedes Modul in einem Satz

Die Kennungen M01 bis M19 sind im Handbuch, in den Einzelsteckbriefen und in der PDF gleich. Ein Modul meint hier eine eigene Dart-Datei. Das gesamte Projekt ist ein Dart-Paket; die fachlichen Ordner sind keine einzeln installierbaren Pakete.

| Modul / Datei | Aufgabe |
| --- | --- |
| [M01 - lib/main.dart](Module/M01_main.md) | Startet Flutter und setzt das App-Theme; öffnet HomePage. |
| [M02 - lib/core/hilfen.dart](Module/M02_hilfen.md) | Bündelt Hilfsfunktionen für Text, Namen, Suche und JSON. |
| [M03 - lib/core/sammlung.dart](Module/M03_sammlung.md) | Filtert und sortiert Alben; bildet Künstlerordner und den A-Z-Index. |
| [M04 - lib/models/modelle.dart](Module/M04_modelle.md) | Definiert die gemeinsamen Datenobjekte, etwa Album, Künstler und Kategorie. |
| [M05 - lib/models/kuenstler_sortierung.dart](Module/M05_kuenstler_sortierung.md) | Hält die noch ungespeicherten Sortiernamen als bearbeitbaren Entwurf. |
| [M06 - lib/data/lokale_datenbank.dart](Module/M06_lokale_datenbank.md) | Speichert und liest Metadaten, Kategorien und Künstlerpräferenzen in SQLite. |
| [M07 - lib/data/kuenstler_sortierung_speichern.dart](Module/M07_kuenstler_sortierung_speichern.md) | Schreibt mehrere geänderte Künstler-Sortiernamen in einer Transaktion. |
| [M08 - lib/services/tidal_auth_service.dart](Module/M08_tidal_auth_service.md) | Stellt die Sitzung wieder her, erneuert Tokens und kapselt den sicheren Store. |
| [M09 - lib/services/tidal_api.dart](Module/M09_tidal_api.md) | Liest TIDAL-JSON; behandelt Status, Cursor, Cover-URLs und Fehlermeldungen. |
| [M10 - lib/services/cover_cache.dart](Module/M10_cover_cache.md) | Lädt Cover und hält sie als lokale Bilddateien vor. |
| [M11 - lib/pages/home_page.dart](Module/M11_home_page.md) | Koordiniert Navigation, Login, Sammlung und den Hintergrundabgleich. |
| [M12 - lib/pages/start_page.dart](Module/M12_start_page.md) | Zeigt Startmotiv und Status; gibt Nutzeraktionen über Callbacks weiter. |
| [M13 - lib/pages/album_detail_page.dart](Module/M13_album_detail_page.md) | Zeigt Albumdetails, lädt Titel und verwaltet Kategoriezuordnungen. |
| [M14 - lib/pages/kuenstler_page.dart](Module/M14_kuenstler_page.md) | Zeigt die bereits aufbereiteten Alben eines Künstlerordners. |
| [M15 - lib/pages/kategorie_page.dart](Module/M15_kategorie_page.md) | Verbindet gespeicherte Kategorie-IDs mit den aktuell geladenen Alben. |
| [M16 - lib/pages/kuenstler_sortiernamen_page.dart](Module/M16_kuenstler_sortiernamen_page.md) | Zeigt den Künstlereditor mit Suche, Eingabefeldern und Speichern. |
| [M17 - lib/widgets/album_grid.dart](Module/M17_album_grid.md) | Zeigt ein wiederverwendbares Albumraster und öffnet Albumdetails. |
| [M18 - lib/widgets/album_cover.dart](Module/M18_album_cover.md) | Zeigt ein Cover aus dem Dateicache oder eine Ersatzanzeige. |
| [M19 - lib/widgets/dialoge.dart](Module/M19_dialoge.md) | Sammelt Dialogeingaben und gibt Ergebnisse an die aufrufende Seite zurück. |

## Daten folgen unterschiedlichen Wegen

HomePage koordiniert die Abläufe. Seiten erhalten Objekte und Dienste über Konstruktoren. Sie geben Nutzeraktionen oder Änderungen über Callbacks und Navigator-Ergebnisse zurück. Asynchrone Ergebnisse werden mit Future und await verarbeitet.

| Daten | Weg / Ort | Warum getrennt? |
| --- | --- | --- |
| Album-Metadaten | TIDAL-JSON → Albumobjekte → SQLite-Cache | Bereits geladene Alben sind beim nächsten Start schnell vorhanden. |
| Eigene Ordnung | Dialog/Editor → Ergebnisobjekte → SQLite | Kategorien und Sortiernamen bleiben lokal erhalten. |
| Coverbilder | HTTPS-Bildabruf → Dateien → AlbumCover | Bildbytes gehören zum Dateicache, nicht zu den SQL-Tabellen. |
| Anmeldung | Auth-Dienst ↔ sicherer Sitzungsspeicher | Tokens werden getrennt von Metadaten und Bildern gespeichert. |
| Wiedergabe | Album-/Titellink → externer Handler/TIDAL-App | Die App übergibt eine Inhalts-ID; sie streamt selbst keine Musik. |

## Drei passende Einstiege in die Modelle

1. [Komponentenmodell 01](SVG/01_Komponenten.svg): Aufgaben, Datenwege und Systemgrenzen im Überblick.
2. [Klassenmodell 04](SVG/04_Klassen_Kuenstlereditor.svg): Wie Editor, Entwurf, Änderungsliste und Speicherung zusammenhängen.
3. [Sequenzmodell 11](SVG/11_Sequenz_Kuenstlereditor.svg): Eingeben → Änderungsliste bilden → gemeinsam speichern → Ansicht neu laden.

Für den Appstart folgt Modell 06, für den vollständigen Bibliotheksabgleich Modell 08 und für Covermodell 13. Das Handbuch verlinkt bei jedem Modul die passenden Diagramme.
