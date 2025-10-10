import 'package:flutter/material.dart';
import 'package:football_news_app/features/home/pages/home_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;
  bool _navigated = false; // evita doble navegación

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _anim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();

    _goHome();
  }

  Future<void> _goHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted || _navigated) return;
    _navigated = true;

    // ⚠️ Única creación del Home con GlobalKey (usado por PushService)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => HomePage(key: homeKey)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: () async => false, // bloquea botón atrás
      child: Scaffold(
        backgroundColor: scheme.surface,
        body: Center(
          child: FadeTransition(
            opacity: _anim,
            child: ScaleTransition(
              scale: _anim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo principal
                  Image.asset(
                    'assets/Primerfoot_icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PremierFootball',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: scheme.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Noticias y Partidos en tiempo real',
                    style: TextStyle(
                      fontSize: 14,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const CircularProgressIndicator(strokeWidth: 2.5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
