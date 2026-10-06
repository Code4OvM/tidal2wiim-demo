part of '../main.dart';

// Sammelbearbeitung: lokal, ohne TIDAL-Aufruf und ohne sofortiges Speichern.
class KuenstlerSortiernamenPage extends StatefulWidget {
  const KuenstlerSortiernamenPage({
    super.key,
    required this.kuenstler,
    required this.onSpeichern,
  });

  final List<KuenstlerSortierZeile> kuenstler;
  final Future<void> Function(List<KuenstlerSortierAenderung>) onSpeichern;

  @override
  State<KuenstlerSortiernamenPage> createState() =>
      _KuenstlerSortiernamenPageState();
}

class _KuenstlerSortiernamenPageState extends State<KuenstlerSortiernamenPage> {
  double get _zeilenHoehe {
    final skala = MediaQuery.textScalerOf(context);
    // Platz auch für zweizeiligen Namen, TIDAL-Name und Änderungsmarker.
    return 16 + skala.scale(20) * 2 + skala.scale(16) * 2;
  }

  late final KuenstlerSortierEntwurf _entwurf;
  final Map<String, TextEditingController> _controller = {};
  final Map<String, FocusNode> _fokus = {};
  final _sucheController = TextEditingController();
  final _suchFokus = FocusNode();
  final _speichernFokus = FocusNode();
  final _scrollController = ScrollController();

  String _suche = '';
  String? _speicherFehler;
  bool _speichert = false;
  bool _rueckfrageOffen = false;
  bool _darfSchliessen = false;
  int _fokusAuftrag = 0;

  @override
  void initState() {
    super.initState();
    _entwurf = KuenstlerSortierEntwurf(widget.kuenstler);
    for (final zeile in _entwurf.zeilen) {
      _controller[zeile.id] = TextEditingController(text: zeile.startwert);
      _fokus[zeile.id] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controller.values) {
      controller.dispose();
    }
    for (final fokus in _fokus.values) {
      fokus.dispose();
    }
    _sucheController.dispose();
    _suchFokus.dispose();
    _speichernFokus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sucheAendern(String wert) {
    _fokusAuftrag++;
    setState(() {
      _suche = wert;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _fokusVerschieben(String id, int richtung) async {
    if (_speichert) {
      return;
    }
    final auftrag = ++_fokusAuftrag;
    final sichtbar = _entwurf.filtern(_suche);
    final index = sichtbar.indexWhere((zeile) => zeile.id == id);
    if (index < 0) {
      return;
    }
    final ziel = index + richtung;

    if (ziel < 0) {
      _suchFokus.requestFocus();
      return;
    }
    if (ziel >= sichtbar.length) {
      FocusScope.of(context).unfocus();
      if (_entwurf.hatAenderungen) {
        _speichernFokus.requestFocus();
      }
      return;
    }

    // Die nächste Zeile kann außerhalb des aktuell gebauten Listenausschnitts
    // liegen. Zuerst sichtbar scrollen, dann ihren Fokus setzen.
    if (_scrollController.hasClients) {
      final position = _scrollController.position;
      final oben = ziel * _zeilenHoehe;
      final unten = oben + _zeilenHoehe;
      var offset = position.pixels;
      if (oben < offset) {
        offset = oben;
      } else if (unten > offset + position.viewportDimension) {
        offset = unten - position.viewportDimension;
      }
      offset = offset
          .clamp(position.minScrollExtent, position.maxScrollExtent)
          .toDouble();
      if ((offset - position.pixels).abs() > 1) {
        await _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    }
    if (!mounted || _speichert || auftrag != _fokusAuftrag) {
      return;
    }
    final naechsteId = sichtbar[ziel].id;
    _fokus[naechsteId]!.requestFocus();
    final controller = _controller[naechsteId]!;
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: controller.text.length,
    );
  }

  Future<void> _schliessen(bool gespeichert) async {
    if (!mounted) {
      return;
    }
    setState(() {
      _darfSchliessen = true;
      _speichert = false;
    });
    // PopScope muss den geänderten canPop-Wert erst im nächsten Frame erhalten.
    await WidgetsBinding.instance.endOfFrame;
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      Navigator.of(context).pop(gespeichert);
    }
  }

  Future<void> _verlassen() async {
    if (_speichert || _rueckfrageOffen || _darfSchliessen) {
      return;
    }
    _fokusAuftrag++;
    if (!_entwurf.hatAenderungen) {
      await _schliessen(false);
      return;
    }
    _rueckfrageOffen = true;
    FocusScope.of(context).unfocus();
    final verwerfen = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text(
          'Die geänderten Sortiernamen sind noch nicht gespeichert. '
          'Möchtest du ohne Speichern zurückgehen?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Weiter bearbeiten'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Verwerfen'),
          ),
        ],
      ),
    );
    _rueckfrageOffen = false;
    if (mounted && verwerfen == true) {
      await _schliessen(false);
    }
  }

