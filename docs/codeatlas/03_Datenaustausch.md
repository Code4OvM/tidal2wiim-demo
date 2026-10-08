# Datenaustausch und Speicherung

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

## Datenverträge zwischen den Modulen

| Verbindung | Datentyp / Übergabe | Bedeutung |
| --- | --- | --- |
| API → _apiLesen() | HTTP-Response / UTF-8 JSON | HTTP 200 wird geprüft; Ergebnis ist Json = Map<String, dynamic>. |
| JSON → Album | Map<String, Json> nach type:id | Sammlungs-IDs werden mit Album-, Künstler- und Coverressourcen aufgelöst. |
| Seitenlader → Home | AlbumSeite | Enthält List<Album> und nächsten Sammlungs-Cursor, nicht die komplette Bibliothek. |
| SQLite → Home | LokaleBibliothekCache? | Albumliste und Speicherzeit; eine leere Tabelle ergibt null. |
| Home → Unterseite | Objekte und Referenzen | Album/Ordner/Listen plus dieselbe TidalAuthService-Instanz; kein kopierter Token. |
| Dialog → Aufrufer | String / Set<int> / Ergebnisobjekt | Navigator.pop liefert ein späteres Ergebnis; null bedeutet meist Abbruch. |
| Editor → Speicherfunktion | List<KuenstlerSortierAenderung> | Nur tatsächlich geänderte Künstler; nach Erfolg pop(true) an Home. |
| Detailseite → Elternansicht | Future<void> Function() | onKategorienGeaendert meldet die Änderung ohne Datensatzpayload; Eltern lesen erneut. |
| Auth → Home | ChangeNotifier | Listener liest Status-Getter neu und ruft setState; kein Ereignisbus für die ganze App. |
| Covercache → Widget | Future<File?> | Bildbytes bleiben im Dateisystem. null/Dateifehler führt zum Netz-Fallback. |
| App → TIDAL-App | HTTPS-URL | Nur Inhalts-ID im Link; weder OAuth-Token noch Musikdatei werden übergeben. |

## Vier Speicherformen

| Ort | Inhalt | Lebensdauer / Grenze |
| --- | --- | --- |
| Arbeitsspeicher | Alben, gefilterte Ansichten, geladene Titel, Editorentwurf | Geht beim Prozessende verloren; setState aktualisiert nur die Oberfläche. |
| SQLite / tidal2wiim.db | Kategorien, Albumzuordnungen, Künstlerpräferenzen, Metadatencache | Dauerhaft im App-Bereich. Schema 3; keine Audiostreams und keine Token. |
| Dateien / cover_cache | Heruntergeladene Cover als .img; vorläufig .tmp | Dateiname aus bereinigter Album-ID und stabilem URL-Hash; später erneut ladbar. |
| Sicherer Store | Version, clientId, Access-/Refresh-Token und Ablaufzeit als JSON | Gekapselt durch TidalSessionStore; nicht in SQLite oder Coverdateien. |

## SQLite ist nicht das Klassenmodell

`artist_preferences` speichert eigene Künstlernamen und Sortiernamen. `categories` enthält Kategorien. `category_albums` bildet Kategorie/Album-Paare ab. `album_cache` enthält Album-Metadaten, die Reihenfolge und Künstlerdaten als JSON.

Nur `category_albums.category_id → categories.id` ist ein SQL-Fremdschlüssel. Auf album_cache existiert kein solcher Fremdschlüssel. Ein vollständiger Cacheaustausch löscht deshalb keine Kategoriezuordnungen. Auch artist_preferences verweist nur logisch auf TIDAL-Künstler-IDs; eine eigene Künstler-Tabelle gibt es im Ist-Schema nicht.

Ein KuenstlerOrdner entsteht aus den aktuellen Albumobjekten. AlbumSeite und LokaleBibliothekCache sind Transportobjekte. AlbumTitel wird beim Öffnen einer Detailseite geladen und nicht in der lokalen Datenbank gespeichert. Die vorhandenen ER-/Tabellenmodelle bleiben eigenständige, unveränderte Darstellungen.

## Beispiel: ein neuer Sortiername

Aus Albumdaten und gespeicherten Einstellungen entstehen Editorzeilen. Die Eingabe „Wülker, Nils“ landet zunächst als Text im Entwurf. Beim Speichern entsteht ein KuenstlerSortierAenderung-Objekt mit Künstler-ID, TIDAL-Name und neuem Sortiernamen. Die Extension aktualisiert artist_preferences innerhalb einer Transaktion. Anschließend liest HomePage die Einstellungen erneut und berechnet Künstlerordner und A-Z-Index neu. Der TIDAL-Name und ein vorhandener eigener Anzeigename bleiben erhalten.

## Beispiel: ein aktualisiertes Album

Die Sammlung liefert zunächst die Album-ID. Weitere API-Aufrufe liefern Album-, Künstler- und Coverressourcen. Album.ausRessourcen() erzeugt das Fachobjekt. Nach vollständigem Hintergrundabgleich wird der gesamte Metadatencache atomar ersetzt. Erst danach wird die sichtbare Albumliste ausgetauscht. Das Cover wird getrennt als Datei geladen. Ein einzelner fehlerhafter Coverdownload macht den erfolgreich gespeicherten Albumdatensatz nicht ungültig.

## Systemgrenze der Wiedergabe

Album- und Titellinks enthalten eine Inhalts-ID. Sie enthalten keine Session-Tokens. Die Plattform entscheidet über den externen Handler; auf dem vorgesehenen Tablet ist dies die TIDAL-App. Dort muss die Wiedergabe gestartet werden. TIDAL Connect zum WiiM ist kein eigener Aufruf des hier untersuchten Codes.
