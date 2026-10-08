# M03 · Ansichten aus vorhandenen Alben ableiten

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/core/sammlung.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/core/sammlung.dart)

**Aufgabe:** Filtert und sortiert Alben, bildet Künstlerordner und berechnet den A-Z-Sprungindex. Definiert die Auswahlwerte für Appseite, Sammlungsansicht und Sortierung.

**Eingaben:** List<Album>, Suchtext, Sortierung und Map<String, KuenstlerEinstellung>.

**Ausgaben:** Gefilterte Albumliste, List<KuenstlerOrdner> oder Map<String, int> als Buchstabenindex.

**Verbindungen:** HomePage ruft die Funktionen beim Aufbau der Sammlung auf. Benutzt Fachmodelle und Texthelfer.

**Wichtige Namen:** Sortierung, SammlungAnsicht, AppSeite, _ansichtErstellen(), _kuenstlerOrdnerErstellen(), _kuenstlerAlphabetIndex()

**Hinweis:** Künstlerordner entstehen im RAM. Mehrere Künstler eines Albums führen zu mehreren Ordnerzuordnungen. Die Albumsortierung verwendet TIDAL-Künstlernamen; eigene Sortiernamen steuern die Künstlerordner.

**Diagramme:** [01 – Verantwortung und Datenwege](../SVG/01_Komponenten.svg) · [02 – Fachmodelle im Arbeitsspeicher](../SVG/02_Klassen_Datenmodelle.svg)
