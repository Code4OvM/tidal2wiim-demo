# Vollständiges Klassenverzeichnis

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

46 Klassen-/Interface-Deklarationen in lib/. Framework-Klassen und MemorySessionStore (nur Tests) sind hier nicht mitgezählt.

| Name | Datei | Aufgabe |
| --- | --- | --- |
| LokaleDatenbank | lib/data/lokale_datenbank.dart | SQLite-Zugriffe und Schema 3. |
| Tidal2WiiMApp | lib/main.dart | Wurzelwidget, Theme und HomePage. |
| KuenstlerSortierZeile | lib/models/kuenstler_sortierung.dart | Unveränderte Ausgangsdaten einer Editorzeile. |
| KuenstlerSortierAenderung | lib/models/kuenstler_sortierung.dart | Datenträger für eine bestätigte Sortieränderung. |
| KuenstlerSortierEntwurf | lib/models/kuenstler_sortierung.dart | Arbeitsspeicher für Eingaben, Filter und Änderungserkennung. |
| KuenstlerEinstellung | lib/models/modelle.dart | Eigener Anzeigename und lokaler Sortiername. |
| Kategorie | lib/models/modelle.dart | Kategorie-ID, Name und Menge von Album-IDs. |
| Kuenstler | lib/models/modelle.dart | TIDAL-Künstler-ID und Name. |
| Album | lib/models/modelle.dart | Album-Metadaten und beteiligte Künstler. |
| LokaleBibliothekCache | lib/models/modelle.dart | Geladene Albumliste mit Speicherzeit. |
| AlbumTitel | lib/models/modelle.dart | Ein Track oder Video im Zustand der Detailseite. |
| KuenstlerOrdner | lib/models/modelle.dart | Aus Alben abgeleitete Künstleransicht. |
| AlbumSeite | lib/models/modelle.dart | Ergebnis einer API-Sammlungsseite mit Folgekursor. |
| AlbumDetailPage | lib/pages/album_detail_page.dart | Konfiguration für ein ausgewähltes Album. |
| _AlbumDetailPageState | lib/pages/album_detail_page.dart | Titelliste, Kategorien und externe Übergabe. |
| HomePage | lib/pages/home_page.dart | Konfiguration der Hauptseite und optionale Test-Abhängigkeiten. |
| _HomePageState | lib/pages/home_page.dart | Zentrale Koordination von Zustand, Datenladen und Navigation. |
| KategoriePage | lib/pages/kategorie_page.dart | Konfiguration einer Kategorieansicht. |
| _KategoriePageState | lib/pages/kategorie_page.dart | Kategorie lesen, aktuelle Albumobjekte filtern, Anzeige erneuern. |
| KuenstlerPage | lib/pages/kuenstler_page.dart | Künstlerüberschrift und gemeinsames Albumraster. |
| KuenstlerSortiernamenPage | lib/pages/kuenstler_sortiernamen_page.dart | Konfiguration des Editors und Speicher-Callback. |
| _KuenstlerSortiernamenPageState | lib/pages/kuenstler_sortiernamen_page.dart | Entwurf, Eingabefelder, Fokus und Abbruch-/Speicherablauf. |
| StartPage | lib/pages/start_page.dart | Startmotiv und vom Elternwidget gelieferte Statusdaten. |
| _StartAktion | lib/pages/start_page.dart | Beschriftete, tatsächlich antippbare Trefferfläche. |
| _StartStatusLeiste | lib/pages/start_page.dart | Album-/TIDAL-Status und Aktualisierungsaktion. |
| _StartTidalZeichen | lib/pages/start_page.dart | Zeichnet das Statussymbol als CustomPainter. |
| _StartBibliothekZeichen | lib/pages/start_page.dart | Zeichnet das Bibliothekssymbol als CustomPainter. |
| LokalerCoverCache | lib/services/cover_cache.dart | Dateisuche, Download, Vorladen und Bereinigung der Cover. |
| ApiFehler | lib/services/tidal_api.dart | HTTP-Status und API-Pfad als Fehlerobjekt. |
| TidalSessionStore | lib/services/tidal_auth_service.dart | Interface zum Lesen/Schreiben des Session-Pakets. |
| SecureTidalSessionStore | lib/services/tidal_auth_service.dart | Produktiver Store auf Basis von flutter_secure_storage. |
| TidalSession | lib/services/tidal_auth_service.dart | Token-Satz und Ablaufzeit. |
| TidalSignInRequired | lib/services/tidal_auth_service.dart | Eine neue Anmeldung ist erforderlich. |
| TidalAuthUnavailable | lib/services/tidal_auth_service.dart | Vorübergehender Zugangsfehler ohne automatisches Verwerfen der Sitzung. |
| TidalSessionChanged | lib/services/tidal_auth_service.dart | Ein laufender Vorgang gehört nicht mehr zur aktuellen Sitzung. |
| TidalAuthService | lib/services/tidal_auth_service.dart | Gemeinsame Sitzung, Token-Erneuerung, gesicherte API-GETs. |
| AlbumCover | lib/widgets/album_cover.dart | Konfiguration der Coveranzeige für ein Album. |
| _AlbumCoverState | lib/widgets/album_cover.dart | Datei-Future, Ladeanzeige und Bild-Fallback. |
| AlbumGrid | lib/widgets/album_grid.dart | Gemeinsames Raster für Künstler-/Kategorie-Unterseiten. |
| _KategorieNameDialog | lib/widgets/dialoge.dart | Konfiguration des Kategorienamen-Dialogs. |
| _KategorieNameDialogState | lib/widgets/dialoge.dart | Textcontroller, Pflichtfeldprüfung und Namensrückgabe. |
| _KuenstlerDialogErgebnis | lib/widgets/dialoge.dart | Einstellung oder ausdrücklicher Zurücksetzen-Wunsch. |
| _KuenstlerBearbeitenDialog | lib/widgets/dialoge.dart | Konfiguration der einzelnen Künstleranpassung. |
| _KuenstlerBearbeitenDialogState | lib/widgets/dialoge.dart | Controller für Anzeige-/Sortiername und Ergebnisrückgabe. |
| _AlbumKategorienDialog | lib/widgets/dialoge.dart | Konfiguration der Kategorieauswahl. |
| _AlbumKategorienDialogState | lib/widgets/dialoge.dart | Bearbeitet eine Kopie der ausgewählten IDs. |


Zusätzlich: eine Dart-Extension `KuenstlerSortierungSpeichern`, drei Enums `Sortierung`, `SammlungAnsicht`, `AppSeite` und das Typalias `Json`. Die Funktionen in core/ und tidal_api.dart sind keine weiteren Klassen.
