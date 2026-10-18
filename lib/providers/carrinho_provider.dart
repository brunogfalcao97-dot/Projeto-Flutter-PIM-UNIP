import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/pedido.dart';

/// Carrinho guardado no aparelho (shared_preferences), para sobreviver ao fechamento do app.
/// Aqui só ficam produto, cor e quantidade. Preço, estoque, desconto e cupom são
/// calculados pela API (POST /api/pedidos/orcamento) na tela do carrinho.
class CarrinhoProvider extends ChangeNotifier {
  CarrinhoProvider() {
    _carregar();
  }

  static const _chave = 'carrinho';

  final List<ItemCarrinho> _itens = [];

  List<ItemCarrinho> get itens => List.unmodifiable(_itens);
  bool get vazio => _itens.isEmpty;
  int get quantidadeTotal => _itens.fold(0, (soma, i) => soma + i.quantidade);

  Future<void> _carregar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final texto = prefs.getString(_chave);
      if (texto == null) return;
      final dados = jsonDecode(texto);
      if (dados is! List) return;
      _itens
        ..clear()
        ..addAll(dados.whereType<Map<String, dynamic>>().map(ItemCarrinho.fromJson));
      notifyListeners();
    } catch (_) {
      // carrinho corrompido: começa vazio
    }
  }

  Future<void> _salvar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chave, jsonEncode(_itens.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  /// Soma a quantidade se o mesmo produto na mesma cor já estiver no carrinho.
  void adicionar(ItemCarrinho item) {
    final indice = _itens.indexWhere((i) => i.mesmoItem(item.produtoId, item.corId));
    if (indice >= 0) {
      _itens[indice] = _itens[indice].comQuantidade(_itens[indice].quantidade + item.quantidade);
    } else {
      _itens.add(item);
    }
    notifyListeners();
    _salvar();
  }

  void alterarQuantidade(ItemCarrinho item, int nova) {
    if (nova <= 0) {
      remover(item);
      return;
    }
    final indice = _itens.indexWhere((i) => i.mesmoItem(item.produtoId, item.corId));
    if (indice < 0) return;
    _itens[indice] = _itens[indice].comQuantidade(nova);
    notifyListeners();
    _salvar();
  }

  void remover(ItemCarrinho item) {
    _itens.removeWhere((i) => i.mesmoItem(item.produtoId, item.corId));
    notifyListeners();
    _salvar();
  }

  void limpar() {
    _itens.clear();
    notifyListeners();
    _salvar();
  }
}
