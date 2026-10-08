# M17 · Wiederverwendbares Raster für Unterseiten

[Codeatlas](../README.md) · [Modulübersicht](../00_Kurzueberblick.md) · [Diagrammübersicht](../04_Diagrammuebersicht.md)

**Quellcode:** [lib/widgets/album_grid.dart](https://github.com/Code4OvM/tidal2wiim-demo/blob/851304ffd33e6ed9f65d74a29d146311e9a6265b/lib/widgets/album_grid.dart)

**Aufgabe:** Zeigt Albumkarten mit Cover, Titel, Künstlern und Jahr. Öffnet beim Antippen eine AlbumDetailPage mit denselben Diensten und Callbacks.

**Eingaben:** List<Album>, AuthService, **optionaler Ländercode des TIDAL-Kontos, beispielsweise DE für Deutschland** und zwei Callbacks.

**Ausgaben:** Albumraster und Navigation zur Detailseite.

**Verbindungen:** Wird von KuenstlerPage und KategoriePage verwendet; baut AlbumCover. Die Hauptsammlung hat derzeit ein eigenes Raster in HomePage.

**Wichtige Namen:** AlbumGrid.build()

**Hinweis:** Wiederverwendung ist hier konkret sichtbar. Es wäre ungenau zu behaupten, dass bereits jedes Raster der App dieses Widget nutzt.

**Diagramme:** [05 – Oberfläche: Objekte und Rückmeldungen](../SVG/05_Klassen_Oberflaeche.svg) · [14 – Albumdetails laden und an TIDAL übergeben](../SVG/14_Sequenz_Details_Wiedergabe.svg)
