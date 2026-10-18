import '../models/cor.dart';
import 'api_client.dart';

/// Cores favoritas do cliente logado: GET /api/favoritos, PUT e DELETE /api/favoritos/{corId}.
class FavoritoService {
  FavoritoService(this._api);

  final ApiClient _api;

  Future<List<Cor>> listar() async {
    final dados = await _api.get('/api/favoritos');
    if (dados is! List) return [];
    return dados.whereType<Map<String, dynamic>>().map(Cor.fromJson).toList();
  }

  Future<void> adicionar(int corId) => _api.put('/api/favoritos/$corId');

  Future<void> remover(int corId) => _api.delete('/api/favoritos/$corId');
}
