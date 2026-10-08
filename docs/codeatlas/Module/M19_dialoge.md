# M19 · Eingaben sammeln und Ergebnisse zurückgeben

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/widgets/dialoge.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/dialoge.dart)

**Aufgabe:** Bündelt drei zustandsbehaftete Dialoge: Kategoriename, einzelne Künstleranpassung und Album-Kategorienauswahl. Jeder Dialog besitzt seine Eingabecontroller bzw. Auswahlkopie.

**Eingaben:** Dialogtitel/Startname, Künstlerdaten bzw. Kategorien mit ausgewählten IDs.

**Ausgaben:** String, _KuenstlerDialogErgebnis oder Set<int> über Navigator.pop(); bei Abbruch null.

**Verbindungen:** HomePage und AlbumDetailPage öffnen die Dialoge und speichern anschließend selbst in SQLite.

**Wichtige Namen:** _KategorieNameDialog, _KuenstlerBearbeitenDialog, _AlbumKategorienDialog, _KuenstlerDialogErgebnis; jeweilige State-Klassen

**Hinweis:** Die Dialoge führen keine SQL-Operationen aus. Controller werden in dispose() ihres eigenen Dialogzustands freigegeben.

**Diagramme:** [12 – Ein Album mehreren Kategorien zuordnen](../SVG/12_Sequenz_Kategorien.svg)
