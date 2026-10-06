Tidal2WiiM – visuelle Startseite
================================

Dieses Paket basiert auf dem zuletzt getesteten Refactoring-Stand (Schritt 4)
inklusive SQLite-Bibliothekscache und lokalem Cover-Cache.

Neu:
- visuelle Startseite im freigegebenen Querformat-Entwurf
- „Sammlung öffnen“ als zentraler Einstieg
- Zahnrad „Einstellungen“ öffnet das bisherige technische Labor
- TIDAL-Status unten links: bei nicht angemeldetem Zustand antippen -> Anmeldung
- „Sammlung aktualisieren“ startet den TIDAL-Hintergrundabgleich
- Albumzahl, TIDAL-Status, Bibliotheksstatus und letzte Aktualisierung werden dynamisch eingeblendet
- die bisherige Sammlungsseite bleibt unverändert

WICHTIG – pubspec.yaml
----------------------
Unter dem vorhandenen Abschnitt "flutter:" muss das Bild als Asset eingetragen sein:

flutter:
  uses-material-design: true
  assets:
    - assets/images/startseite.png

Falls bereits ein "assets:"-Abschnitt existiert, nur diese Zeile ergänzen:

    - assets/images/startseite.png

Danach im Projektordner ausführen:

  flutter pub get
  dart format lib
  flutter analyze
  flutter test
  flutter build apk --release

Installation auf das Tablet:

  & "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe" install -r "D:\Entwicklung\tidal2wiim\build\app\outputs\flutter-apk\app-release.apk"
