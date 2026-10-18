import 'package:flutter/material.dart';

/// Identidade visual da empresa.
///
/// Para mudar nome, logo ou cores do app, altere só este arquivo e substitua
/// a logo em assets/images/logo.png.
class Branding {
  Branding._();

  /// Nome mostrado no app quando a logo não puder ser carregada.
  static const String nomeEmpresa = 'FixTintas';

  /// Arquivo da logo (PNG com fundo transparente).
  static const String logoAsset = 'assets/images/logo.png';

  // ---- Cores da marca ------------------------------------------------------

  /// Azul da marca: botões, ícones, links e destaques.
  static const Color primaria = Color(0xFF1A2A6C);

  /// Laranja de apoio, tirado da logo (usado em detalhes).
  static const Color secundaria = Color(0xFFFF8700);

  /// Fundo das telas.
  static const Color fundo = Color(0xFFFFFFFF);
}
