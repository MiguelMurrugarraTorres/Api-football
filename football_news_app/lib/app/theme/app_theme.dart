// lib/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Cambia este color y toda la app (light/dark) se re-deriva sola.
const Color kBrandSeed = Color.fromARGB(255, 218, 24, 24); //negro

// app_theme.dart
class AppTheme {
  static ThemeData light({Color seed = kBrandSeed}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) =>  const Color(0xFF111111),
          ),
          foregroundColor: MaterialStateProperty.all(Colors.white),
          shape: MaterialStateProperty.all(const StadiumBorder()),
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
          textStyle: MaterialStateProperty.all(
            const TextStyle(letterSpacing: .5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  static ThemeData dark({Color seed = kBrandSeed}) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      appBarTheme: AppBarTheme(backgroundColor: scheme.surface, foregroundColor: scheme.onSurface),
            elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith(
            (states) =>  const Color.fromARGB(255, 255, 255, 255),
          ),
          foregroundColor: MaterialStateProperty.all(const Color.fromARGB(255, 0, 0, 0)),
          shape: MaterialStateProperty.all(const StadiumBorder()),
          minimumSize: MaterialStateProperty.all(const Size.fromHeight(48)),
          textStyle: MaterialStateProperty.all(
            const TextStyle(letterSpacing: .5, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

