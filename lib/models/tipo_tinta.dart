/// Tipo de tinta e acabamento (GET /api/tipos-tinta).
///
/// Os números técnicos vêm todos da API: o app não tem nenhuma tabela própria de rendimento ou contraste.
class TipoTinta {
  const TipoTinta({
    required this.id,
    required this.nome,
    required this.acabamento,
    this.descricao,
    this.rendimentoM2PorLitro = 0,
    this.demaosRecomendadas = 2,
    this.fatorContraste = 0.95,
  });

  final int id;
  final String nome;

  /// Fosco, acetinado ou brilhante.
  final String acabamento;
  final String? descricao;
  final double rendimentoM2PorLitro;
  final int demaosRecomendadas;

  /// Quanto do sombreamento original da foto é mantido na simulação visual (vem da API).
  final double fatorContraste;

  factory TipoTinta.fromJson(Map<String, dynamic> json) => TipoTinta(
        id: (json['id'] as num).toInt(),
        nome: json['nome'].toString(),
        acabamento: json['acabamento']?.toString() ?? '',
        descricao: json['descricao']?.toString(),
        rendimentoM2PorLitro: (json['rendimentoM2PorLitro'] as num?)?.toDouble() ?? 0,
        demaosRecomendadas: (json['demaosRecomendadas'] as num?)?.toInt() ?? 2,
        fatorContraste: (json['fatorContraste'] as num?)?.toDouble() ?? 0.95,
      );

  String get rotulo => acabamento.isEmpty ? nome : '$nome · $acabamento';
}
