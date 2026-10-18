import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/branding.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'splash_screen.dart';

/// Mostra a tela de abertura enquanto o app se prepara (recupera a sessão salva
/// no aparelho) e depois troca, com uma transição suave, para a tela inicial.
class AppInicial extends StatefulWidget {
  const AppInicial({super.key});

  @override
  State<AppInicial> createState() => _AppInicialState();
}

class _AppInicialState extends State<AppInicial> {
  /// Tempo mínimo da tela de abertura, para a logo ser vista mesmo quando o
  /// app abre rápido. Pode diminuir ou aumentar à vontade.
  static const _tempoMinimo = Duration(milliseconds: 1800);

  bool _pronto = false;

  @override
  void initState() {
    super.initState();
    _preparar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Deixa a logo carregada antes da abertura, para ela não "piscar" na tela.
    precacheImage(const AssetImage(Branding.logoAsset), context, onError: (_, __) {});
  }

  Future<void> _preparar() async {
    final auth = context.read<AuthProvider>();
    await Future.wait<void>([
      auth.carregarSessao(),
      Future<void>.delayed(_tempoMinimo),
    ]);
    if (mounted) setState(() => _pronto = true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _pronto
          ? const HomeScreen(key: ValueKey('home'))
          : const SplashScreen(key: ValueKey('splash')),
    );
  }
}
