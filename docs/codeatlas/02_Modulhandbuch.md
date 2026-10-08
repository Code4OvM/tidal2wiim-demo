# Modulhandbuch

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

19 eigene Dart-Dateien, jeweils mit demselben Steckbriefschema.

## M01 · App starten und Dateien verbinden

**Quellcode:** [lib/main.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/main.dart)

**Aufgabe:** Startet Flutter mit Tidal2WiiMApp. Baut MaterialApp, dunkles Theme und HomePage auf. Verbindet 16 part-Dateien zu einer gemeinsamen Dart-Bibliothek und importiert zwei weitere eigene Bibliotheken.

**Eingaben:** Optional: bibliothekLaden-Callback und TidalAuthService für isolierte Tests.

**Ausgaben:** Widget-Baum mit HomePage; selbst keine Albumdaten oder SQL-Abfragen.

**Verbindungen:** Bindet alle part-Dateien ein; importiert models/kuenstler_sortierung.dart und services/tidal_auth_service.dart.

**Wichtige Namen:** main(), Tidal2WiiMApp.build()

**Hinweis:** Die Ordner sind fachliche Bereiche. Technisch ist tidal2wiim ein Dart-Paket mit drei eigenen Bibliotheken.

**Diagramme:** 01, 05, 06

---

## M02 · JSON, Suchtext und Zeitdauer aufbereiten

**Quellcode:** [lib/core/hilfen.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/core/hilfen.dart)

**Aufgabe:** Stellt kleine Hilfsfunktionen ohne eigenen Zustand bereit. Prüft JSON-Strukturen, bereinigt Texte und wandelt **Zeitspannen im standardisierten Format nach ISO 8601** – hier beispielsweise die Spieldauer eines Musiktitels – für die Titelanzeige um.

**Eingaben:** Object?, JSON-Werte, Suchtext oder Duration?.

**Ausgaben:** Json, List<Json>, String?, normalisierte Suchtexte sowie Duration? und Anzeigetexte.

**Datentypen:** `String?` bezeichnet Text oder `null`. `Duration?` bezeichnet eine Zeitdauer oder `null`. Das `?` erlaubt jeweils einen fehlenden Wert.

**Verbindungen:** Wird von Modellen, API-Auswertung, Sammlung und Albumdetailseite benutzt. Kein direkter Netz- oder Datenbankzugriff.

**Wichtige Namen:** Json, _objekt(), _optionalObjekt(), _liste(), _text(), _vergleichstext(), _dauerLesen(), _dauerAnzeige()

**Hinweis:** Ein fehlender optionaler Wert darf null bleiben. Eine falsche Pflichtstruktur wird dagegen als FormatException gemeldet.

**Diagramme:** 09, 14

---

## M03 · Ansichten aus vorhandenen Alben ableiten

**Quellcode:** [lib/core/sammlung.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/core/sammlung.dart)

**Aufgabe:** Filtert und sortiert Alben, bildet Künstlerordner und berechnet den A-Z-Sprungindex. Definiert die Auswahlwerte für Appseite, Sammlungsansicht und Sortierung.

**Eingaben:** List<Album>, Suchtext, Sortierung und Map<String, KuenstlerEinstellung>.

**Ausgaben:** Gefilterte Albumliste, List<KuenstlerOrdner> oder Map<String, int> als Buchstabenindex.

**Verbindungen:** HomePage ruft die Funktionen beim Aufbau der Sammlung auf. Benutzt Fachmodelle und Texthelfer.

**Wichtige Namen:** Sortierung, SammlungAnsicht, AppSeite, _ansichtErstellen(), _kuenstlerOrdnerErstellen(), _kuenstlerAlphabetIndex()

**Hinweis:** Künstlerordner entstehen im RAM. Mehrere Künstler eines Albums führen zu mehreren Ordnerzuordnungen. Die Albumsortierung verwendet TIDAL-Künstlernamen; eigene Sortiernamen steuern die Künstlerordner.

