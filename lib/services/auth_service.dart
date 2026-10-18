import 'api_client.dart';

class AuthResultado {
  const AuthResultado({
    required this.token,
    required this.nome,
    required this.email,
    required this.perfil,
  });

  final String token;
  final String nome;
  final String email;

  /// "Cliente" ou "Admin", como a API devolveu no login.
  final String perfil;
}

/// Endpoints: POST /api/auth/login e POST /api/auth/registrar.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<AuthResultado> login(String email, String senha) async {
    final dados = await _api.post('/api/auth/login', {'email': email, 'senha': senha});

    if (dados is! Map<String, dynamic>) {
      throw ApiException('Resposta inesperada do servidor no login.');
    }
    final token = dados['token'] ?? dados['accessToken'] ?? dados['jwt'];
    if (token == null) {
      throw ApiException('O servidor não devolveu o token de acesso.');
    }

    return AuthResultado(
      token: token.toString(),
      nome: (dados['nome'] ?? email).toString(),
      email: email,
      perfil: (dados['perfil'] ?? 'Cliente').toString(),
    );
  }

  Future<void> registrar(String nome, String email, String senha) {
    return _api.post('/api/auth/registrar', {'nome': nome, 'email': email, 'senha': senha});
  }
}
