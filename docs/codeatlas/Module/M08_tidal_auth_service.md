# M08 · Anmeldung und Token-Lebenszyklus verwalten

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/services/tidal_auth_service.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/services/tidal_auth_service.dart)

**Aufgabe:** Stellt die gemeinsame Sitzung wieder her, speichert Login-Ergebnisse und erneuert Tokens bei Bedarf. Schützt vor mehrfachen parallelen Refreshs und Ergebnissen einer inzwischen ersetzten Sitzung.

**Eingaben:** clientId, optionale Store-/Client-/Uhr-Abhängigkeiten; TidalSession beim Login; HTTPS-URI und HTTP-Client beim Lesen.

**Ausgaben:** Future<String> für ein Token, Future<Response> für API-GET, Status-Getter und ChangeNotifier-Benachrichtigungen.

**Verbindungen:** HomePage besitzt oder erhält den Dienst und gibt dieselbe Referenz an Unterseiten weiter. SecureTidalSessionStore verwendet flutter_secure_storage.

**Wichtige Namen:** TidalAuthService, TidalSession, TidalSessionStore, SecureTidalSessionStore; restore(), acceptLogin(), accessToken(), get(), forget()

**Hinweis:** HTTP 401 führt höchstens zu einem zweiten API-GET. Temporäre Netzfehler erhalten die Sitzung. storageWarning weist auf Probleme beim Lesen, Speichern oder Entfernen der sicheren Sitzung hin.

**Diagramme:** [03 – Sitzungsverwaltung und Testbarkeit](../SVG/03_Klassen_Sitzung.svg) · [06 – Appstart: Cache und gespeicherte Sitzung](../SVG/06_Sequenz_Appstart.svg) · [07 – Interaktive Anmeldung und sicheres Speichern](../SVG/07_Sequenz_Anmeldung.svg) · [10 – API 401: einmal erneuern und wiederholen](../SVG/10_Sequenz_Token401.svg)