**Diagramme:** 01, 02

---

## M04 · Gemeinsame Datenobjekte beschreiben

**Quellcode:** [lib/models/modelle.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/models/modelle.dart)

**Aufgabe:** Definiert acht Fach- und Transportmodelle für Album, Künstler, Kategorie, Einstellungen, Titel, Ordner, API-Seite und lokalen Cache. Album.ausRessourcen() setzt API-Ressourcen zu einem Album zusammen.

**Eingaben:** Konstruktorwerte; Ressourcenindex nach type:id; SQLite-Map für KuenstlerEinstellung.

**Ausgaben:** Typisierte Dart-Objekte; abgeleitete Werte wie Jahr, Anzeigename und Albumanzahl.

**Verbindungen:** Gemeinsame Sprache von HomePage, Detailseiten, SQLite, Sammlung und Coveranzeige.

**Wichtige Namen:** Album, Kuenstler, Kategorie, KuenstlerEinstellung, KuenstlerOrdner, AlbumTitel, AlbumSeite, LokaleBibliothekCache

**Hinweis:** Kategorie hält Album-IDs. Album enthält Künstler, aber keine Titelliste. Ein final-Feld macht eine darin referenzierte Liste nicht automatisch unveränderlich.

**Diagramme:** 02, 09

---

## M05 · Änderungen als Entwurf sammeln

**Quellcode:** [lib/models/kuenstler_sortierung.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/models/kuenstler_sortierung.dart)

**Aufgabe:** Verwaltet die Ausgangszeilen und noch ungespeicherte Sortiernamen. Erkennt tatsächliche Änderungen und hält Reihenfolge sowie Suchgrundlage während des Tippens stabil.

**Eingaben:** Iterable<KuenstlerSortierZeile>; Künstler-ID und Eingabetext; Suchtext.

**Ausgaben:** Gefilterte Zeilen, Änderungsanzahl und unveränderliche List<KuenstlerSortierAenderung>.

**Verbindungen:** Eigenständige Bibliothek ohne Imports von Flutter, SQLite oder TIDAL. Die Editor-Seite verwendet sie; eigene Unit-Tests prüfen die Logik.

**Wichtige Namen:** KuenstlerSortierZeile, KuenstlerSortierAenderung, KuenstlerSortierEntwurf; setzen(), filtern(), aenderungen

**Hinweis:** Rohtext bleibt beim Tippen erhalten. Erst der effektive Speicherwert wird getrimmt; ein leeres Feld fällt auf den ursprünglichen TIDAL-Namen zurück.

**Diagramme:** 04, 11

---

## M06 · Strukturierte Daten lokal speichern

**Quellcode:** [lib/data/lokale_datenbank.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/data/lokale_datenbank.dart)

**Aufgabe:** Öffnet tidal2wiim.db mit Schema 3 und aktiviert Fremdschlüssel. Kapselt Cache, Künstlerpräferenzen, Kategorien und Albumzuordnungen; übernimmt Migrationen und Transaktionen.

**Eingaben:** Albumlisten mit Zeitstempel, KuenstlerEinstellung, Kategorienamen sowie Album- und Kategorie-IDs.

**Ausgaben:** Future<LokaleBibliothekCache?>, Einstellungs-Map, Kategorienlisten, ID-Mengen oder Future<void>.

**Verbindungen:** HomePage, KategoriePage und AlbumDetailPage nutzen LokaleDatenbank.instance. sqflite führt SQL aus; path bildet den Dateipfad.

**Wichtige Namen:** LokaleDatenbank, albumCacheLaden(), albumCacheSpeichern(), kategorienLaden(), albumKategorienSetzen()

**Hinweis:** Cacheaustausch und Zuordnungswechsel sind atomar. Nur category_albums.category_id ist ein SQL-Fremdschlüssel; Künstlerdaten liegen im Cache als JSON vor.

**Diagramme:** 01, 08, 12

---

