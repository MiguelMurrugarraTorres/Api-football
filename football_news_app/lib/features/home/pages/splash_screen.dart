// lib/features/home/pages/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:football_news_app/main.dart'; // usa homeKey y MyHomePage

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _anim;

  bool _navigated = false; // 👈 guard para evitar doble navegación

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

    // ⚠️ Esta es la ÚNICA creación del Home con el GlobalKey
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => MyHomePage(key: homeKey)),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // bloquea back en el splash
      child: Scaffold(
        body: Container(
          color: const Color.fromARGB(255, 245, 245, 245),
          alignment: Alignment.center,
          child: FadeTransition(
            opacity: _anim,
            child: ScaleTransition(
              scale: _anim,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/Primerfoot_icon.png',
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'PremierFootball',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
