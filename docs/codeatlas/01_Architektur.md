# Architektur und Leseführung

[Codeatlas](README.md) · [Dokumentationsübersicht](../README.md)

## Der kurze Weg durch das Projekt

1. `main.dart`: Einstieg und Bibliotheksgrenzen erkennen.
2. `models/modelle.dart`: verstehen, welche Daten die App im RAM verwendet.
3. `core/sammlung.dart`: aus Alben Künstlerordner und Ansichten ableiten.
4. `pages/home_page.dart`: die Koordination von UI, Cache und Online-Abgleich verfolgen.
5. `data/` und `services/`: dauerhafte Daten, Anmeldung und externe Zugriffe unterscheiden.
6. Künstlereditor mit Diagramm 11 verfolgen: Ausgangsstand → Entwurf → bestätigte Änderungsliste → Transaktion → neu gelesene Ansicht.

## Drei eigene Dart-Bibliotheken

| Bibliothek | Verbindung | Bedeutung |
| --- | --- | --- |
| main.dart plus 16 part-Dateien | part / part of | Gemeinsamer Namensraum. `_private` Namen sind innerhalb dieser Bibliothek dateiübergreifend sichtbar. |
| models/kuenstler_sortierung.dart | import in main.dart | Reines Bearbeitungsmodell ohne Flutter-, SQLite- oder TIDAL-Abhängigkeit. |
| services/tidal_auth_service.dart | import in main.dart | Gekapselte Sitzung mit öffentlichen Methoden und privatem internem Zustand. |

Die fachlichen Ordner sind daher keine strengen technischen Schichten. `HomePage` ist die zentrale zustandsbehaftete Oberflächenkomponente (StatefulWidget) der Flutter-App. Ihr Zustand `_HomePageState` koordiniert Navigation, Ansichten und Datenbeschaffung. Die Startansicht mit Titelgrafik wird vom Widget `StartPage` aufgebaut. Datenbank und API verwenden dieselben Fachmodelle. Ein Refactoring in weitere unabhängige Bibliotheken wäre eine spätere Änderung, kein bereits vorhandener Zustand.

## So funktionieren die Verbindungen

**Konstruktorparameter:** Beim Öffnen einer Seite werden Album, Listen, optionales Land und die bestehende AuthService-Referenz übergeben. Die Daten werden nicht erneut über ein Netzwerk zwischen den Dart-Dateien ausgetauscht.

**Future und await:** Ein Future bezeichnet ein späteres Ergebnis. await wartet innerhalb der betreffenden asynchronen Funktion. Future.wait startet keine eigenen Betriebssystemthreads; die begonnenen asynchronen Vorgänge können sich zeitlich überlappen. Auch die Cover-Worker sind asynchrone Schleifen, keine ausdrücklich erzeugten Isolates.

**Callbacks:** Eine Unterseite ruft eine übergebene Funktion auf. `onKategorienGeaendert()` sendet keinen vollständigen Datensatz. Die Elternansicht liest die betroffenen Daten anschließend erneut. Der Editor liefert seine Änderungsliste dagegen ausdrücklich an `onSpeichern(aenderungen)`.

**UI-Zustand:** setState meldet Flutter eine lokale Zustandsänderung. Es speichert nichts in SQLite. ChangeNotifier wird gezielt für den Sitzungsdienst verwendet; es gibt hier keinen allgemeinen Ereignisbus.

**Navigator:** Ein Dialog oder eine Route kann ein Ergebnis liefern. Bei Editor-Erfolg ist dies true; nur dann lädt HomePage die Einstellungen erneut. Bei Abbruch oder unverändertem Zurückgehen gibt es keinen bestätigten Speichervorgang.

## Notation der PlantUML-Modelle

Durchgezogene Klassenpfeile zeigen gehaltene Referenzen, gestrichelte Pfeile eine Verwendung oder Erzeugung. Eine gestrichelte Beziehung „über IDs“ ist keine gespeicherte Objektreferenz. Realisierung und Vererbung sind nur dort eingezeichnet, wo sie im Dart-Code existieren. Die Extension zur Datenbank ist keine Unterklasse.

In Sequenzdiagrammen läuft die Zeit von oben nach unten. `alt` zeigt Alternativen, `opt` eine Bedingung, `loop` Wiederholung und `par` unabhängig gestartete asynchrone Vorgänge. Rückgabepfeile transportieren Daten oder signalisieren das Ende eines Future. Die Darstellung verdichtet den Code; sie ist kein Laufzeit-Trace.

Die Klassendiagramme zeigen zur Lesbarkeit ausgewählte Attribute und Methoden. Das vollständige Verzeichnis aller 46 Klassen/Interfaces steht separat. Hilfsfunktionen werden nicht als erfundene Dienstklassen gezeichnet.
