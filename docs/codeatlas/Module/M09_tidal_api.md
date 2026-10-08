# M09 · API-Aufrufe vereinheitlichen und JSON lesen

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/services/tidal_api.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/tidal_api.dart)

**Aufgabe:** Baut OpenAPI-URLs, ruft den Auth-Dienst auf, prüft HTTP 200 und decodiert JSON. Liest Folgekursor, wählt eine passende Cover-URL und übersetzt Fehler in verständliche Hinweise.

**Eingaben:** http.Client, gemeinsamer TidalAuthService, Pfadsegmente und Queryparameter; JSON-Ressourcen für Cover und Cursor.

**Ausgaben:** Future<Json>, String? für Cursor/Cover-URL oder ApiFehler.

**Verbindungen:** HomePage und AlbumDetailPage nutzen _apiLesen(). Album.ausRessourcen() nutzt _coverUrlLesen().

**Wichtige Namen:** _apiLesen(), _cursorLesen(), _coverUrlLesen(), _fehlerText(), ApiFehler

**Hinweis:** Die Datei ist überwiegend eine Funktionssammlung, keine TidalApi-Klasse. Jeder Aufruf wartet vor der Anfrage 300 ms; das ist kein vollständiger automatischer 429-Retry.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [09 – Von JSON-Ressourcen zu Album-Objekten](../SVG/09_Sequenz_Albumseite.svg) · [10 – API 401: einmal erneuern und wiederholen](../SVG/10_Sequenz_Token401.svg)
