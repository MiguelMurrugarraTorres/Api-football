// lib/features/matches/pages/matches_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:football_news_app/data/models/match.dart';
import 'package:football_news_app/data/services/api_service.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  final ApiService _api = ApiService();

  late List<_DateChip> _chips;
  late _DateChip _selected;
  bool _loading = true;
  String? _error;

  List<MatchItem> _matches = [];

  @override
  void initState() {
    super.initState();
    _chips = _buildChips();
    _selected = _chips.firstWhere((c) => c.kind == _DateKind.today);
    _loadFor(_selected);
  }

  // === Fecha / chips ===
  List<_DateChip> _buildChips() {
    final nowUtc = DateTime.now().toUtc();
    DateTime d(int offset) => nowUtc.add(Duration(days: offset));

    String key(DateTime x) => DateFormat('yyyy-MM-dd').format(x);
    String label(DateTime x, int offset) {
      if (offset == -1) return 'Ayer';
      if (offset == 0) return 'Hoy';
      if (offset == 1) return 'Mañana';
      return DateFormat('EEE d MMM', 'es_PE').format(x); // ej: vie 10 oct
    }

    return [
      _DateChip(
          kind: _DateKind.yesterday,
          dateKey: key(d(-1)),
          label: label(d(-1), -1)),
      _DateChip(
          kind: _DateKind.today, dateKey: key(d(0)), label: label(d(0), 0)),
      _DateChip(
          kind: _DateKind.tomorrow, dateKey: key(d(1)), label: label(d(1), 1)),
      _DateChip(
          kind: _DateKind.other, dateKey: key(d(2)), label: label(d(2), 2)),
      _DateChip(
          kind: _DateKind.other, dateKey: key(d(3)), label: label(d(3), 3)),
    ];
  }

  Future<void> _loadFor(_DateChip chip) async {
    setState(() {
      _selected = chip;
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.fetchMatches(date: chip.dateKey);
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

  Map<String, List<MatchItem>> _groupByLeague(List<MatchItem> list) {
    final map = <String, List<MatchItem>>{};
    for (final m in list) {
      (map[m.compName] ??= []).add(m);
    }
    return map;
  }

  // === Helpers de formato ===
  String _formatKickoffLocal(String kickoffUtc) {
    if (kickoffUtc.isEmpty) return '';
    try {
      // Soporta ISO completo o "HH:mm"
      DateTime dt;
      if (kickoffUtc.contains('T')) {
        dt = DateTime.parse(kickoffUtc).toLocal();
      } else {
        // si solo viene "HH:mm", muéstralo tal cual
        return kickoffUtc;
      }
      return DateFormat('HH:mm').format(dt);
    } catch (_) {
      return '';
    }
  }

  bool _isNotStarted(String status) {
    final s = status.toUpperCase();
    return s == 'NS' || s.contains('POR EMPEZAR') || s.contains('NO INICIA');
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorState(message: _error!)
            : _matches.isEmpty
                ? _EmptyState(dateLabel: _selected.label)
                : _MatchesGroupedList(
                    grouped: _groupByLeague(_matches),
                    formatKickoffLocal: _formatKickoffLocal,
                    isNotStarted: _isNotStarted,
                  );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidos'),
        actions: [
          IconButton(
            onPressed: () {/* filtros futuros */},
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          _DateChipsBar(
            chips: _chips,
            selected: _selected,
            onTap: (c) => _loadFor(c),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _pullRefresh,
              child: body,
            ),
          ),
          const SizedBox(height: 4),
          _ClassificationRow(onTap: () {
            // TODO: navegar a standings si agregas endpoint/ruta
          }),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// === UI ===

class _DateChipsBar extends StatelessWidget {
  final List<_DateChip> chips;
  final _DateChip selected;
  final ValueChanged<_DateChip> onTap;

  const _DateChipsBar({
    required this.chips,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final c = chips[i];
          final isSel = c == selected;
          return ChoiceChip(
            label: Text(c.label),
            selected: isSel,
            onSelected: (_) => onTap(c),
            selectedColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
            labelStyle: TextStyle(
              fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
            ),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }
}

class _MatchesGroupedList extends StatelessWidget {
  final Map<String, List<MatchItem>> grouped;
  final String Function(String kickoffUtc) formatKickoffLocal;
  final bool Function(String status) isNotStarted;

  const _MatchesGroupedList({
    required this.grouped,
    required this.formatKickoffLocal,
    required this.isNotStarted,
  });

  @override
  Widget build(BuildContext context) {
    final leagues = grouped.keys.toList()..sort();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: leagues.length,
      itemBuilder: (context, idx) {
        final league = leagues[idx];
        final items = grouped[league]!;
        return _LeagueSection(
          league: league,
          items: items,
          formatKickoffLocal: formatKickoffLocal,
          isNotStarted: isNotStarted,
        );
      },
    );
  }
}

class _LeagueSection extends StatelessWidget {
  final String league;
  final List<MatchItem> items;
  final String Function(String) formatKickoffLocal;
  final bool Function(String) isNotStarted;

  const _LeagueSection({
    required this.league,
    required this.items,
    required this.formatKickoffLocal,
    required this.isNotStarted,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = items.first.roundText;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de liga
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(league, style: Theme.of(context).textTheme.titleMedium),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: Theme.of(context)
                      .textTheme
                      .labelMedium
                      ?.copyWith(color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Lista de partidos
        ...items.map((m) => _MatchTile(
              item: m,
              timeOrStatus: isNotStarted(
                      m.statusText.isNotEmpty ? m.statusText : m.status)
                  ? formatKickoffLocal(m.kickoffUtc)
                  : (m.statusText.isNotEmpty ? m.statusText : m.status),
            )),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchItem item;
  final String timeOrStatus;

  const _MatchTile({required this.item, required this.timeOrStatus});

  @override
  Widget build(BuildContext context) {
    final hs = item.homeScore;
    final as_ = item.awayScore;

    String scoreText(int? v) => v?.toString() ?? '-';

    return InkWell(
      onTap: () {
        // TODO: abrir ficha del partido en tu WebView usando item.href
        // Usa tu patrón de artículos: Navigator.push a InAppWebViewPage(...)
        // o, si estás en MyHomePage, homeKey.currentState?.openWebView(item.href);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            // Logos + nombres (dos filas)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TeamRow(name: item.homeName, logo: item.homeLogo),
                  const SizedBox(height: 8),
                  _TeamRow(name: item.awayName, logo: item.awayLogo),
                ],
              ),
            ),

            // Marcador centrado
            SizedBox(
              width: 56,
              child: Center(
                child: Text(
                  '${scoreText(hs)}  -  ${scoreText(as_)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),

            // Hora local o estado (alineado derecha)
            SizedBox(
              width: 80,
              child: Text(
                timeOrStatus,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  final String name;
  final String logo;
  const _TeamRow({required this.name, required this.logo});

  @override
  Widget build(BuildContext context) {
    final has = logo.isNotEmpty;
    return Row(
      children: [
        ClipOval(
          child: has
              ? Image.network(
                  logo,
                  width: 28,
                  height: 28,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
        width: 28,
        height: 28,
        color: Colors.grey.shade200,
        child: const Icon(Icons.shield_outlined, size: 16, color: Colors.grey),
      );
}

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

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.wifi_off, size: 56, color: Colors.grey.shade600),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No se pudieron cargar los partidos.\n$message',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String dateLabel;
  const _EmptyState({required this.dateLabel});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.sports_soccer_outlined,
            size: 56, color: Colors.grey.shade600),
        const SizedBox(height: 12),
        Center(
          child: Text(
            'No hay partidos para $dateLabel.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}

// === Tipos auxiliares ===
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
      other is _DateChip &&
          runtimeType == other.runtimeType &&
          dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}
