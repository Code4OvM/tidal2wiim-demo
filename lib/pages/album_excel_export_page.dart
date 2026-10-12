import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/album_export.dart';
import '../services/album_excel_export.dart';
import '../services/album_export_metadaten.dart';

typedef AlbumExcelSpeichern = Future<String?> Function(
  Uint8List bytes,
  String name,
);
typedef AlbumExcelErzeugen = Future<Uint8List> Function(
  AlbumExcelDokument dokument,
);

Future<String?> albumExcelAufAndroidSpeichern(
  Uint8List bytes,
  String name,
) async {
  if (!Platform.isAndroid) {
    throw UnsupportedError(
      'Der Dateiexport ist für das Android-Tablet vorgesehen.',
    );
  }
  // file_picker 13: statische API, Rückgabewert Uri? statt String?.
  // Das Plugin schreibt die Bytes selbst. Eine content:-URI ist kein Dateipfad:
  // Deshalb hier NICHT zusätzlich File(uri).writeAsBytes() aufrufen.
  final Uri? ziel = await FilePicker.saveFile(
    dialogTitle: 'Albumliste speichern',
    fileName: name,
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    type: FileType.custom,
    allowedExtensions: const ['xlsx'],
    bytes: bytes,
  );
  // Bestehende App-/Testschnittstelle beibehalten: null bedeutet Abbruch.
  return ziel?.toString();
}

class AlbumExcelExportPage extends StatefulWidget {
  const AlbumExcelExportPage({
    super.key,
    required this.albumAnzahl,
    required this.snapshotLaden,
    this.jsonLesen,
    this.land,
    this.speichern,
    this.erzeugen,
  });

  final int albumAnzahl;
  final Future<AlbumExportSnapshot> Function() snapshotLaden;
  final AlbumExportJsonLesen? jsonLesen;
  final String? land;
  final AlbumExcelSpeichern? speichern;
  final AlbumExcelErzeugen? erzeugen;

  @override
  State<AlbumExcelExportPage> createState() => _AlbumExcelExportPageState();
}

class _AlbumExcelExportPageState extends State<AlbumExcelExportPage> {
  late bool _onlineErgaenzen;
  bool _beschaeftigt = false;
  bool _dateidialog = false;
  bool _fehler = false;
  String _status = '';
  String? _hinweis;
  AlbumExportAbbruch? _abbruch;

  @override
  void initState() {
    super.initState();
    _onlineErgaenzen = widget.jsonLesen != null;
  }

  @override
  void dispose() {
    _abbruch?.abbrechen();
    super.dispose();
  }

  void _statusSetzen(String text) {
    if (!mounted) {
      return;
    }
    setState(() => _status = text);
  }