## M07 · Sortiernamen gemeinsam in SQLite schreiben

**Quellcode:** [lib/data/kuenstler_sortierung_speichern.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/data/kuenstler_sortierung_speichern.dart)

**Aufgabe:** Ergänzt LokaleDatenbank um die Sammelspeicherung. Prüft IDs vorab und führt alle Änderungen in einer Transaktion aus. Verändert vorhandene eigene Anzeigenamen nicht.

**Eingaben:** List<KuenstlerSortierAenderung> aus dem Entwurf.

**Ausgaben:** Future<void>; bei Fehlern Exception und Rollback statt eines halben Änderungsstands.

**Verbindungen:** HomePage bindet die Extension-Methode als onSpeichern-Callback an die Editor-Seite. Geschrieben wird artist_preferences.

**Wichtige Namen:** extension KuenstlerSortierungSpeichern on LokaleDatenbank; kuenstlerSortiernamenSpeichern()

**Hinweis:** Eine Extension ist keine Unterklasse. Beim Zurücksetzen wird ein Präferenzsatz nur gelöscht, wenn kein eigener Anzeigename erhalten werden muss.

**Diagramme:** 04, 11

---

## M08 · Anmeldung und Token-Lebenszyklus verwalten

**Quellcode:** [lib/services/tidal_auth_service.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/tidal_auth_service.dart)

**Aufgabe:** Stellt die gemeinsame Sitzung wieder her, speichert Login-Ergebnisse und erneuert Tokens bei Bedarf. Schützt vor mehrfachen parallelen Refreshs und Ergebnissen einer inzwischen ersetzten Sitzung.

**Eingaben:** clientId, optionale Store-/Client-/Uhr-Abhängigkeiten; TidalSession beim Login; HTTPS-URI und HTTP-Client beim Lesen.

**Ausgaben:** Future<String> für ein Token, Future<Response> für API-GET, Status-Getter und ChangeNotifier-Benachrichtigungen.

**Verbindungen:** HomePage besitzt oder erhält den Dienst und gibt dieselbe Referenz an Unterseiten weiter. SecureTidalSessionStore verwendet flutter_secure_storage.

**Wichtige Namen:** TidalAuthService, TidalSession, TidalSessionStore, SecureTidalSessionStore; restore(), acceptLogin(), accessToken(), get(), forget()

**Hinweis:** HTTP 401 führt höchstens zu einem zweiten API-GET. Temporäre Netzfehler erhalten die Sitzung. storageWarning weist auf Probleme beim Lesen, Speichern oder Entfernen der sicheren Sitzung hin.

**Diagramme:** 03, 06, 07, 10

---

## M09 · API-Aufrufe vereinheitlichen und JSON lesen

**Quellcode:** [lib/services/tidal_api.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/tidal_api.dart)

**Aufgabe:** Baut OpenAPI-URLs, ruft den Auth-Dienst auf, prüft HTTP 200 und decodiert JSON. Liest Folgekursor, wählt eine passende Cover-URL und übersetzt Fehler in verständliche Hinweise.

**Eingaben:** http.Client, gemeinsamer TidalAuthService, Pfadsegmente und Queryparameter; JSON-Ressourcen für Cover und Cursor.

**Ausgaben:** Future<Json>, String? für Cursor/Cover-URL oder ApiFehler.

**Verbindungen:** HomePage und AlbumDetailPage nutzen _apiLesen(). Album.ausRessourcen() nutzt _coverUrlLesen().

**Wichtige Namen:** _apiLesen(), _cursorLesen(), _coverUrlLesen(), _fehlerText(), ApiFehler

**Hinweis:** Die Datei ist überwiegend eine Funktionssammlung, keine TidalApi-Klasse. Jeder Aufruf wartet vor der Anfrage 300 ms; das ist kein vollständiger automatischer 429-Retry.

**Diagramme:** 01, 09, 10

---

## M10 · Albumcover als Dateien zwischenspeichern

