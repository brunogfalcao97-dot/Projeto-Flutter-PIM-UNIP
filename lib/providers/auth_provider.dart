import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Guarda a sessão do cliente (token JWT) e expõe login, cadastro e logout.
/// O [api] criado aqui é compartilhado pelos outros serviços para enviar o token.
/// Permissões de verdade são checadas pela API; [ehAdmin] serve só para a interface.
class AuthProvider extends ChangeNotifier {
  AuthProvider({FlutterSecureStorage? armazenamento})
      : _armazenamento = armazenamento ?? const FlutterSecureStorage() {
    api = ApiClient(tokenProvider: () => _token, onSessaoExpirada: sair);
    _auth = AuthService(api);
  }

  static const _kToken = 'token';
  static const _kNome = 'nome';
  static const _kEmail = 'email';
  static const _kPerfil = 'perfil';

  final FlutterSecureStorage _armazenamento;
  late final ApiClient api;
  late final AuthService _auth;

  String? _token;
  String? _nome;
  String? _email;
  String? _perfil;

  bool get autenticado => _token != null;
  String get nome => _nome ?? '';
  String get email => _email ?? '';
  String get perfil => _perfil ?? 'Cliente';
  bool get ehAdmin => perfil == 'Admin';

  /// Lê a sessão salva no aparelho (chamado uma vez antes de abrir o app).
  Future<void> carregarSessao() async {
    try {
      _token = await _armazenamento.read(key: _kToken);
      _nome = await _armazenamento.read(key: _kNome);
      _email = await _armazenamento.read(key: _kEmail);
      _perfil = await _armazenamento.read(key: _kPerfil);
    } catch (_) {
      _token = null;
    }
    notifyListeners();
  }

  Future<void> entrar(String email, String senha) async {
    final resultado = await _auth.login(email, senha);
    _token = resultado.token;
    _nome = resultado.nome;
    _email = resultado.email;
    _perfil = resultado.perfil;
    try {
      await _armazenamento.write(key: _kToken, value: _token);
      await _armazenamento.write(key: _kNome, value: _nome);
      await _armazenamento.write(key: _kEmail, value: _email);
      await _armazenamento.write(key: _kPerfil, value: _perfil);
    } catch (_) {
      // Sem armazenamento seguro o login vale só até fechar o app.
    }
    notifyListeners();
  }

  /// Cria a conta e já entra com ela.
  Future<void> cadastrar(String nome, String email, String senha) async {
    await _auth.registrar(nome, email, senha);
    await entrar(email, senha);
  }

  /// Atualiza o nome mostrado depois de editar o perfil.
  Future<void> atualizarNome(String novoNome) async {
    _nome = novoNome;
    notifyListeners();
    try {
      await _armazenamento.write(key: _kNome, value: novoNome);
    } catch (_) {}
  }

  Future<void> sair() async {
    _token = null;
    _nome = null;
    _email = null;
    _perfil = null;
    notifyListeners();
    try {
      await _armazenamento.delete(key: _kToken);
      await _armazenamento.delete(key: _kNome);
      await _armazenamento.delete(key: _kEmail);
      await _armazenamento.delete(key: _kPerfil);
    } catch (_) {}
  }
}
