# Excel-Export – Tidal2WiiM 1.1.0

## Zweck und Motivation

Die App dient als persönliches digitales Plattenregal für eine TIDAL-Sammlung. Genre-Vorschläge sollen nicht automatisch und ungeprüft innerhalb der App zugeordnet werden. Stattdessen exportiert Tidal2WiiM die gespeicherte Albensammlung in ein offenes, außerhalb der App bearbeitbares Tabellenformat. Diese Trennung hält die Anwendung schlank, ermöglicht externe Analyse (auch mit KI-Unterstützung) und belässt die endgültige Kategorienentscheidung beim Nutzer.

## Funktion

- Einstieg: Startseite → Einstellungen/Labor → **Alben als Excel-Liste exportieren**.
- Export der **gesamten lokal gespeicherten Bibliothek**, unabhängig von Suchfiltern.
- **Eine Zeile pro TIDAL-Album-ID**; mehrere Künstler und Kategorien werden in einer Zelle aufgelistet.
- Albumname, Künstler, Erscheinungsdatum, Audioqualitätskennzeichnungen (sofern verfügbar), Kategorien, TIDAL-Link, Album-ID.
- Optionale zusätzliche Leseabfrage bei TIDAL für Version und Qualitätskennzeichnungen. Fehlen Daten oder scheitert eine Anfrage, werden Werte nicht erfunden; die Alben verbleiben im Export.
- Drei vorbereitete **leere** Arbeitsfelder: Genre-Vorschläge (1–3), Sicherheit der Zuordnung (hoch/mittel/unklar) und Anmerkung.
- Formatierte XLSX-Arbeitsmappe mit Filter, fixierten Überschriften und Hinweisen; Speichern über Android-Dateidialog.
- Die Exportfunktion verändert **weder SQLite-Daten noch Kategorien**. Kein Excel-Import, keine automatische Genre-Zuordnung und keine eingebettete KI.

## Nutzung zur Genre-Einordnung

Nach dem Export lässt sich die Tabelle auf einem PC oder mit externen Hilfsmitteln analysieren. Vorschläge und Begründungen können überprüft, korrigiert oder verworfen werden. Nur vom Nutzer ausgewählte Begriffe werden später manuell als Kategorien in Tidal2WiiM angelegt und zugeordnet.

## Praxistest vom 12.10.2026

Ein praktischer Export von **510 Album-IDs** ergab genau **510 Datenzeilen**. Zwei Einträge ohne auflösbare TIDAL-Metadaten wurden mit ID und Link transparent erhalten. Der Funktionstest erfolgte auf dem Android-Tablet. Automatisierte Flutter-Tests und `flutter analyze` liefen beim Anwender erfolgreich.

## Versionsstand

`v1.1.0` / Flutter-Buildnummer `+2`. Die Abhängigkeiten für den Export sind `archive 4.3.0` und `file_picker 13.1.0`. Die bestehende sichere Speicherung der Anmeldung mit `flutter_secure_storage 11.2.0` bleibt unverändert.
