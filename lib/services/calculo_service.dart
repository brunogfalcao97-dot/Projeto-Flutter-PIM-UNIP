import '../models/calculo_tinta.dart';
import 'api_client.dart';

/// POST /api/calculos/tinta. Quanto de tinta comprar é decidido pela API; o app só envia as medidas.
class CalculoService {
  CalculoService(this._api);

  final ApiClient _api;

  /// Informe [alturaM] e [larguraM], ou então [areaM2]. [demaos] null = usa as demãos recomendadas do tipo.
  Future<CalculoTinta> calcularTinta({
    required int tipoTintaId,
    double? alturaM,
    double? larguraM,
    double? areaM2,
    double areaDescontarM2 = 0,
    int? demaos,
    int? marcaId,
  }) async {
    final dados = await _api.post('/api/calculos/tinta', {
      'tipoTintaId': tipoTintaId,
      if (alturaM != null) 'alturaM': alturaM,
      if (larguraM != null) 'larguraM': larguraM,
      if (areaM2 != null) 'areaM2': areaM2,
      'areaDescontarM2': areaDescontarM2,
      if (demaos != null) 'demaos': demaos,
      if (marcaId != null) 'marcaId': marcaId,
    });

    if (dados is! Map<String, dynamic>) {
      throw ApiException('Resposta inesperada do servidor no cálculo.');
    }
    return CalculoTinta.fromJson(dados);
  }
}