  Future<void> _exportieren() async {
    if (_beschaeftigt) {
      return;
    }
    FocusScope.of(context).unfocus();
    final abbruch = AlbumExportAbbruch();
    _abbruch = abbruch;
    setState(() {
      _beschaeftigt = true;
      _fehler = false;
      _hinweis = null;
      _status = 'Lokale Bibliothek und Kategorien werden gelesen ...';
    });
    try {
      final snapshot = await widget.snapshotLaden();
      abbruch.pruefen();
      if (snapshot.alben.isEmpty) {
        throw const FormatException(
          'Noch keine vollständige lokale Bibliothek vorhanden. '
          'Bitte zuerst die Sammlung vollständig laden.',
        );
      }
      _statusSetzen(
        _onlineErgaenzen
            ? 'Versions- und Qualitätsangaben werden von TIDAL ergänzt ...'
            : 'Lokaler Stand wird für Excel vorbereitet ...',
      );
      final ergebnis = await albumExportMetadatenErgaenzen(
        alben: snapshot.alben,
        abbruch: abbruch,
        lesen: _onlineErgaenzen ? widget.jsonLesen : null,
        land: widget.land,
        fortschritt: (fertig, gesamt) => _statusSetzen(
          'TIDAL-Zusatzangaben: $fertig von $gesamt Alben bearbeitet ...',
        ),
      );
      abbruch.pruefen();
      if (!mounted) {
        return;
      }
      setState(() {
        _hinweis = ergebnis.hinweis;
        _status =
            'Excel-Datei mit ${ergebnis.alben.length} Alben wird erstellt ...';
      });
      final zeit = DateTime.now();
      final dokument = AlbumExcelDokument(
        alben: ergebnis.alben,
        exportiertAm: zeit,
        cacheStand: snapshot.cacheStand,
        zusatzmetadatenAnzahl: ergebnis.ergaenzt,
        hinweis: ergebnis.hinweis,
      );
      final bytes = widget.erzeugen != null
          ? await widget.erzeugen!(dokument)
          : await compute(albumExcelErzeugen, dokument);
      abbruch.pruefen();
      if (!mounted) {
        return;
      }
      setState(() {
        _dateidialog = true;
        _status =
            'Bitte Speicherort und Dateinamen im Android-Dialog wählen ...';
      });
      final name = albumExcelDateiname(zeit);
      final ort = await (widget.speichern ?? albumExcelAufAndroidSpeichern)(
        bytes,
        name,
      );
      if (!mounted) {
        return;
      }
      _statusSetzen(
        ort == null
            ? 'Speichern abgebrochen. Die Sammlung wurde nicht verändert.'
            : '${ergebnis.alben.length} Alben als Excel-Datei gespeichert. '
                  'Die Datei liegt am gewählten Speicherort.',
      );
    } on AlbumExportAbgebrochen {
      _statusSetzen('Export abgebrochen. Die Sammlung wurde nicht verändert.');
    } on FormatException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fehler = true;
        _status = e.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _fehler = true;
        _status =
            'Export oder Speichern fehlgeschlagen. Bitte erneut versuchen. '
            'Die Sammlung bleibt unverändert.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _beschaeftigt = false;
          _dateidialog = false;
          _abbruch = null;
        });
      }
    }
  }

  void _abbrechen() {
    if (_dateidialog) {
      return;
    }
    _abbruch?.abbrechen();
    _statusSetzen(
      'Export wird abgebrochen; eine laufende Anfrage wird noch beendet ...',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_beschaeftigt,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Alben als Excel-Liste exportieren'),
          leading: IconButton(
            tooltip: 'Zurück zum Labor',
            onPressed: _beschaeftigt ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    '${widget.albumAnzahl} Alben in der aktuellen Ansicht verfügbar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Exportiert wird die gesamte vollständig gespeicherte Bibliothek, '
                    'nicht nur ein Suchergebnis. Pro Album entsteht eine Zeile; mehrere '
                    'Künstler und Kategorien bleiben gemeinsam in dieser Zeile.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Künstler · Albumname mit Versionszusatz · Erscheinungsdatum · '
                    'Audioqualität · Kategorien · TIDAL-Link · TIDAL-Album-ID',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Die Spalten „Genre-Vorschläge“, „Sicherheit der Zuordnung“ '
                    'und „Anmerkung“ bleiben für die spätere Bearbeitung leer.',
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile.adaptive(
                    key: const ValueKey('excel-zusatzangaben'),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Versions- und Qualitätsangaben von TIDAL ergänzen',
                    ),
                    subtitle: Text(
                      widget.jsonLesen == null
                          ? 'Keine gespeicherte Sitzung verfügbar. Lokaler Export ist trotzdem möglich.'
                          : 'Nur zusätzliche Leseabfragen. Bei Verbindungsproblemen werden '
                                'die lokalen Daten trotzdem exportiert; fehlende Angaben bleiben leer.',
                    ),
                    value: _onlineErgaenzen,
                    onChanged: _beschaeftigt || widget.jsonLesen == null
                        ? null
                        : (value) => setState(() => _onlineErgaenzen = value),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Die Datei kann z. B. in „Downloads“ gespeichert und anschließend '
                    'auf den PC übertragen werden. Kein Import, keine Änderung an Kategorien '
                    'und keine automatische Genrezuordnung.',
                  ),
                  const SizedBox(height: 24),
                  if (_beschaeftigt) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 12),
                  ],
                  if (_status.isNotEmpty) ...[
                    Text(
                      _status,
                      key: const ValueKey('excel-status'),
                      style: TextStyle(
                        color: _fehler
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (_hinweis != null) ...[
                    Text(_hinweis!, key: const ValueKey('excel-hinweis')),
                    const SizedBox(height: 12),
                  ],
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        key: const ValueKey('excel-speichern'),
                        onPressed: _beschaeftigt || widget.albumAnzahl == 0
                            ? null
                            : _exportieren,
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text(
                          'Excel-Datei erstellen und speichern',
                        ),
                      ),
                      if (_beschaeftigt && !_dateidialog)
                        TextButton(
                          key: const ValueKey('excel-abbrechen'),
                          onPressed: _abbruch?.abgebrochen == true
                              ? null
                              : _abbrechen,
                          child: const Text('Export abbrechen'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}