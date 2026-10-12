import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../models/album_export.dart';

const albumExcelSpalten = <String>[
  'Künstler',
  'Albumname inkl. Versionsangabe',
  'Erscheinungsdatum',
  'Audioqualität',
  'Kategorien',
  'TIDAL-Link',
  'TIDAL-Album-ID',
  'Genre-Vorschläge',
  'Sicherheit der Zuordnung',
  'Anmerkung',
];

class AlbumExcelDokument {
  AlbumExcelDokument({
    required Iterable<AlbumExportZeile> alben,
    required this.exportiertAm,
    this.cacheStand,
    this.zusatzmetadatenAnzahl = 0,
    this.hinweis,
  }) : alben = List<AlbumExportZeile>.unmodifiable(alben);
  final List<AlbumExportZeile> alben;
  final DateTime exportiertAm;
  final DateTime? cacheStand;
  final int zusatzmetadatenAnzahl;
  final String? hinweis;
}

String albumExcelDateiname(DateTime zeit) {
  String zwei(int n) => n.toString().padLeft(2, '0');
  return 'Tidal2WiiM_Alben_${_datum(zeit)}_'
      '${zwei(zeit.hour)}${zwei(zeit.minute)}${zwei(zeit.second)}.xlsx';
}

/// Bewusst begrenzter OOXML-Export: zwei Arbeitsblätter, Texte, Datum,
/// Hyperlinks, Filter und Eingabehilfe. Kein Excel-Editor, keine Makros.
/// Öffentliche Top-Level-Funktion, damit Flutter compute() sie ausführen kann.
Uint8List albumExcelErzeugen(AlbumExcelDokument dokument) {
  final alben = albumExportSortieren(dokument.alben);
  if (alben.length > 1048575) {
    throw const FormatException('Zu viele Alben für ein Excel-Arbeitsblatt.');
  }
  final dateien = <String, String>{
    '[Content_Types].xml': _contentTypes,
    '_rels/.rels': _rootRels,
    'docProps/app.xml': _app,
    'docProps/core.xml': _core(dokument.exportiertAm),
    'xl/workbook.xml': _workbook(alben.length + 1),
    'xl/_rels/workbook.xml.rels': _workbookRels,
    'xl/styles.xml': _styles,
    'xl/worksheets/sheet1.xml': _albenBlatt(alben),
    'xl/worksheets/sheet2.xml': _hinweiseBlatt(dokument, alben),
  };
  if (alben.isNotEmpty) {
    dateien['xl/worksheets/_rels/sheet1.xml.rels'] = _linkRels(alben);
  }
  final archiv = Archive();
  for (final entry in dateien.entries) {
    final bytes = utf8.encode(entry.value);
    archiv.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return Uint8List.fromList(ZipEncoder().encode(archiv));
}

String _datum(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _xml(String text) {
  for (final rune in text.runes) {
    final erlaubt =
        rune == 9 ||
        rune == 10 ||
        rune == 13 ||
        (rune >= 0x20 && rune <= 0xD7FF) ||
        (rune >= 0xE000 && rune <= 0xFFFD) ||
        (rune >= 0x10000 && rune <= 0x10FFFF);
    if (!erlaubt) {
      throw const FormatException(
        'Ein Tabellenwert enthält ungültige Steuerzeichen.',
      );
    }
  }
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _textZelle(String adresse, String text, int style) {
  if (text.length > 32767) {
    throw const FormatException(
      'Ein Tabellenwert überschreitet die Excel-Zellgrenze.',
    );
  }
  // Excel interpretiert _xHHHH_ speziell. Vorhandene Literalfolgen schützen.
  final escaped = text.replaceAllMapped(
    RegExp(r'_x[0-9a-fA-F]{4}_'),
    (m) => '_x005F_${m.group(0)!.substring(1)}',
  );
  // inlineStr ist ausdrücklich Text: auch =, +, - und @ sind KEINE Formeln.
  return '<c r="$adresse" s="$style" t="inlineStr"><is>'
      '<t xml:space="preserve">${_xml(escaped)}</t></is></c>';
}

String _datumZelle(String adresse, DateTime? datum, bool streifen) {
  if (datum == null) {
    return '<c r="$adresse" s="${streifen ? 6 : 5}"/>';
  }
  final tag = DateTime.utc(datum.year, datum.month, datum.day);
  if (tag.year < 1900 || tag.year > 9999) {
    return _textZelle(adresse, _datum(datum), streifen ? 4 : 3);
  }
  var serial = tag.difference(DateTime.utc(1899, 12, 31)).inDays;
  if (!tag.isBefore(DateTime.utc(1900, 3, 1))) {
    serial++; // Excel-1900-Konvention.
  }
  return '<c r="$adresse" s="${streifen ? 6 : 5}"><v>$serial</v></c>';
}

String _albenBlatt(List<AlbumExportZeile> alben) {
  final ende = alben.length + 1;
  final b = StringBuffer(
    '$_xmlStart<worksheet xmlns="$_ss" xmlns:r="$_rel">'
    '<dimension ref="A1:J$ende"/>'
    '<sheetViews><sheetView workbookViewId="0" showGridLines="0">'
    '<pane xSplit="2" ySplit="1" topLeftCell="C2" activePane="bottomRight" state="frozen"/>'
    '<selection pane="bottomRight" activeCell="C2" sqref="C2"/>'
    '</sheetView></sheetViews><sheetFormatPr defaultRowHeight="44"/>'
    '<cols>',
  );
  const breiten = [32, 44, 19, 26, 30, 40, 22, 32, 25, 40];
  for (var i = 0; i < breiten.length; i++) {
    b.write(
      '<col min="${i + 1}" max="${i + 1}" width="${breiten[i]}" customWidth="1"/>',
    );
  }
  b.write('</cols><sheetData><row r="1" ht="40" customHeight="1">');
  for (var i = 0; i < albumExcelSpalten.length; i++) {
    b.write(
      _textZelle(
        '${String.fromCharCode(65 + i)}1',
        albumExcelSpalten[i],
        i < 7 ? 1 : 2,
      ),
    );
  }
  b.write('</row>');
  for (var i = 0; i < alben.length; i++) {
    final a = alben[i];
    final r = i + 2;
    final streifen = i.isOdd;
    final style = streifen ? 4 : 3;
    b.write('<row r="$r" ht="44" customHeight="1">');
    b.write(_textZelle('A$r', a.kuenstler.join('; '), style));
    b.write(_textZelle('B$r', a.albumname, style));
    b.write(_datumZelle('C$r', a.erscheinungsdatum, streifen));
    b.write(_textZelle('D$r', a.mediaTags.join('; '), style));
    b.write(_textZelle('E$r', a.kategorien.join('; '), style));
    b.write(_textZelle('F$r', a.link, streifen ? 10 : 9));
    b.write(_textZelle('G$r', a.id, style));
    b.write('<c r="H$r" s="7"/><c r="I$r" s="7"/><c r="J$r" s="7"/></row>');
  }
  b.write('</sheetData><autoFilter ref="A1:J$ende"/>');
  if (alben.isNotEmpty) {
    b.write(
      '<dataValidations count="1"><dataValidation type="list" '
      'allowBlank="1" showErrorMessage="1" errorStyle="stop" '
      'errorTitle="Gültige Zuordnung wählen" '
      'error="Bitte hoch, mittel oder unklar wählen." sqref="I2:I$ende">'
      '<formula1>"hoch,mittel,unklar"</formula1></dataValidation></dataValidations>',
    );
    b.write('<hyperlinks>');
    for (var i = 0; i < alben.length; i++) {
      b.write('<hyperlink ref="F${i + 2}" r:id="rId${i + 1}"/>');
    }
    b.write('</hyperlinks>');
  }
  b.write(
    '<pageMargins left="0.3" right="0.3" top="0.5" bottom="0.5" '
    'header="0.2" footer="0.2"/></worksheet>',
  );
  return b.toString();
}

String _hinweiseBlatt(AlbumExcelDokument d, List<AlbumExportZeile> alben) {
  final daten = <List<String>>[
    ['Tidal2WiiM · Albumexport', ''],
    ['Exportiert am', d.exportiertAm.toLocal().toIso8601String()],
    [
      'Lokaler Bibliotheksstand',
      d.cacheStand?.toLocal().toIso8601String() ?? 'Nicht vorhanden',
    ],
    ['Exportierte Alben', '${alben.length}'],
    [
      'Zusatzmetadaten von TIDAL',
      '${d.zusatzmetadatenAnzahl} von ${alben.length} Alben',
    ],
    [
      'Umfang',
      'Gesamte gespeicherte Bibliothek, unabhängig von Such- und Ansichtsfiltern. '
          'Eine Zeile pro Album-ID. Mehrere Künstler oder Kategorien stehen gemeinsam in einer Zelle.',
    ],
    [
      'Künstlernamen',
      'Die Namen stammen aus dem TIDAL-Albumcache. Persönliche Sortiernamen '
          'und umbenannte Künstlerordner werden nicht anstelle der TIDAL-Namen ausgegeben.',
    ],
    [
      'Albumname',
      'Lokaler Titel; bei aktivierter und erfolgreicher Zusatzabfrage TIDAL-Titel '
          'mit gegebenenfalls geliefertem Versionszusatz. Keine eigenständige Editionsrecherche.',
    ],
    [
      'Erscheinungsdatum',
      'Datum aus dem lokalen Albumcache; nicht zwangsläufig das historische '
          'Erstveröffentlichungsdatum. Fehlende Angaben bleiben leer.',
    ],
    [
      'Audioqualität',
      'Unveränderte mediaTags der Album-API, z. B. LOSSLESS, HIRES_LOSSLESS '
          'oder DOLBY_ATMOS, sofern übermittelt. Keine Messung der Wiedergabe, keine zugesicherte '
          'Bit-/Abtastrate und keine Garantie für sämtliche Titel oder Endgeräte.',
    ],
    [
      'Genre-Vorschläge',
      'Bewusst leer: später extern ein bis drei passende Musikrichtungen eintragen.',
    ],
    [
      'Sicherheit der Zuordnung',
      'Bewusst leer: später hoch, mittel oder unklar wählen.',
    ],
    [
      'Anmerkung',
      'Bewusst leer: später kurze Begründung oder Hinweis auf einen Grenzfall.',
    ],
    [
      'Kein Rückimport',
      'Änderungen in Excel ändern die App nicht. Kategorien werden weiterhin '
          'bewusst und manuell in der App zugeordnet.',
    ],
    [
      'Kein vollständiges Backup',
      'Diese Liste ersetzt keine Sicherung der App-Datenbank. '
          'Sie enthält keine Anmeldedaten, keine Coverdateien und keine Musikdateien.',
    ],
    [
      'Zusatzabfrage',
      d.hinweis ??
          'Abfrage abgeschlossen. Auch bei erfolgreichem Abruf können '
              'Versionszusätze und Qualitätsangaben fehlen. Leere Werte werden nicht erfunden.',
    ],
    ['Metadatenreferenz', 'https://tidal-music.github.io/tidal-api-reference/'],
  ];
  final b = StringBuffer(
    '$_xmlStart<worksheet xmlns="$_ss">'
    '<dimension ref="A1:B${daten.length}"/>'
    '<sheetViews><sheetView workbookViewId="0" showGridLines="0"/></sheetViews>'
    '<sheetFormatPr defaultRowHeight="48"/><cols>'
    '<col min="1" max="1" width="30" customWidth="1"/>'
    '<col min="2" max="2" width="88" customWidth="1"/></cols><sheetData>',
  );
  for (var i = 0; i < daten.length; i++) {
    final r = i + 1;
    b.write(
      '<row r="$r" ht="${i == 0 ? 32 : (i < 5 ? 24 : 58)}" customHeight="1">',
    );
    b.write(_textZelle('A$r', daten[i][0], i == 0 ? 8 : 4));
    b.write(_textZelle('B$r', daten[i][1], 3));
    b.write('</row>');
  }
  b.write(
    '</sheetData><mergeCells count="1"><mergeCell ref="A1:B1"/></mergeCells></worksheet>',
  );
  return b.toString();
}

String _linkRels(List<AlbumExportZeile> alben) =>
    '$_xmlStart<Relationships xmlns="$_packageRel">'
    '${[for (var i = 0; i < alben.length; i++) '<Relationship Id="rId${i + 1}" Type="$_rel/hyperlink" '
          'Target="${_xml(alben[i].link)}" TargetMode="External"/>'].join()}'
    '</Relationships>';

const _xmlStart = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>';
const _ss = 'http://schemas.openxmlformats.org/spreadsheetml/2006/main';
const _rel =
    'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const _packageRel =
    'http://schemas.openxmlformats.org/package/2006/relationships';
const _contentTypes =
    '''$_xmlStart<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
<Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';
const _rootRels =
    '''$_xmlStart<Relationships xmlns="$_packageRel">
<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
<Relationship Id="rId3" Type="$_rel/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';
String _workbook(int ende) =>
    '''$_xmlStart<workbook xmlns="$_ss" xmlns:r="$_rel">
<bookViews><workbookView activeTab="0"/></bookViews>
<sheets><sheet name="Alben" sheetId="1" r:id="rId1"/>
<sheet name="Hinweise" sheetId="2" r:id="rId2"/></sheets>
<definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">'Alben'!\$A\$1:\$J\$$ende</definedName></definedNames>
</workbook>''';
const _workbookRels =
    '''$_xmlStart<Relationships xmlns="$_packageRel">
<Relationship Id="rId1" Type="$_rel/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="$_rel/worksheet" Target="worksheets/sheet2.xml"/>
<Relationship Id="rId3" Type="$_rel/styles" Target="styles.xml"/>
</Relationships>''';
const _app =
    '''$_xmlStart<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties"><Application>Tidal2WiiM</Application></Properties>''';
String _core(DateTime date) =>
    '''$_xmlStart<cp:coreProperties
xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties"
xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<dc:creator>Tidal2WiiM</dc:creator><dc:title>Albumexport</dc:title>
<dcterms:created xsi:type="dcterms:W3CDTF">${date.toUtc().toIso8601String()}</dcterms:created>
</cp:coreProperties>''';
const _styles = '''$_xmlStart<styleSheet xmlns="$_ss">
<numFmts count="1"><numFmt numFmtId="164" formatCode="dd.mm.yyyy"/></numFmts>
<fonts count="4">
<font><sz val="11"/><color rgb="FF202B32"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font>
<font><b/><sz val="18"/><color rgb="FF233C43"/><name val="Calibri"/></font>
<font><u/><sz val="11"/><color rgb="FF16637C"/><name val="Calibri"/></font>
</fonts>
<fills count="6">
<fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF233C43"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FF88663B"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFF1F5F6"/><bgColor indexed="64"/></patternFill></fill>
<fill><patternFill patternType="solid"><fgColor rgb="FFFFF8EA"/><bgColor indexed="64"/></patternFill></fill>
</fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="11">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="1" fillId="3" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="0" fillId="4" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="164" fontId="0" fillId="4" borderId="0" xfId="0" applyNumberFormat="1" applyAlignment="1"><alignment vertical="top"/></xf>
<xf numFmtId="0" fontId="0" fillId="5" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="center"/></xf>
<xf numFmtId="0" fontId="3" fillId="0" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
<xf numFmtId="0" fontId="3" fillId="4" borderId="0" xfId="0" applyAlignment="1"><alignment vertical="top" wrapText="1"/></xf>
</cellXfs><cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>
</styleSheet>''';