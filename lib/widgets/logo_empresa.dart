import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import '../config/branding.dart';

/// Mostra a logo da empresa (assets/images/logo.png).
///
/// Se o arquivo não puder ser carregado, mostra o nome da empresa (com um
/// ícone, se não for [compacto]) no lugar e registra o motivo no terminal, então
/// o app continua funcionando mesmo sem a logo.
class LogoEmpresa extends StatelessWidget {
  const LogoEmpresa({super.key, this.altura = 80, this.compacto = false});

  final double altura;

  /// true: na falta da logo, mostra só o nome (bom para a barra do topo).
  final bool compacto;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      Branding.logoAsset,
      height: altura,
      fit: BoxFit.contain,
      errorBuilder: (contexto, erro, _) {
        debugPrint('Logo não carregou (${Branding.logoAsset}): $erro');
        return _alternativa(contexto);
      },
    );
  }

  Widget _alternativa(BuildContext context) {
    final cor = Theme.of(context).colorScheme.primary;
    final nome = Text(
      Branding.nomeEmpresa,
      style: TextStyle(
        fontSize: compacto ? 20 : 26,
        fontWeight: FontWeight.bold,
        color: cor,
      ),
    );
    if (compacto) return nome;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.format_paint, size: altura * 0.7, color: cor),
        const SizedBox(height: 8),
        nome,
      ],
    );
  }
}