**Quellcode:** [lib/services/cover_cache.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/cover_cache.dart)

**Aufgabe:** Findet oder lädt Coverdateien im lokalen cover_cache-Verzeichnis. Bündelt laufende Downloads für denselben Zielpfad, schreibt zunächst .tmp und räumt beim Abgleich überholte Dateien auf.

**Eingaben:** Album mit ID und Cover-URL oder List<Album> zum Vorladen; optionaler HTTP-Client.

**Ausgaben:** Future<File?> für ein Cover oder Future<void> nach synchronisieren().

**Verbindungen:** AlbumCover fragt einzelne Dateien an. HomePage startet das Vorladen nach Cacheübernahme oder vollständiger Aktualisierung.

**Wichtige Namen:** LokalerCoverCache.instance, dateiFuer(), synchronisieren(), _herunterladen()

**Hinweis:** Bis zu vier Worker gelten für synchronisieren(), nicht als globale Grenze aller Einzelabrufe. Bildbytes liegen im Dateisystem und nie als BLOB in SQLite.

**Diagramme:** 01, 06, 13

---

## M11 · Appzustand und Abläufe koordinieren

**Quellcode:** [lib/pages/home_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/home_page.dart)

**Aufgabe:** Das zentrale StatefulWidget HomePage und sein Zustand _HomePageState verwalten Startansicht, Labor und Sammlung. Sie koordinieren Login, Cache, API-Seiten, Hintergrundabgleich, Suche, Künstlerordner, Kategorien und Navigation zum Sortiernameneditor.

**Eingaben:** Optionale Test-Abhängigkeiten, Nutzeraktionen, Dienstmeldungen, API- und Datenbankergebnisse.

**Ausgaben:** Aktueller UI-Zustand; Daten und AuthService an Unterseiten; Callbacks zum Neuladen.

**Verbindungen:** Zentraler Auftraggeber für Datenbank, Auth, API und Covercache. Baut StartPage; öffnet Künstler-, Kategorie-, Album- und Editor-Seiten.

**Wichtige Namen:** HomePage, _HomePageState; _initialisieren(), _seiteLesen(), _albenLaden(), _bibliothekImHintergrundAktualisieren(), _kuenstlerSortiernamenOeffnen()

**Hinweis:** Die Aufteilung in Dateien trennt noch nicht sämtliche UI- und Fachlogik. Labor und Sammlung sind hier Widget-Methoden, keine eigenen Seitenklassen.

**Diagramme:** 01, 05, 06, 08, 09, 11

---

## M12 · Startbild mit echten Bedienelementen verbinden

**Quellcode:** [lib/pages/start_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/start_page.dart)

**Aufgabe:** Zeigt die Startgrafik, dynamische Albumzahl und Statusleiste. Skaliert Bild, Texte und Trefferflächen gemeinsam und löst vier vom Elternwidget bereitgestellte Aktionen aus.

**Eingaben:** Albumanzahl, Sitzung-/Ladeflags, Aktualisierungszeit sowie vier Callbacks.

**Ausgaben:** Aufrufe von onSammlungOeffnen, onLaborOeffnen, onAktualisieren und onTidalStatus.

**Verbindungen:** Wird von HomePage konfiguriert. _StartAktion, _StartStatusLeiste und zwei CustomPainter bilden interne UI-Bausteine.

**Wichtige Namen:** StartPage, _StartAktion, _StartStatusLeiste, _StartTidalZeichen, _StartBibliothekZeichen

**Hinweis:** StartPage liest selbst weder SQLite noch die API. Sie zeigt den gelieferten Zustand und delegiert Aktionen zurück an HomePage.

**Diagramme:** 05, 06

---

## M13 · Album, Titel und lokale Zuordnungen anzeigen

**Quellcode:** [lib/pages/album_detail_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/album_detail_page.dart)

**Aufgabe:** Lädt die Titelliste aus TIDAL und Kategorien aus SQLite unabhängig voneinander. Ermöglicht Kategoriezuordnung und öffnet Album-, Track- oder Videolinks extern.

