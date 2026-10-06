part of '../main.dart';

typedef Json = Map<String, dynamic>;

// ============================================================================
// Allgemeine Hilfen
// ============================================================================

Json _objekt(Object? wert) {
  if (wert is Json) return wert;
  throw const FormatException('JSON-Objekt erwartet.');
}

Json _optionalObjekt(Object? wert) => wert is Json ? wert : {};

List<Json> _liste(Object? wert) {
  if (wert is! List) {
    throw const FormatException('JSON-Liste erwartet.');
  }
  return wert.map(_objekt).toList();
}

String? _text(Object? wert) {
  if (wert is String && wert.trim().isNotEmpty) {
    return wert.trim();
  }
  return null;
}

String _vergleichstext(String text) {
  return text
      .trim()
      .toLowerCase()
      .replaceAll('ä', 'a')
      .replaceAll('ö', 'o')
      .replaceAll('ü', 'u')
      .replaceAll('ß', 'ss');
}

// ============================================================================
// Zeitdauer
// ============================================================================

Duration? _dauerLesen(Object? wert) {
  final text = _text(wert);
  if (text == null) return null;

  final match = RegExp(
    r'^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+(?:[.,]\d+)?)S)?)?$',
  ).firstMatch(text);

  if (match == null) return null;

  double zahl(int gruppe) {
    return double.tryParse((match.group(gruppe) ?? '0').replaceAll(',', '.')) ??
        0;
  }

  final sekunden = zahl(1) * 86400 + zahl(2) * 3600 + zahl(3) * 60 + zahl(4);

  if (!sekunden.isFinite) return null;

  return Duration(milliseconds: (sekunden * 1000).round());
}

String _dauerAnzeige(Duration? dauer) {
  if (dauer == null) return '–';

  final stunden = dauer.inHours;
  final minuten = dauer.inMinutes.remainder(60).toString().padLeft(2, '0');
  final sekunden = dauer.inSeconds.remainder(60).toString().padLeft(2, '0');

  if (stunden > 0) {
    return '$stunden:$minuten:$sekunden';
  }

  return '${dauer.inMinutes}:$sekunden';
}
