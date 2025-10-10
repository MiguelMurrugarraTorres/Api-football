// lib/features/teams/pages/teams_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';

import 'package:football_news_app/data/models/team.dart';
import 'package:football_news_app/data/services/api_service.dart';
import 'package:football_news_app/features/home/pages/home_page.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';
import 'package:football_news_app/features/webview/pages/in_app_webview_page.dart';


class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});

  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final ApiService _api = ApiService();

  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  bool _loading = true;
  String? _error;

  List<TeamItem> _all = [];
  List<TeamItem> _display = [];

  // Filtro alfabético
  final List<String> _letters = ['#', ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split('')];
  String _selectedLetter = 'A';

  @override
  void initState() {
    super.initState();
    _fetchAll();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final rows = await _api.fetchTeamsRaw();          // ← await remoto
      if (!mounted) return;                             // 👈 guard
      _all = rows.map((e) => TeamItem.fromJson(e)).toList();
      _applyLetterFilter(_selectedLetter, callSetState: false);
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;                             // 👈 guard
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      if (!mounted) return;                             // 👈 guard por si navegaste
      final q = _searchCtrl.text.trim();
      if (q.isEmpty) {
        _applyLetterFilter(_selectedLetter);
        return;
      }
      try {
        final rows = await _api.searchTeamsV2(q);       // ← await remoto
        if (!mounted) return;                           // 👈 guard
        final list = rows.map((e) => TeamItem.fromJson(e)).toList();
        setState(() {
          _display = list;
        });
      } catch (_) {
        // ante error, deja el estado anterior
      }
    });
  }

  void _applyLetterFilter(String letter, {bool callSetState = true}) {
    _selectedLetter = letter;
    if (letter == '#') {
      // No alfabéticos (números, símbolos)
      _display = _all
          .where((t) => t.displayName.isNotEmpty)
          .where((t) {
            final c = t.displayName.characters.first.toUpperCase();
            return !RegExp(r'[A-Z]').hasMatch(c);
          })
          .toList();
    } else {
      _display = _all
          .where((t) =>
              t.displayName.isNotEmpty &&
              t.displayName.toUpperCase().startsWith(letter))
          .toList();
    }
    if (callSetState && mounted) setState(() {});
  }

  void _openTeam(TeamItem t) {
    final raw = t.href.trim();
    if (raw.isEmpty) return;

    final url = (raw.startsWith('http://') || raw.startsWith('https://'))
        ? raw
        : 'https://$raw';
    final title = t.displayName;

    final homeState = homeKey.currentState;
    if (homeState != null) {
      homeState.openWebView(url, title: title);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => InAppWebViewPage(uri: uri, title: title)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
            ? _ErrorState(message: _error!)
            : Column(
                children: [
                  const SizedBox(height: 8),
                  _SearchBar(controller: _searchCtrl),
                  const SizedBox(height: 8),
                  _LettersBar(
                    letters: _letters,
                    selected: _selectedLetter,
                    onTap: (l) {
                      _searchCtrl.clear();
                      _applyLetterFilter(l);
                    },
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: _display.isEmpty
                        ? const _EmptyState()
                        : ListView.separated(
                            itemCount: _display.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final t = _display[i];
                              return ListTile(
                                leading: ClipOval(
                                  child: (t.logoUrl ?? '').isNotEmpty
                                      ? Image.network(
                                          t.logoUrl!,
                                          width: 32,
                                          height: 32,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _logoPlaceholder(),
                                        )
                                      : _logoPlaceholder(),
                                ),
                                title: Text(
                                  t.displayName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: (t.country ?? '').isNotEmpty
                                    ? Text(t.country!)
                                    : null,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openTeam(t),
                              );
                            },
                          ),
                  ),
                ],
              );

    return Scaffold(
      appBar: AppBar(title: const Text('Equipos')),
      body: body,
      bottomNavigationBar: BottomNavigationWidget(
        selectedIndex: 0,
        selectedLabel: 'Equipos',
        onItemTapped: (i) {
          if (i == 0) {
            // Inicio
            Navigator.of(context).popUntil((r) => r.isFirst);
          } else if (i == 1) {
            // Partidos
            Navigator.of(context).pushReplacementNamed('/matches');
          } else if (i == 2) {
            // Equipos (ya estás)
          } else if (i == 3) {
            // Competiciones (placeholder)
            Navigator.of(context).pushReplacementNamed('/competitions');
          }
        },
      ),
    );
  }

  Widget _logoPlaceholder() => Container(
        width: 32,
        height: 32,
        color: Colors.grey.shade200,
        child: const Icon(Icons.shield_outlined, size: 18, color: Colors.grey),
      );
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Buscar equipo…',
          prefixIcon: const Icon(Icons.search),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

class _LettersBar extends StatelessWidget {
  final List<String> letters;
  final String selected;
  final ValueChanged<String> onTap;

  const _LettersBar({
    required this.letters,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        scrollDirection: Axis.horizontal,
        itemCount: letters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final l = letters[i];
          final isSel = l == selected;
          return ChoiceChip(
            label: Text(l),
            selected: isSel,
            onSelected: (_) => onTap(l),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            selectedColor:
                Theme.of(context).colorScheme.primary.withOpacity(0.15),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error cargando equipos.\n$message',
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No hay equipos para mostrar.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      );
}
