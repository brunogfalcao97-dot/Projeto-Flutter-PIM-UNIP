import '../models/perfil.dart';
import 'api_client.dart';

/// Dados do cliente logado: GET/PUT /api/perfil e POST /api/perfil/alterar-senha.
class PerfilService {
  PerfilService(this._api);

  final ApiClient _api;

  Perfil _perfil(dynamic dados) {
    if (dados is! Map<String, dynamic>) {
      throw ApiException('Resposta inesperada do servidor.');
    }
    return Perfil.fromJson(dados);
  }

  Future<Perfil> obter() async => _perfil(await _api.get('/api/perfil'));

  Future<Perfil> atualizar({required String nome, String? telefone}) async =>
      _perfil(await _api.put('/api/perfil', {'nome': nome, 'telefone': telefone}));

  Future<void> alterarSenha({required String senhaAtual, required String novaSenha}) =>
      _api.post('/api/perfil/alterar-senha', {'senhaAtual': senhaAtual, 'novaSenha': novaSenha});
}
