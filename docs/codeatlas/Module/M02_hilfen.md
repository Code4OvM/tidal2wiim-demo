# M02 · JSON, Suchtext und Zeitdauer aufbereiten

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/core/hilfen.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/core/hilfen.dart)

**Aufgabe:** Stellt kleine Hilfsfunktionen ohne eigenen Zustand bereit. Prüft JSON-Strukturen, bereinigt Texte und wandelt ISO-Dauern für die Titelanzeige um.

**Eingaben:** Object?, JSON-Werte, Suchtext oder Duration?.

**Ausgaben:** Json, List<Json>, String?, normalisierte Suchtexte sowie Duration? und Anzeigetexte.

**Datentypen:** `String?` bezeichnet Text oder `null`. `Duration?` bezeichnet eine Zeitdauer oder `null`. Das `?` erlaubt jeweils einen fehlenden Wert.

**Verbindungen:** Wird von Modellen, API-Auswertung, Sammlung und Albumdetailseite benutzt. Kein direkter Netz- oder Datenbankzugriff.

**Wichtige Namen:** Json, _objekt(), _optionalObjekt(), _liste(), _text(), _vergleichstext(), _dauerLesen(), _dauerAnzeige()

**Hinweis:** Ein fehlender optionaler Wert darf null bleiben. Eine falsche Pflichtstruktur wird dagegen als FormatException gemeldet.

**Diagramme:** [09 – Von JSON-Ressourcen zu Album-Objekten](../SVG/09_Sequenz_Albumseite.svg) · [14 – Albumdetails laden und an TIDAL übergeben](../SVG/14_Sequenz_Details_Wiedergabe.svg)