**Eingaben:** Album, gemeinsamer AuthService, **optionaler Ländercode des TIDAL-Kontos, beispielsweise DE für Deutschland** sowie Callbacks für Anmeldung und Kategorieänderungen.

**Ausgaben:** List<AlbumTitel> im Seitenzustand, lokale Kategorieauswahl und externe URLs; Rückmeldung nach gespeicherter Zuordnung.

**Verbindungen:** Aufruf durch HomePage oder AlbumGrid; nutzt _apiLesen(), LokaleDatenbank, AlbumCover und Dialoge.

**Wichtige Namen:** AlbumDetailPage, _AlbumDetailPageState; _titelLaden(), _kategorienBearbeiten(), _inTidalOeffnen(), _titelInTidalOeffnen()

**Hinweis:** Die Titelliste wird nicht dauerhaft gecacht. launchUrl() startet einen externen Handler; Play und WiiM-Auswahl erfolgen anschließend außerhalb unserer App.

**Diagramme:** 05, 12, 14

---

## M14 · Alben eines Künstlerordners darstellen

**Quellcode:** [lib/pages/kuenstler_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kuenstler_page.dart)

**Aufgabe:** Ist eine kleine, zustandslose Hülle: Zeigt den Anzeigenamen als Seitentitel und übergibt die zugehörigen Alben an AlbumGrid.

**Eingaben:** KuenstlerOrdner, AuthService, **optionaler Ländercode des TIDAL-Kontos, beispielsweise DE für Deutschland** und Änderungs-/Anmelde-Callbacks.

**Ausgaben:** Widget-Baum aus AppBar und AlbumGrid.

**Verbindungen:** HomePage erstellt den Ordner zuvor mit _kuenstlerOrdnerErstellen(). AlbumGrid übernimmt die Detailnavigation.

**Wichtige Namen:** KuenstlerPage.build()

**Hinweis:** Die Seite legt keine Ordner an und fragt keine Künstlerdaten nach. Sie erhält bereits aufbereitete Objekte.

**Diagramme:** 02, 05

---

## M15 · Gespeicherte Zuordnung mit geladenen Alben verbinden

**Quellcode:** [lib/pages/kategorie_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kategorie_page.dart)

**Aufgabe:** Liest die Kategorie samt Album-IDs und filtert die übergebene Albumliste. Zeigt sowohl sichtbare Alben als auch die Zahl gespeicherter Zuordnungen.

**Eingaben:** Kategorie-ID/-Name, alle aktuell geladenen Alben, AuthService und Callbacks.

**Ausgaben:** Nach Jahr und Titel sortierte List<Album> für AlbumGrid; Aktualisierung nach Kategorieänderungen.

**Verbindungen:** Nutzt LokaleDatenbank.kategorienLaden(); AlbumGrid öffnet Details. Der Callback lädt zunächst diese Seite und danach die Elternansicht neu.

**Wichtige Namen:** KategoriePage, _KategoriePageState; _neuLaden()

**Hinweis:** Eine gespeicherte Album-ID muss nicht mehr im aktuellen Cache liegen. Deshalb können Gesamtzahl und sichtbare Anzahl voneinander abweichen.

**Diagramme:** 05, 12

---

## M16 · Mehrere Sortiernamen bequem bearbeiten

**Quellcode:** [lib/pages/kuenstler_sortiernamen_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kuenstler_sortiernamen_page.dart)

**Aufgabe:** Stellt Suche, Eingabefelder, Änderungszähler und Speichern bereit. Verwaltet Controller, Fokuswechsel und Schutz vor dem Verlassen mit ungespeicherten Änderungen.

**Eingaben:** List<KuenstlerSortierZeile> und onSpeichern-Callback.

**Ausgaben:** Änderungsliste an den Callback; Navigator-Ergebnis true nach erfolgreichem Speichern. Bei Abbruch kein true.

