import 'dart:convert';

import '../models/cor.dart';
import '../models/produto.dart';
import '../models/tipo_tinta.dart';
import 'api_client.dart';
import 'cache_local.dart';

/// Catálogo público da API: cores, tipos de tinta, marcas e produtos (preço e estoque).
///
/// Cache: dentro da validade, a cópia do aparelho é usada sem esperar a rede (app abre mais rápido).
/// Se a API estiver inacessível, a última cópia guardada é usada, mesmo vencida.
/// Produtos têm validade zero: preço e estoque sempre vêm da API quando há conexão.
class CatalogoService {
  CatalogoService(this._api, this._cache);

  final ApiClient _api;
  final CacheLocal _cache;

  static const _validadeCatalogo = Duration(minutes: 10);

  Future<List<Cor>> cores() => _lista('cores', '/api/cores', Cor.fromJson, _validadeCatalogo);

  Future<List<TipoTinta>> tiposTinta() =>
      _lista('tipos-tinta', '/api/tipos-tinta', TipoTinta.fromJson, _validadeCatalogo);

  Future<List<Marca>> marcas() => _lista('marcas', '/api/marcas', Marca.fromJson, _validadeCatalogo);

  Future<List<Produto>> produtos() => _lista('produtos', '/api/produtos', Produto.fromJson, Duration.zero);

  Future<List<T>> _lista<T>(
    String chave,
    String caminho,
    T Function(Map<String, dynamic>) converter,
    Duration validade,
  ) async {
    final guardado = await _cache.ler(chave);

    if (guardado != null && validade > Duration.zero && guardado.idade < validade) {
      final lista = _converter(guardado.json, converter);
      if (lista != null) return lista;
    }

    try {
      final dados = await _api.get(caminho);
      if (dados is! List) return <T>[];
      final lista = dados.whereType<Map<String, dynamic>>().map(converter).toList();
      await _cache.gravar(chave, jsonEncode(dados));
      return lista;
    } on ApiException catch (e) {
      // Sem conexão: mostra a última cópia guardada, se houver.
      if (e.semConexao && guardado != null) {
        final lista = _converter(guardado.json, converter);
        if (lista != null) return lista;
      }
      rethrow;
    }
  }

  List<T>? _converter<T>(String json, T Function(Map<String, dynamic>) converter) {
    try {
      final dados = jsonDecode(json);
      if (dados is! List) return null;
      return dados.whereType<Map<String, dynamic>>().map(converter).toList();
    } catch (_) {
      return null;
    }
  }
}
