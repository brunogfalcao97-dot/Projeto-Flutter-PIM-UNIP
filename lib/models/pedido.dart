/// Item guardado no carrinho do aparelho. Os textos são só para mostrar a lista
/// quando a API está fora do ar; preços e totais vêm sempre do orçamento da API.
class ItemCarrinho {
  const ItemCarrinho({
    required this.produtoId,
    required this.corId,
    required this.quantidade,
    required this.descricao,
    required this.corNome,
    required this.corHex,
  });

  final int produtoId;
  final int corId;
  final int quantidade;
  final String descricao;
  final String corNome;
  final String corHex;

  ItemCarrinho comQuantidade(int nova) => ItemCarrinho(
        produtoId: produtoId,
        corId: corId,
        quantidade: nova,
        descricao: descricao,
        corNome: corNome,
        corHex: corHex,
      );

  bool mesmoItem(int outroProdutoId, int outraCorId) => produtoId == outroProdutoId && corId == outraCorId;

  factory ItemCarrinho.fromJson(Map<String, dynamic> json) => ItemCarrinho(
        produtoId: (json['produtoId'] as num).toInt(),
        corId: (json['corId'] as num).toInt(),
        quantidade: (json['quantidade'] as num).toInt(),
        descricao: json['descricao']?.toString() ?? '',
        corNome: json['corNome']?.toString() ?? '',
        corHex: json['corHex']?.toString() ?? '#CCCCCC',
      );

  Map<String, dynamic> toJson() => {
        'produtoId': produtoId,
        'corId': corId,
        'quantidade': quantidade,
        'descricao': descricao,
        'corNome': corNome,
        'corHex': corHex,
      };

  /// Formato que a API espera em POST /api/pedidos e /api/pedidos/orcamento.
  Map<String, dynamic> paraApi() => {
        'produtoId': produtoId,
        'corId': corId,
        'quantidade': quantidade,
      };
}

class LinhaPedido {
  const LinhaPedido({
    required this.produtoId,
    required this.produtoDescricao,
    required this.volumeLitros,
    required this.corId,
    required this.corNome,
    required this.corHex,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
  });

  final int produtoId;
  final String produtoDescricao;
  final double volumeLitros;
  final int corId;
  final String corNome;
  final String corHex;
  final int quantidade;
  final double precoUnitario;
  final double total;

  factory LinhaPedido.fromJson(Map<String, dynamic> json) => LinhaPedido(
        produtoId: (json['produtoId'] as num).toInt(),
        produtoDescricao: json['produtoDescricao'].toString(),
        volumeLitros: (json['volumeLitros'] as num).toDouble(),
        corId: (json['corId'] as num).toInt(),
        corNome: json['corNome'].toString(),
        corHex: json['corHex'].toString(),
        quantidade: (json['quantidade'] as num).toInt(),
        precoUnitario: (json['precoUnitario'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
      );
}

/// "Quanto custa?": POST /api/pedidos/orcamento. Valores calculados pela API.
class Orcamento {
  const Orcamento({
    required this.itens,
    required this.litrosTotais,
    required this.subtotal,
    required this.descontoVolume,
    required this.descontoCupom,
    required this.total,
    this.cupom,
  });

  final List<LinhaPedido> itens;
  final double litrosTotais;
  final double subtotal;
  final double descontoVolume;
  final double descontoCupom;
  final double total;
  final String? cupom;

  factory Orcamento.fromJson(Map<String, dynamic> json) => Orcamento(
        itens: (json['itens'] as List)
            .map((e) => LinhaPedido.fromJson(e as Map<String, dynamic>))
            .toList(),
        litrosTotais: (json['litrosTotais'] as num).toDouble(),
        subtotal: (json['subtotal'] as num).toDouble(),
        descontoVolume: (json['descontoVolume'] as num).toDouble(),
        descontoCupom: (json['descontoCupom'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        cupom: json['cupom']?.toString(),
      );

  /// Procura a linha do orçamento que corresponde a um item do carrinho.
  LinhaPedido? linhaDe(ItemCarrinho item) {
    for (final linha in itens) {
      if (linha.produtoId == item.produtoId && linha.corId == item.corId) return linha;
    }
    return null;
  }
}

class PedidoResumo {
  const PedidoResumo({
    required this.id,
    required this.criadoEm,
    required this.status,
    required this.total,
    required this.quantidadeItens,
  });

  final int id;
  final DateTime criadoEm;
  final String status;
  final double total;
  final int quantidadeItens;

  factory PedidoResumo.fromJson(Map<String, dynamic> json) => PedidoResumo(
        id: (json['id'] as num).toInt(),
        criadoEm: DateTime.tryParse('${json['criadoEm']}') ?? DateTime.now(),
        status: json['status'].toString(),
        total: (json['total'] as num).toDouble(),
        quantidadeItens: (json['quantidadeItens'] as num).toInt(),
      );
}

class Pedido {
  const Pedido({
    required this.id,
    required this.criadoEm,
    required this.status,
    required this.itens,
    required this.subtotal,
    required this.descontoVolume,
    required this.descontoCupom,
    required this.total,
    required this.podeCancelar,
    this.cupom,
  });

  final int id;
  final DateTime criadoEm;
  final String status;
  final List<LinhaPedido> itens;
  final double subtotal;
  final double descontoVolume;
  final double descontoCupom;
  final double total;
  final String? cupom;

  /// A API diz se o cliente ainda pode cancelar (regra de negócio fica lá).
  final bool podeCancelar;

  factory Pedido.fromJson(Map<String, dynamic> json) => Pedido(
        id: (json['id'] as num).toInt(),
        criadoEm: DateTime.tryParse('${json['criadoEm']}') ?? DateTime.now(),
        status: json['status'].toString(),
        itens: (json['itens'] as List)
            .map((e) => LinhaPedido.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num).toDouble(),
        descontoVolume: (json['descontoVolume'] as num).toDouble(),
        descontoCupom: (json['descontoCupom'] as num).toDouble(),
        total: (json['total'] as num).toDouble(),
        cupom: json['cupom']?.toString(),
        podeCancelar: json['podeCancelar'] == true,
      );
}
