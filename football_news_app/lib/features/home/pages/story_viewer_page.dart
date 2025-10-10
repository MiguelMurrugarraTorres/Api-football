// lib/features/home/pages/story_viewer_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:football_news_app/features/home/models/story_item.dart';

class StoryViewerPage extends StatefulWidget {
  final List<StoryItem> stories;
  final void Function(String url, String? title) onOpenArticle;

  const StoryViewerPage({
    super.key,
    required this.stories,
    required this.onOpenArticle,
  });

  @override
  State<StoryViewerPage> createState() => _StoryViewerPageState();
}

class _StoryViewerPageState extends State<StoryViewerPage> {
  final PageController _pageController = PageController();
  int _index = 0;

  Timer? _timer;
  double _progress = 0.0; // 0..1
  static const _durationPerStory = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    _startTicking();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startTicking() {
    _timer?.cancel();
    const tick = Duration(milliseconds: 50);
    final totalMs = _durationPerStory.inMilliseconds;
    int elapsed = 0;

    _timer = Timer.periodic(tick, (t) {
      if (!mounted) return;
      elapsed += tick.inMilliseconds;
      final value = (elapsed / totalMs).clamp(0.0, 1.0);
      setState(() => _progress = value);
      if (value >= 1.0) {
        t.cancel();
        _next();
      }
    });
  }

  void _next() {
    if (_index < widget.stories.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _prev() {
    if (_index > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  }

  void _onTapDown(TapDownDetails d, Size size) {
    final dx = d.localPosition.dx;
    if (dx < size.width * 0.33) {
      _prev();
    } else {
      _next();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = widget.stories;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _onTapDown(d, MediaQuery.of(context).size),
          child: Stack(
            children: [
              // pages
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) {
                  setState(() {
                    _index = i;
                    _progress = 0;
                  });
                  _startTicking();
                },
                itemCount: stories.length,
                itemBuilder: (_, i) {
                  final s = stories[i];
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        s.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image, color: Colors.white)),
                        loadingBuilder: (ctx, child, evt) {
                          if (evt == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          );
                        },
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.black54, Colors.transparent, Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 24,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.providerName.isEmpty ? 'OneFootball' : s.providerName,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: Colors.black87,
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                onPressed: () {
                                  Navigator.of(context).maybePop();
                                  widget.onOpenArticle(s.shareUrl, s.title);
                                },
                                child: const Text('VER ARTÍCULO COMPLETO'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              // progreso
              Positioned(
                left: 8,
                right: 8,
                top: 8,
                child: Row(
                  children: List.generate(stories.length, (i) {
                    final value = i < _index ? 1.0 : (i == _index ? _progress : 0.0);
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i == stories.length - 1 ? 0 : 6),
                        height: 3,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: FractionallySizedBox(
                          widthFactor: value,
                          alignment: Alignment.centerLeft,
                          child: Container(color: Colors.white),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // cerrar
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
