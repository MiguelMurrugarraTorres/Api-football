// lib/features/matches/pages/matches_screen.dart
import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:football_news_app/data/models/match.dart';
import 'package:football_news_app/data/services/api_service.dart';

import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/matches/widgets/league_section.dart';
import 'package:football_news_app/features/matches/widgets/match_card.dart';
import 'package:football_news_app/features/matches/widgets/matches_filter_sheet.dart';
import 'package:football_news_app/features/matches/widgets/status_kind.dart';

// NUEVOS widgets extraídos
import 'package:football_news_app/features/matches/widgets/date_chips_bar.dart';
import 'package:football_news_app/features/matches/widgets/empty_state.dart';
import 'package:football_news_app/features/matches/widgets/error_state.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ApiService _api = ApiService();

  late List<_DateChip> _chips;
  late _DateChip _selected;
  _DateChip? _customChip; // chip temporal cuando eliges fecha fuera del rango

  bool _loading = true;
  String? _error;

  MatchesFilterType _filter = MatchesFilterType.all;

  // Lista cruda devuelta por API (orden ya prioriza LIVE → programados → finalizados)
  List<MatchItem> _matches = [];

  @override
  void initState() {
    super.initState();
    _chips = _buildBaseChips(); // siempre respecto al HOY real
    _selected = _chips.firstWhere((c) => c.kind == _DateKind.today);
    _loadFor(_selected);
  }

  // === Chips base: siempre HOY real del dispositivo ===
  List<_DateChip> _buildBaseChips() {
    final nowLocal = DateTime.now();
    DateTime d(int offset) =>
        DateTime(nowLocal.year, nowLocal.month, nowLocal.day)
            .add(Duration(days: offset));

    String key(DateTime x) => DateFormat('yyyy-MM-dd').format(x);
    String label(DateTime x, int offset) {
      if (offset == -1) return 'Ayer';
      if (offset == 0) return 'Hoy';
      if (offset == 1) return 'Mañana';
      return DateFormat('EEE d MMM', 'es').format(x);
    }

    return [
      _DateChip(kind: _DateKind.yesterday, dateKey: key(d(-1)), label: label(d(-1), -1)),
      _DateChip(kind: _DateKind.today,     dateKey: key(d(0)),  label: label(d(0),  0)),
      _DateChip(kind: _DateKind.tomorrow,  dateKey: key(d(1)),  label: label(d(1),  1)),
      _DateChip(kind: _DateKind.other,     dateKey: key(d(2)),  label: label(d(2),  2)),
      _DateChip(kind: _DateKind.other,     dateKey: key(d(3)),  label: label(d(3),  3)),
    ];
  }

  // Reconstruye la vista de chips (base + chip temporal si existe)
  void _refreshChipsView() {
    _chips = [..._buildBaseChips(), if (_customChip != null) _customChip!];
  }

  String _todayKey() =>
      DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> _loadFor(_DateChip chip) async {
    setState(() {
      _selected = chip;
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.fetchMatches(date: chip.dateKey); // /api/matches?date=YYYY-MM-DD
      _matches = raw.map((e) => MatchItem.fromJson(e)).toList();
      setState(() => _loading = false);
    } catch (e) {
      _matches = [];
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pullRefresh() async => _loadFor(_selected);

  // Mantener orden del backend (NO ordenar). Agrupar por competición
  LinkedHashMap<LeagueKey, List<MatchItem>> _groupByLeague(List<MatchItem> list) {
    final map = LinkedHashMap<LeagueKey, List<MatchItem>>();
    for (final m in list) {
      final k = LeagueKey(m.compName, m.roundText, m.compLogoUrl);
      (map[k] ??= <MatchItem>[]).add(m);
    }
    return map;
  }

  // === Helpers de formato/estado ===
  String _formatKickoffLocal(String kickoffUtc) {
    if (kickoffUtc.isEmpty) return '';
    try {
      if (kickoffUtc.contains('T')) {
        return DateFormat('HH:mm').format(DateTime.parse(kickoffUtc).toLocal());
      }
      return kickoffUtc; // "HH:mm"
    } catch (_) {
      return '';
    }
  }

  bool _isNotStarted(String statusOrText) {
    final s = (statusOrText).toUpperCase();
    return s == 'NS' ||
        s.contains('POR EMPEZAR') ||
        s.contains('NO INICIA') ||
        s.contains('SCHEDULED');
  }

  bool _shouldMarkSuspended(MatchItem m) {
    final st = m.statusText.trim();
    final hs = m.homeScore ?? 0;
    final as_ = m.awayScore ?? 0;
    return (st.isEmpty) && (hs == 0 && as_ == 0);
  }

  StatusDisplay _computeStatus(MatchItem m) {
    if ((m.liveMinuteText ?? '').isNotEmpty) {
      return StatusDisplay(m.liveMinuteText!, StatusKind.live);
    }
    if (_shouldMarkSuspended(m)) {
      return const StatusDisplay('Suspendido', StatusKind.suspended);
    }
    final textPref = (m.statusText.isNotEmpty ? m.statusText : m.status);
    if (_isNotStarted(textPref)) {
      final hhmm = _formatKickoffLocal(m.kickoffUtc);
      return StatusDisplay(hhmm.isNotEmpty ? hhmm : 'Programado', StatusKind.time);
    }
    return StatusDisplay(textPref, StatusKind.other);
  }

  // Filtro “En directo ahora”
  List<MatchItem> _applyFilter(List<MatchItem> list) {
    if (_filter == MatchesFilterType.liveOnly) {
      return list.where((m) => (m.liveMinuteText ?? '').isNotEmpty).toList();
    }
    return list;
  }

  // === Calendar ===
  Future<void> _openCalendar() async {
    final today = DateTime.now();
    final initial = DateFormat('yyyy-MM-dd').parse(_selected.dateKey);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year - 2),
      lastDate: DateTime(today.year + 2),
      locale: const Locale('es', ''),
      helpText: 'Selecciona fecha',
    );
    if (picked == null) return;

    final pickedKey = DateFormat('yyyy-MM-dd').format(picked);
    final pickedLabel = DateFormat('EEE d MMM', 'es').format(picked);

    // Si eliges HOY real -> selecciona chip base "Hoy" y elimina el temporal
    if (pickedKey == _todayKey()) {
      setState(() {
        _customChip = null;
        _refreshChipsView();
        _selected = _buildBaseChips().firstWhere((c) => c.kind == _DateKind.today);
      });
      await _loadFor(_selected);
      return;
    }

    // Si no es hoy: crea/actualiza chip temporal con esa fecha
    final newCustom = _DateChip(kind: _DateKind.other, dateKey: pickedKey, label: pickedLabel);
    setState(() {
      _customChip = newCustom;
      _refreshChipsView(); // base + temporal
      _selected = newCustom;
    });
    await _loadFor(newCustom);
  }

  // === BottomSheet Filtro ===
  Future<void> _openFilter() async {
    final result = await showMatchesFilterSheet(context, current: _filter);
    if (result != null && mounted) {
      setState(() => _filter = result);
    }
  }

  bool get _isFilterActive => _filter == MatchesFilterType.liveOnly;

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_matches);

    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? ErrorState(message: _error!)
            : filtered.isEmpty
                ? EmptyState(dateLabel: _selected.label)
                : (_filter == MatchesFilterType.all)
                    ? _MatchesGroupedList(
                        grouped: _groupByLeague(filtered),
                        computeStatus: _computeStatus,
                      )
                    : _MatchesFlatList(
                        items: filtered,
                        computeStatus: _computeStatus,
                      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos'),
        actions: [
          IconButton(icon: const Icon(Icons.calendar_month), onPressed: _openCalendar),
          if (_isFilterActive)
            IconButton(
              tooltip: 'Quitar filtro',
              icon: const Icon(Icons.filter_alt_off),
              onPressed: () => setState(() => _filter = MatchesFilterType.all),
            ),
          IconButton(icon: const Icon(Icons.tune), onPressed: _openFilter),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          DateChipsBar(
            chips: _chips,
            selected: _selected,
            onTap: (c) {
              // Si se toca un chip base, elimina el chip temporal
              if (_customChip != null && c != _customChip) {
                setState(() {
                  _customChip = null;
                  _refreshChipsView();
                });
              }
              _loadFor(c);
            },
            labelOf: (c) => c.label, // 👈 aquí
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(onRefresh: _pullRefresh, child: body),
          ),
          const SizedBox(height: 4),
          _ClassificationRow(onTap: () {/* TODO standings */}),
          const SizedBox(height: 4),
        ],
      ),
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 0,
        selectedLabel: 'Partidos',
        onItemTapped: (i) {
          if (i == 0) Navigator.of(context).pushReplacementNamed('/home');
        },
      ),
    );
  }
}

