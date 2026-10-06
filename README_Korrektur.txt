Tidal2WiiM – Korrektur der grafischen Startseite
Stand: 30.09.2026
Zielgerät laut Projekt: LZF ZA1, insbesondere Querformat.

BEHOBENE PUNKTE
1. Einheitlicher Maßstab: Bild, Texte und Trefferflächen liegen auf derselben
   Zeichenfläche (1448 x 1086, entsprechend der tatsächlichen PNG-Datei).
   Keine Verzerrung durch BoxFit.fill; die gesamte Oberfläche wird proportional
   in den verfügbaren Bereich eingepasst.
2. Der anklickbare Einstellungen-Bereich liegt über Zahnrad UND Beschriftung.
   Er öffnet das Labor und bleibt auch während eines Ladevorgangs erreichbar.
3. Die eingebrannte Beispiel-Albumzahl wird vollständig abgedeckt. Der aktuelle
   Wert steht an der vorgesehenen Stelle unter MEINE SAMMLUNG.
4. Die gesamte untere Statusleiste wird deckend mit echten Flutter-Elementen
   aufgebaut. Es bleiben keine alten Statuswörter, Häkchen, Titelzahlen oder
   Uhrzeiten sichtbar. Die nicht ermittelte Gesamtzahl der Titel entfällt.
5. SafeArea berücksichtigt die vom Android-System gemeldeten Bildschirmränder,
   insbesondere die untere Bedienleiste. Keine feste Gerätepixelhöhe erforderlich.
   Bei breiteren Bildschirmformaten bleiben dunkle seitliche Ränder, statt das
   4:3-Motiv abzuschneiden oder zu verzerren.
6. Der Widget-Test prüft nun die neue Startseite und den Weg ins Labor, nicht
   mehr Anmeldeknöpfe direkt auf der Bild-Startseite.

DATEIEN ÜBERNEHMEN
Vorher eine Sicherung deines Projekts außerhalb von lib/test anlegen.
ZIP in ein separates Verzeichnis entpacken.
Die Ordner lib, assets und test in D:\Entwicklung\tidal2wiim kopieren.
Vorhandene gleichnamige Dateien ersetzen; insbesondere test\widget_test.dart.
Die im Projekt vorhandene pubspec.yaml NICHT ersetzen.

Es sind keine neuen Pakete, keine neue Datenbankversion und keine Änderungen
an Android/Gradle nötig. Die Bilddatei ist bytegleich mit dem freigegebenen
Bild aus dem bisherigen Startseitenpaket. Ihr Pfad bleibt unverändert:
assets/images/startseite.png

Die zusätzliche optionale Funktion bibliothekLaden in Tidal2WiiMApp/HomePage
ermöglicht isolierte UI-Tests ohne SQLite-Plugin. Beim normalen Start bleibt
alles wie bisher: Der Bibliothekscache wird aus SQLite eingelesen.

PRÜFEN (im Projektverzeichnis)
dart format lib test
flutter analyze
flutter test

Nur bei erfolgreicher Prüfung:
flutter build apk --release

Nur bei erfolgreichem Build im selben PowerShell-Fenster:
& "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" -s DHZ1A256GB26240629 install -r "D:\Entwicklung\tidal2wiim\build\app\outputs\flutter-apk\app-release.apk"

Die App nicht deinstallieren und keine App-Daten löschen. Kategorien,
Künstler-Sortiernamen, Bibliothekscache und Covercache werden durch dieses
Quellcodepaket nicht verändert. install -r verwendet den üblichen Updateweg.

PRAKTISCHER TEST
- Tablet ins Querformat drehen; die Android-Bedienleiste bleibt sichtbar.
- Direkt auf das Zahnrad tippen: Das Labor muss erscheinen.
- Im Labor oben auf das Haus tippen: Zurück zur grafischen Startseite.
- Albumzahl und Statusfelder prüfen: Kein versetzter/doppelter Text.
- Sammlung öffnen und danach zur Startseite zurückkehren.
- Aktualisieren: Der vorhandene Abgleich läuft; der Zeitpunkt wird aktualisiert.

PRÜFSTATUS DIESES PAKETS
Geprüft: Vollständigkeit, part-Verweise, unveränderte Bilddatei, Unterschiede
zum Ausgangspaket und Koordinaten der Bild-/Text-/Bedienflächen.
Die mitgelieferten Flutter-Widget-Tests umfassen Aktionen, Labor-Navigation,
dynamische Werte und mehrere Seitenverhältnisse mit simulierten Systemrändern.
Sie wurden im Erstellungscontainer nicht ausgeführt: Hier ist kein Flutter-SDK
installiert. Flutter analyze/test und der Android-Build sind auf dem
Entwicklungsrechner auszuführen. Kein behaupteter Testlauf auf dem LZF ZA1.
