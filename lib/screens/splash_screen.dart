import 'package:flutter/material.dart';

import '../config/branding.dart';
import '../widgets/logo_empresa.dart';

/// Tela de abertura: logo da empresa com um indicador de carregamento.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      backgroundColor: Branding.fundo,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A logo aparece com um leve efeito de entrada.
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  builder: (_, valor, filho) => Opacity(
                    opacity: valor,
                    child: Transform.scale(scale: 0.9 + 0.1 * valor, child: filho),
                  ),
                  child: const LogoEmpresa(altura: 180),
                ),
                const SizedBox(height: 36),
                const SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Carregando...',
                  style: tema.textTheme.bodyMedium?.copyWith(color: Branding.primaria),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