// === Listas ===

class _MatchesGroupedList extends StatelessWidget {
  final LinkedHashMap<LeagueKey, List<MatchItem>> grouped;
  final StatusDisplay Function(MatchItem) computeStatus;

  const _MatchesGroupedList({
    required this.grouped,
    required this.computeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final leagues = grouped.keys.toList(); // sin sort()
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: leagues.length,
      itemBuilder: (context, idx) {
        final key = leagues[idx];
        final items = grouped[key]!;
        return LeagueSection(
          league: key,
          items: items,
          computeStatus: computeStatus,
        );
      },
    );
  }
}

class _MatchesFlatList extends StatelessWidget {
  final List<MatchItem> items;
  final StatusDisplay Function(MatchItem) computeStatus;

  const _MatchesFlatList({required this.items, required this.computeStatus});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      itemCount: items.length,
      itemBuilder: (context, i) =>
          MatchCard(item: items[i], statusDisplay: computeStatus(items[i])),
    );
  }
}

// === Otros widgets pequeños ===

class _ClassificationRow extends StatelessWidget {
  final VoidCallback onTap;
  const _ClassificationRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Ver clasificación'),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
    );
  }
}

// === Tipos auxiliares (internos de pantalla) ===

enum _DateKind { yesterday, today, tomorrow, other }

class _DateChip {
  final _DateKind kind;
  final String dateKey; // YYYY-MM-DD
  final String label;

  const _DateChip({
    required this.kind,
    required this.dateKey,
    required this.label,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _DateChip && dateKey == other.dateKey);

  @override
  int get hashCode => dateKey.hashCode;
}
