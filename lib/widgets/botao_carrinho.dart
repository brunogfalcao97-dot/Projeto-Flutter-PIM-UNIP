import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/carrinho_provider.dart';
import '../screens/carrinho_screen.dart';

/// Ícone do carrinho com a quantidade de itens.
class BotaoCarrinho extends StatelessWidget {
  const BotaoCarrinho({super.key});

  @override
  Widget build(BuildContext context) {
    final quantidade = context.watch<CarrinhoProvider>().quantidadeTotal;
    return IconButton(
      tooltip: 'Carrinho',
      icon: Badge(
        isLabelVisible: quantidade > 0,
        label: Text('$quantidade'),
        child: const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
      ),
    );
  }
}
