/// Projeto salvo pelo cliente (GET /api/simulacoes).
///
/// A foto é privada: baixe com o token em [imagemUrl] (caminho relativo da API).
class Simulacao {
  const Simulacao({
    required this.id,
    required this.criadoEm,
    required this.corId,
    required this.corNome,
    required this.corHex,
    required this.tipoTintaId,
    required this.tipoTintaNome,
    required this.imagemUrl,
    this.nome,
    this.areaM2,
  });

  final int id;
  final DateTime criadoEm;
  final String? nome;
  final double? areaM2;
  final int corId;
  final String corNome;
  final String corHex;
  final int tipoTintaId;
  final String tipoTintaNome;
  final String imagemUrl;

  factory Simulacao.fromJson(Map<String, dynamic> json) => Simulacao(
        id: (json['id'] as num).toInt(),
        criadoEm: DateTime.tryParse('${json['criadoEm']}') ?? DateTime.now(),
        nome: json['nome']?.toString(),
        areaM2: (json['areaM2'] as num?)?.toDouble(),
        corId: (json['corId'] as num).toInt(),
        corNome: json['corNome'].toString(),
        corHex: json['corHex'].toString(),
        tipoTintaId: (json['tipoTintaId'] as num).toInt(),
        tipoTintaNome: json['tipoTintaNome'].toString(),
        imagemUrl: json['imagemUrl'].toString(),
      );
}