  Future<void> _speichern() async {
    if (_speichert || _darfSchliessen || !_entwurf.hatAenderungen) {
      return;
    }
    _fokusAuftrag++;
    final aenderungen = _entwurf.aenderungen;
    FocusScope.of(context).unfocus();
    setState(() {
      _speichert = true;
      _speicherFehler = null;
    });
    try {
      await widget.onSpeichern(aenderungen);
      if (!mounted) {
        return;
      }
      await _schliessen(true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _speichert = false;
        _speicherFehler =
            'Speichern fehlgeschlagen. Deine Eingaben bleiben hier erhalten. '
            'Bitte erneut versuchen. (${e.runtimeType})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final sichtbar = _entwurf.filtern(_suche);
    final anzahl = _entwurf.anzahlAenderungen;

    return PopScope<bool>(
      canPop: !_speichert && (_darfSchliessen || !_entwurf.hatAenderungen),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          unawaited(_verlassen());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text('Künstler-Sortiernamen'),
          leading: IconButton(
            tooltip: 'Zurück zum Labor',
            onPressed: _speichert ? null : _verlassen,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Personen: Nachname, Vorname. Bandnamen können bleiben. '
                          'Ein leeres Feld verwendet wieder den TIDAL-Namen. '
                          'Die Anzeigenamen bleiben unverändert.',
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          key: const ValueKey('sortierung-suche'),
                          controller: _sucheController,
                          focusNode: _suchFokus,
                          enabled: !_speichert,
                          textInputAction: TextInputAction.search,
                          onChanged: _sucheAendern,
                          onSubmitted: (_) => FocusScope.of(context).unfocus(),
                          decoration: InputDecoration(
                            labelText: 'Künstler suchen',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _suche.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Suche leeren',
                                    onPressed: () {
                                      _sucheController.clear();
                                      _sucheAendern('');
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                            border: const OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${sichtbar.length} von ${_entwurf.zeilen.length} Künstlern · '
                          '$anzahl ${anzahl == 1 ? 'Änderung' : 'Änderungen'}',
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Text(
                            'Künstler',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 6,
                          child: Text(
                            'Sortiername',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: sichtbar.isEmpty
                        ? Center(
                            child: Text(
                              _entwurf.zeilen.isEmpty
                                  ? 'Noch keine Künstler in der lokalen Bibliothek.'
                                  : 'Keine passenden Künstler.',
                            ),
                          )
                        : ListView.builder(
                            key: const ValueKey('sortierung-liste'),
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            itemExtent: _zeilenHoehe,
                            itemCount: sichtbar.length,
                            findChildIndexCallback: (key) {
                              if (key is! ValueKey<String>) {
                                return null;
                              }
                              final index = sichtbar.indexWhere(
                                (z) => z.id == key.value,
                              );
                              return index < 0 ? null : index;
                            },
                            itemBuilder: (context, index) => _zeile(
                              sichtbar[index],
                              index == sichtbar.length - 1,
                            ),
                          ),
                  ),
                  const Divider(height: 1),
                  // Im Body, nicht als Overlay: Dieser Bereich rückt beim
                  // Öffnen der Bildschirmtastatur mit nach oben.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_speicherFehler != null) ...[
                          Text(
                            _speicherFehler!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: 12,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (_speichert)
                              const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            TextButton(
                              key: const ValueKey('sortierung-abbrechen'),
                              onPressed: _speichert ? null : _verlassen,
                              child: const Text('Abbrechen'),
                            ),
                            FilledButton.icon(
                              key: const ValueKey('sortierung-speichern'),
                              focusNode: _speichernFokus,
                              onPressed: _speichert || anzahl == 0
                                  ? null
                                  : _speichern,
                              icon: const Icon(Icons.save_outlined),
                              label: Text(
                                _speichert
                                    ? 'Wird gespeichert …'
                                    : '$anzahl ${anzahl == 1 ? 'Änderung' : 'Änderungen'} speichern',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _zeile(KuenstlerSortierZeile zeile, bool letzte) {
    final geaendert = _entwurf.istGeaendert(zeile.id);
    final eigenerName = zeile.anzeigename != zeile.tidalName;
    return Padding(
      key: ValueKey(zeile.id),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  zeile.anzeigename,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (eigenerName)
                  Text(
                    'TIDAL: ${zeile.tidalName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                if (geaendert)
                  Text(
                    'geändert',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: CallbackShortcuts(
              bindings: {
                const SingleActivator(LogicalKeyboardKey.tab): () =>
                    unawaited(_fokusVerschieben(zeile.id, 1)),
                const SingleActivator(
                  LogicalKeyboardKey.tab,
                  shift: true,
                ): () =>
                    unawaited(_fokusVerschieben(zeile.id, -1)),
              },
              child: TextField(
                key: ValueKey('sortiername-${zeile.id}'),
                controller: _controller[zeile.id],
                focusNode: _fokus[zeile.id],
                enabled: !_speichert,
                autocorrect: false,
                enableSuggestions: false,
                maxLines: 1,
                textInputAction: letzte
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: (_) => unawaited(_fokusVerschieben(zeile.id, 1)),
                onChanged: (wert) => setState(() {
                  _entwurf.setzen(zeile.id, wert);
                  _speicherFehler = null;
                }),
                decoration: InputDecoration(
                  hintText: zeile.tidalName,
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
