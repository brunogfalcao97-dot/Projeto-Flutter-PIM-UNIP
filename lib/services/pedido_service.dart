import '../models/pedido.dart';
import 'api_client.dart';

/// Orçamento, pedidos e histórico de compras. Todos os valores são calculados pela API.
class PedidoService {
  PedidoService(this._api);

  final ApiClient _api;

  Map<String, dynamic> _corpo(List<ItemCarrinho> itens, String? cupom) => {
        'itens': itens.map((i) => i.paraApi()).toList(),
        if (cupom != null && cupom.trim().isNotEmpty) 'cupom': cupom.trim(),
      };

  Map<String, dynamic> _mapa(dynamic dados) {
    if (dados is! Map<String, dynamic>) {
      throw ApiException('Resposta inesperada do servidor.');
    }
    return dados;
  }

  /// "Quanto custa?": confere estoque e cupom e devolve subtotal, descontos e total. Não grava nada.
  Future<Orcamento> orcamento(List<ItemCarrinho> itens, {String? cupom}) async {
    final dados = await _api.post('/api/pedidos/orcamento', _corpo(itens, cupom));
    return Orcamento.fromJson(_mapa(dados));
  }

  /// Fecha o pedido (exige login).
  Future<Pedido> criar(List<ItemCarrinho> itens, {String? cupom}) async {
    final dados = await _api.post('/api/pedidos', _corpo(itens, cupom));
    return Pedido.fromJson(_mapa(dados));
  }

  Future<List<PedidoResumo>> listar() async {
    final dados = await _api.get('/api/pedidos');
    if (dados is! List) return [];
    return dados.whereType<Map<String, dynamic>>().map(PedidoResumo.fromJson).toList();
  }

  Future<Pedido> obter(int id) async => Pedido.fromJson(_mapa(await _api.get('/api/pedidos/$id')));

  Future<Pedido> cancelar(int id) async =>
      Pedido.fromJson(_mapa(await _api.post('/api/pedidos/$id/cancelar')));
}
