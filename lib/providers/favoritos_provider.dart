import 'package:flutter/foundation.dart';

import '../models/cor.dart';
import '../services/api_client.dart';
import '../services/favorito_service.dart';
import 'auth_provider.dart';

/// Cores favoritas do cliente. A lista mora na API; aqui fica uma cópia para a tela reagir rápido.
/// Acompanha o login: ao entrar carrega da API, ao sair esvazia.
class FavoritosProvider extends ChangeNotifier {
  FavoritosProvider(this._auth, this._servico) {
    _auth.addListener(_aoMudarSessao);
    _aoMudarSessao();
  }

  final AuthProvider _auth;
  final FavoritoService _servico;

  List<Cor> _cores = [];
  bool _carregando = false;
  bool _logadoAntes = false;

  List<Cor> get cores => List.unmodifiable(_cores);
  bool get carregando => _carregando;

  bool ehFavorita(int corId) => _cores.any((c) => c.id == corId);

  void _aoMudarSessao() {
    final logado = _auth.autenticado;
    if (logado == _logadoAntes) return;
    _logadoAntes = logado;
    if (logado) {
      carregar();
    } else {
      _cores = [];
      notifyListeners();
    }
  }

  Future<void> carregar() async {
    if (!_auth.autenticado) return;
    _carregando = true;
    notifyListeners();
    try {
      _cores = await _servico.listar();
    } on ApiException catch (e) {
      debugPrint('Falha ao carregar favoritos: $e');
    } finally {
      _carregando = false;
      notifyListeners();
    }
  }

  /// Marca ou desmarca. Atualiza a tela na hora e desfaz se a API recusar.
  /// Lança [ApiException] se falhar. Exige login (a tela deve conferir antes).
  Future<void> alternar(Cor cor) async {
    final eraFavorita = ehFavorita(cor.id);
    final anterior = List<Cor>.of(_cores);

    if (eraFavorita) {
      _cores.removeWhere((c) => c.id == cor.id);
    } else {
      _cores.add(cor);
    }
    notifyListeners();

    try {
      if (eraFavorita) {
        await _servico.remover(cor.id);
      } else {
        await _servico.adicionar(cor.id);
      }
    } on ApiException {
      _cores = anterior;
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _auth.removeListener(_aoMudarSessao);
    super.dispose();
  }
}
