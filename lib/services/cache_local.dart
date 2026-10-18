import 'package:shared_preferences/shared_preferences.dart';

/// Uma cópia guardada no aparelho e o momento em que foi salva.
class RegistroCache {
  const RegistroCache(this.json, this.salvoEm);

  final String json;
  final DateTime salvoEm;

  Duration get idade => DateTime.now().difference(salvoEm);
}

/// Cache local simples (shared_preferences) para o app abrir mais rápido e continuar mostrando o catálogo
/// sem internet. Guarda apenas dados públicos do catálogo; nada de senha, token ou dados do cliente.
///
/// Se o armazenamento do aparelho falhar por qualquer motivo, o app segue funcionando sem cache.
class CacheLocal {
  Future<SharedPreferences?> _prefs() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<RegistroCache?> ler(String chave) async {
    final prefs = await _prefs();
    if (prefs == null) return null;

    final json = prefs.getString('cache.$chave');
    final quando = prefs.getInt('cache.$chave.em');
    if (json == null || quando == null) return null;
    return RegistroCache(json, DateTime.fromMillisecondsSinceEpoch(quando));
  }

  Future<void> gravar(String chave, String json) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString('cache.$chave', json);
      await prefs.setInt('cache.$chave.em', DateTime.now().millisecondsSinceEpoch);
    } catch (_) {
      // sem cache, sem problema
    }
  }
}
