import 'package:flutter/painting.dart' show Color;

/// Converte "#RRGGBB" (ou "#RGB") em um inteiro 0xRRGGBB. Valor inválido vira preto, sem derrubar o app.
int hexParaRgb(String codigoHex) {
  try {
    var hex = codigoHex.replaceAll('#', '').trim();
    if (hex.length == 3) hex = hex.split('').map((c) => '$c$c').join();
    return int.parse(hex.substring(0, 6), radix: 16);
  } catch (_) {
    return 0;
  }
}

/// Cor do catálogo (GET /api/cores).
class Cor {
  const Cor({
    required this.id,
    required this.nome,
    required this.codigoHex,
    required this.rgb,
    this.familia,
    this.codigoPantone,
  });

  final int id;
  final String nome;
  final String codigoHex;

  /// Valor 0xRRGGBB usado pelo algoritmo de pintura.
  final int rgb;
  final String? familia;
  final String? codigoPantone;

  factory Cor.fromJson(Map<String, dynamic> json) {
    final hex = json['codigoHex'].toString();
    final rgbJson = json['rgb'];

    // A API já manda o RGB separado; se vier faltando, calcula a partir do HEX.
    final int valor;
    if (rgbJson is Map<String, dynamic>) {
      valor = ((rgbJson['r'] as num).toInt() << 16) |
          ((rgbJson['g'] as num).toInt() << 8) |
          (rgbJson['b'] as num).toInt();
    } else {
      valor = hexParaRgb(hex);
    }

    return Cor(
      id: (json['id'] as num).toInt(),
      nome: json['nome'].toString(),
      codigoHex: hex,
      rgb: valor,
      familia: json['familia']?.toString(),
      codigoPantone: json['codigoPantone']?.toString(),
    );
  }

  /// Cor montada só com o que o histórico guarda (id, nome e HEX).
  factory Cor.simples(int id, String nome, String codigoHex) =>
      Cor(id: id, nome: nome, codigoHex: codigoHex, rgb: hexParaRgb(codigoHex));

  Color get color => Color(0xFF000000 | rgb);
}
