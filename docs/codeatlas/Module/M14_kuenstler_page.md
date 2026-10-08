# M14 · Alben eines Künstlerordners darstellen

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/pages/kuenstler_page.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/pages/kuenstler_page.dart)

**Aufgabe:** Ist eine kleine, zustandslose Hülle: Zeigt den Anzeigenamen als Seitentitel und übergibt die zugehörigen Alben an AlbumGrid.

**Eingaben:** KuenstlerOrdner, AuthService, optionales Land und Änderungs-/Anmelde-Callbacks.

**Ausgaben:** Widget-Baum aus AppBar und AlbumGrid.

**Verbindungen:** HomePage erstellt den Ordner zuvor mit _kuenstlerOrdnerErstellen(). AlbumGrid übernimmt die Detailnavigation.

**Wichtige Namen:** KuenstlerPage.build()

**Hinweis:** Die Seite legt keine Ordner an und fragt keine Künstlerdaten nach. Sie erhält bereits aufbereitete Objekte.

**Diagramme:** [02 – Fachmodelle im Arbeitsspeicher](../SVG/02_Klassen_Datenmodelle.svg) · [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg)
