/// Resposta de POST /api/calculos/tinta: tudo calculado pela API.

class ItemOpcao {
  const ItemOpcao({
    required this.produtoId,
    required this.sku,
    required this.descricao,
    required this.volumeLitros,
    required this.quantidade,
    required this.precoUnitario,
    required this.subtotal,
  });

  final int produtoId;
  final String sku;
  final String descricao;
  final double volumeLitros;
  final int quantidade;
  final double precoUnitario;
  final double subtotal;

  factory ItemOpcao.fromJson(Map<String, dynamic> json) => ItemOpcao(
        produtoId: (json['produtoId'] as num).toInt(),
        sku: json['sku'].toString(),
        descricao: json['descricao'].toString(),
        volumeLitros: (json['volumeLitros'] as num).toDouble(),
        quantidade: (json['quantidade'] as num).toInt(),
        precoUnitario: (json['precoUnitario'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
      );
}

/// Uma forma de comprar a quantidade necessária (a mais barata de uma marca).
class OpcaoCompra {
  const OpcaoCompra({
    required this.marcaId,
    required this.marcaNome,
    required this.itens,
    required this.litrosComprados,
    required this.sobraLitros,
    required this.total,
  });

  final int marcaId;
  final String marcaNome;
  final List<ItemOpcao> itens;
  final double litrosComprados;
  final double sobraLitros;
  final double total;

  factory OpcaoCompra.fromJson(Map<String, dynamic> json) => OpcaoCompra(
        marcaId: (json['marcaId'] as num).toInt(),
        marcaNome: json['marcaNome'].toString(),
        itens: (json['itens'] as List)
            .map((e) => ItemOpcao.fromJson(e as Map<String, dynamic>))
            .toList(),
        litrosComprados: (json['litrosComprados'] as num).toDouble(),
        sobraLitros: (json['sobraLitros'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

class CalculoTinta {
  const CalculoTinta({
    required this.areaBrutaM2,
    required this.areaDescontadaM2,
    required this.areaLiquidaM2,
    required this.demaos,
    required this.rendimentoM2PorLitro,
    required this.margemPerdaPercentual,
    required this.litrosNecessarios,
    required this.tipoTintaNome,
    required this.opcoes,
    this.aviso,
  });

  final double areaBrutaM2;
  final double areaDescontadaM2;
  final double areaLiquidaM2;
  final int demaos;
  final double rendimentoM2PorLitro;
  final double margemPerdaPercentual;
  final double litrosNecessarios;
  final String tipoTintaNome;
  final String? aviso;
  final List<OpcaoCompra> opcoes;

  factory CalculoTinta.fromJson(Map<String, dynamic> json) => CalculoTinta(
        areaBrutaM2: (json['areaBrutaM2'] as num).toDouble(),
        areaDescontadaM2: (json['areaDescontadaM2'] as num).toDouble(),
        areaLiquidaM2: (json['areaLiquidaM2'] as num).toDouble(),
        demaos: (json['demaos'] as num).toInt(),
        rendimentoM2PorLitro: (json['rendimentoM2PorLitro'] as num).toDouble(),
        margemPerdaPercentual: (json['margemPerdaPercentual'] as num).toDouble(),
        litrosNecessarios: (json['litrosNecessarios'] as num).toDouble(),
        tipoTintaNome: json['tipoTintaNome'].toString(),
        aviso: json['aviso']?.toString(),
        opcoes: (json['opcoes'] as List)
            .map((e) => OpcaoCompra.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
