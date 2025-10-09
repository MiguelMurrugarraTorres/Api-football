// lib/features/matches/pages/matches_screen.dart
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:football_news_app/data/models/match.dart';
import 'package:football_news_app/data/services/api_service.dart';

import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';
import 'package:football_news_app/main.dart'; // homeKey para abrir WebView integrado

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

  /// ✔️ Preserva el orden que envía el backend (no ordenar aquí).
  LinkedHashMap<String, List<MatchItem>> _groupByLeague(List<MatchItem> list) {
    final map = LinkedHashMap<String, List<MatchItem>>();
    for (final m in list) {
      (map[m.compName] ??= <MatchItem>[]).add(m);
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
    // Si statusText viene vacío/null y score 0-0 → lo consideramos "Suspendido"
    return (st.isEmpty) && (hs == 0 && as_ == 0);
  }

  _StatusDisplay _computeStatus(MatchItem m) {
    // 1) Está en vivo (minuto desde backend)
    if ((m.liveMinuteText ?? '').isNotEmpty) {
      return _StatusDisplay(m.liveMinuteText!, _StatusKind.live);
    }

    // 2) Si viene statusText vacío y 0-0 => Suspendido
    if (_shouldMarkSuspended(m)) {
      return const _StatusDisplay('Suspendido', _StatusKind.suspended);
    }

    // 3) Por empezar (usa hora local)
    final textPref = (m.statusText.isNotEmpty ? m.statusText : m.status);
    if (_isNotStarted(textPref)) {
      final hhmm = _formatKickoffLocal(m.kickoffUtc);
      return _StatusDisplay(
          hhmm.isNotEmpty ? hhmm : 'Programado', _StatusKind.time);
    }

    // 4) Sino, muestra statusText/status tal cual
    return _StatusDisplay(textPref, _StatusKind.other);
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
                    computeStatus: _computeStatus,
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
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 0,
        selectedLabel: 'Partidos',
        onItemTapped: (i) {
          if (i == 0) {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        },
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
  final LinkedHashMap<String, List<MatchItem>> grouped;
  final _StatusDisplay Function(MatchItem) computeStatus;

  const _MatchesGroupedList({
    required this.grouped,
    required this.computeStatus,
  });

  @override
  Widget build(BuildContext context) {
    final leagues = grouped.keys.toList(); // 👈 sin sort()
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: leagues.length,
      itemBuilder: (context, idx) {
        final league = leagues[idx];
        final items = grouped[league]!;
        return _LeagueSection(
          league: league,
          items: items,
          computeStatus: computeStatus,
        );
      },
    );
  }
}

class _LeagueSection extends StatelessWidget {
  final String league;
  final List<MatchItem> items;
  final _StatusDisplay Function(MatchItem) computeStatus;

  const _LeagueSection({
    required this.league,
    required this.items,
    required this.computeStatus,
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
        ...items.map((m) {
          final disp = computeStatus(m);
          return _MatchTile(item: m, statusDisplay: disp);
        }),
      ],
    );
  }
}

class _MatchTile extends StatelessWidget {
  final MatchItem item;
  final _StatusDisplay statusDisplay;

  const _MatchTile({required this.item, required this.statusDisplay});

  Color _statusColor(BuildContext context) {
    switch (statusDisplay.kind) {
      case _StatusKind.live:
        return Colors.pinkAccent;
      case _StatusKind.suspended:
        return Colors.orange;
      case _StatusKind.time:
        return Colors.grey.shade700;
      case _StatusKind.other:
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hs = item.homeScore;
    final as_ = item.awayScore;

    String scoreText(int? v) => v?.toString() ?? '-';

    return InkWell(
      onTap: () {
        final raw = item.href.trim();
        if (raw.isEmpty) return;

        final url = (raw.startsWith('http://') || raw.startsWith('https://'))
            ? raw
            : 'https://$raw';
        final title = '${item.homeName} vs ${item.awayName}';

        // 1) WebView integrado si estamos en Home
        final homeState = homeKey.currentState;
        if (homeState != null) {
          homeState.openWebView(url, title: title);
          return;
        }

        // 2) fallback: pantalla propia
        final uri = Uri.tryParse(url);
        if (uri != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => InAppWebViewPage(uri: uri, title: title),
            ),
          );
        }
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

            // Estado/Minuto/Hora (alineado derecha)
            SizedBox(
              width: 84,
              child: Align(
                alignment: Alignment.centerRight,
                child: _StatusPill(
                  text: statusDisplay.text,
                  kind: statusDisplay.kind,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String text;
  final _StatusKind kind;

  const _StatusPill({
    required this.text,
    required this.kind,
  });

  @override
  Widget build(BuildContext context) {
    final color = () {
      switch (kind) {
        case _StatusKind.live:
          return Colors.pinkAccent;
        case _StatusKind.suspended:
          return Colors.orange;
        case _StatusKind.time:
        case _StatusKind.other:
        default:
          return Colors.grey.shade700;
      }
    }();

    final isLive = kind == _StatusKind.live;

    if (isLive) {
      // 🔴 • 83'
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.pinkAccent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      );
    }

    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context)
          .textTheme
          .labelSmall
          ?.copyWith(color: color, fontWeight: FontWeight.w600),
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

// === Estado mostrado (texto + tipo para color) ===
enum _StatusKind { live, time, suspended, other }

class _StatusDisplay {
  final String text;
  final _StatusKind kind;
  const _StatusDisplay(this.text, this.kind);
}
