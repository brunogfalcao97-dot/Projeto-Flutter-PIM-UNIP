import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../providers/favoritos_provider.dart';
import '../widgets/estados.dart';
import 'calculadora_screen.dart';
import 'produtos_screen.dart';

/// Cores favoritas do cliente (guardadas na API).
class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  Future<void> _remover(BuildContext context, Cor cor) async {
    try {
      await context.read<FavoritosProvider>().alternar(cor);
    } catch (e) {
      if (context.mounted) mostrarAviso(context, textoDoErro(e, 'Não foi possível remover o favorito.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final favoritos = context.watch<FavoritosProvider>();
    final cores = favoritos.cores;

    return Scaffold(
      appBar: AppBar(title: const Text('Cores favoritas')),
      body: favoritos.carregando && cores.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : cores.isEmpty
              ? const MensagemEstado(
                  icone: Icons.favorite_border,
                  texto: 'Nenhuma cor favorita ainda. Toque no coração ao simular uma cor.',
                )
              : RefreshIndicator(
                  onRefresh: () => context.read<FavoritosProvider>().carregar(),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: cores.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final cor = cores[i];
                      final detalhes = [
                        cor.codigoHex.toUpperCase(),
                        if (cor.codigoPantone != null && cor.codigoPantone!.isNotEmpty) cor.codigoPantone!,
                      ].join(' · ');
                      return ListTile(
                        leading: AmostraCor(cor: cor, tamanho: 44),
                        title: Text(cor.nome),
                        subtitle: Text(detalhes),
                        trailing: PopupMenuButton<String>(
                          onSelected: (acao) {
                            switch (acao) {
                              case 'comprar':
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => ProdutosScreen(corInicial: cor)),
                                );
                              case 'calcular':
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => CalculadoraScreen(cor: cor)),
                                );
                              case 'remover':
                                _remover(context, cor);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'comprar', child: Text('Comprar tinta')),
                            PopupMenuItem(value: 'calcular', child: Text('Calcular quantidade')),
                            PopupMenuItem(value: 'remover', child: Text('Remover dos favoritos')),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
