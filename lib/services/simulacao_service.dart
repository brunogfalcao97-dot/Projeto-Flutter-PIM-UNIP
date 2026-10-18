import 'dart:typed_data';

import '../models/simulacao.dart';
import 'api_client.dart';

/// Projetos salvos do cliente: POST (multipart), GET e DELETE em /api/simulacoes.
class SimulacaoService {
  SimulacaoService(this._api);

  final ApiClient _api;

  /// Salva a escolha do cliente e a foto já pintada.
  /// Campos do formulário: corId, tipoTintaId, nome (opcional), areaM2 (opcional) e o arquivo "imagem".
  Future<void> salvar({
    required int corId,
    required int tipoTintaId,
    required Uint8List imagemJpg,
    String? nome,
    double? areaM2,
  }) {
    return _api.postImagem(
      '/api/simulacoes',
      campos: {
        'corId': '$corId',
        'tipoTintaId': '$tipoTintaId',
        if (nome != null && nome.trim().isNotEmpty) 'nome': nome.trim(),
        if (areaM2 != null) 'areaM2': '$areaM2',
      },
      campoArquivo: 'imagem',
      bytes: imagemJpg,
      nomeArquivo: 'simulacao_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<List<Simulacao>> listar() async {
    final dados = await _api.get('/api/simulacoes');
    if (dados is! List) return [];
    return dados.whereType<Map<String, dynamic>>().map(Simulacao.fromJson).toList();
  }

  Future<void> excluir(int id) => _api.delete('/api/simulacoes/$id');
}
