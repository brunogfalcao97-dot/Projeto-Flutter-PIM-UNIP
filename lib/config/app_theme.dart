import 'package:flutter/material.dart';

import 'branding.dart';

/// Tema do app, montado a partir das cores definidas em [Branding].
class AppTheme {
  AppTheme._();

  static ThemeData get claro {
    final esquema = ColorScheme.fromSeed(seedColor: Branding.primaria).copyWith(
      primary: Branding.primaria,
      secondary: Branding.secundaria,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: Branding.fundo,
      // Barra branca: a logo tem fundo transparente e foi desenhada para fundo claro.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Branding.primaria,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black38,
        elevation: 1,
        scrolledUnderElevation: 1,
      ),
      inputDecorationTheme: const InputDecorationTheme(border: OutlineInputBorder()),
    );
  }
}