**Verbindungen:** HomePage liefert Zeilen und Speicherfunktion. KuenstlerSortierEntwurf hält die Fachlogik getrennt von Flutter.

**Wichtige Namen:** KuenstlerSortiernamenPage, _KuenstlerSortiernamenPageState; _speichern(), _verlassen(), _fokusVerschieben()

**Hinweis:** Bei einem Speicherfehler bleiben die Eingaben auf der Seite. Während des Speicherns sind Bearbeitung und unbeabsichtigtes Schließen gesperrt.

**Diagramme:** 04, 11

---

## M17 · Wiederverwendbares Raster für Unterseiten

**Quellcode:** [lib/widgets/album_grid.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/album_grid.dart)

**Aufgabe:** Zeigt Albumkarten mit Cover, Titel, Künstlern und Jahr. Öffnet beim Antippen eine AlbumDetailPage mit denselben Diensten und Callbacks.

**Eingaben:** List<Album>, AuthService, **optionaler Ländercode des TIDAL-Kontos, beispielsweise DE für Deutschland** und zwei Callbacks.

**Ausgaben:** Albumraster und Navigation zur Detailseite.

**Verbindungen:** Wird von KuenstlerPage und KategoriePage verwendet; baut AlbumCover. Die Hauptsammlung hat derzeit ein eigenes Raster in HomePage.

**Wichtige Namen:** AlbumGrid.build()

**Hinweis:** Wiederverwendung ist hier konkret sichtbar. Es wäre ungenau zu behaupten, dass bereits jedes Raster der App dieses Widget nutzt.

**Diagramme:** 05, 14

---

## M18 · Coverdatei laden und Bildfehler abfangen

**Quellcode:** [lib/widgets/album_cover.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/album_cover.dart)

**Aufgabe:** Fordert ein Cover vom Dateicache an und zeigt Ladeanzeige, Datei oder Netzbild. Bei fehlender URL bzw. erfolglosem Netzbild erscheint ein Platzhalter.

**Eingaben:** Album; beim Widget-Update werden geänderte ID oder Cover-URL erkannt.

**Ausgaben:** Bilddarstellung mit FutureBuilder; kein geändertes Albumobjekt.

**Verbindungen:** Verwendet LokalerCoverCache.dateiFuer(), Image.file und als Ersatz Image.network. Eingesetzt in Hauptsammlung, AlbumGrid und Detailseite.

**Wichtige Namen:** AlbumCover, _AlbumCoverState; initState(), didUpdateWidget(), _netzFallback()

**Hinweis:** Ein vorhandener Dateipfad garantiert noch kein decodierbares Bild. Darum besitzt auch Image.file eine Fehlerbehandlung.

**Diagramme:** 13

---

## M19 · Eingaben sammeln und Ergebnisse zurückgeben

**Quellcode:** [lib/widgets/dialoge.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/dialoge.dart)

**Aufgabe:** Bündelt drei zustandsbehaftete Dialoge: Kategoriename, einzelne Künstleranpassung und Album-Kategorienauswahl. Jeder Dialog besitzt seine Eingabecontroller bzw. Auswahlkopie.

**Eingaben:** Dialogtitel/Startname, Künstlerdaten bzw. Kategorien mit ausgewählten IDs.

**Ausgaben:** String, _KuenstlerDialogErgebnis oder Set<int> über Navigator.pop(); bei Abbruch null.

**Verbindungen:** HomePage und AlbumDetailPage öffnen die Dialoge und speichern anschließend selbst in SQLite.

**Wichtige Namen:** _KategorieNameDialog, _KuenstlerBearbeitenDialog, _AlbumKategorienDialog, _KuenstlerDialogErgebnis; jeweilige State-Klassen

**Hinweis:** Die Dialoge führen keine SQL-Operationen aus. Controller werden in dispose() ihres eigenen Dialogzustands freigegeben.

**Diagramme:** 12

---
