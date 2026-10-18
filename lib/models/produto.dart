/// Marca de tinta (GET /api/marcas).
class Marca {
  const Marca({required this.id, required this.nome, this.descricao});

  final int id;
  final String nome;
  final String? descricao;

  factory Marca.fromJson(Map<String, dynamic> json) => Marca(
        id: (json['id'] as num).toInt(),
        nome: json['nome'].toString(),
        descricao: json['descricao']?.toString(),
      );
}

/// Lata à venda, com preço e estoque (GET /api/produtos).
class Produto {
  const Produto({
    required this.id,
    required this.sku,
    required this.nome,
    required this.marcaId,
    required this.marcaNome,
    required this.tipoTintaId,
    required this.tipoTintaNome,
    required this.acabamento,
    required this.volumeLitros,
    required this.preco,
    required this.estoque,
    required this.emEstoque,
  });

  final int id;
  final String sku;
  final String nome;
  final int marcaId;
  final String marcaNome;
  final int tipoTintaId;
  final String tipoTintaNome;
  final String acabamento;
  final double volumeLitros;

  /// Preço só para exibir. Quem calcula o valor do pedido é a API.
  final double preco;
  final int estoque;
  final bool emEstoque;

  factory Produto.fromJson(Map<String, dynamic> json) => Produto(
        id: (json['id'] as num).toInt(),
        sku: json['sku'].toString(),
        nome: json['nome'].toString(),
        marcaId: (json['marcaId'] as num).toInt(),
        marcaNome: json['marcaNome'].toString(),
        tipoTintaId: (json['tipoTintaId'] as num).toInt(),
        tipoTintaNome: json['tipoTintaNome'].toString(),
        acabamento: json['acabamento']?.toString() ?? '',
        volumeLitros: (json['volumeLitros'] as num).toDouble(),
        preco: (json['preco'] as num).toDouble(),
        estoque: (json['estoque'] as num).toInt(),
        emEstoque: json['emEstoque'] == true,
      );
}
