import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../models/pedido.dart';
import '../models/produto.dart';
import '../providers/carrinho_provider.dart';
import '../services/catalogo_service.dart';
import '../utils/formatar.dart';
import '../widgets/botao_carrinho.dart';
import '../widgets/estados.dart';
import '../widgets/seletor_cor.dart';
import 'carrinho_screen.dart';

/// Catálogo de latas com preço e estoque vindos da API. O cliente escolhe a cor e adiciona ao carrinho.
class ProdutosScreen extends StatefulWidget {
  const ProdutosScreen({super.key, this.corInicial});

  final Cor? corInicial;

  @override
  State<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends State<ProdutosScreen> {
  late Future<List<Produto>> _futuro;
  List<Cor>? _cores;
  Cor? _cor;
  String? _filtroTipo;

  @override
  void initState() {
    super.initState();
    _cor = widget.corInicial;
    _futuro = context.read<CatalogoService>().produtos();
  }

  void _recarregar() {
    setState(() => _futuro = context.read<CatalogoService>().produtos());
  }

  Future<Cor?> _pedirCor() async {
    try {
      _cores ??= await context.read<CatalogoService>().cores();
    } catch (e) {
      if (mounted) mostrarAviso(context, textoDoErro(e, 'Não foi possível carregar as cores.'));
      return null;
    }
    if (!mounted) return null;
    final escolhida = await escolherCor(context, _cores!, atual: _cor);
    if (escolhida != null && mounted) setState(() => _cor = escolhida);
    return escolhida;
  }

  Future<void> _adicionar(Produto produto) async {
    final cor = _cor ?? await _pedirCor();
    if (cor == null || !mounted) return;

    context.read<CarrinhoProvider>().adicionar(ItemCarrinho(
          produtoId: produto.id,
          corId: cor.id,
          quantidade: 1,
          descricao: '${produto.nome} · ${litros(produto.volumeLitros)}',
          corNome: cor.nome,
          corHex: cor.codigoHex,
        ));
    mostrarAviso(
      context,
      'Adicionado: ${produto.nome} na cor ${cor.nome}.',
      rotuloAcao: 'Ver carrinho',
      aoAcionar: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comprar tintas'), actions: const [BotaoCarrinho()]),
      body: FutureBuilder<List<Produto>>(
        future: _futuro,
        builder: (contexto, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensagemEstado(
              icone: Icons.cloud_off,
              texto: textoDoErro(snapshot.error!, 'Não foi possível carregar os produtos.'),
              acao: FilledButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
            );
          }

          final todos = snapshot.data ?? [];
          final tipos = todos.map((p) => p.tipoTintaNome).toSet().toList()..sort();
          final lista = _filtroTipo == null ? todos : todos.where((p) => p.tipoTintaNome == _filtroTipo).toList();

          return RefreshIndicator(
            onRefresh: () async {
              _recarregar();
              try {
                await _futuro;
              } catch (_) {}
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: _cor == null ? const Icon(Icons.palette_outlined) : AmostraCor(cor: _cor!),
                    title: Text(_cor?.nome ?? 'Escolha a cor da tinta'),
                    subtitle: Text(_cor == null ? 'Toque para ver o catálogo de cores' : _cor!.codigoHex.toUpperCase()),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pedirCor,
                  ),
                ),
                if (tipos.length > 1) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('Todos'),
                            selected: _filtroTipo == null,
                            onSelected: (_) => setState(() => _filtroTipo = null),
                          ),
                        ),
                        for (final tipo in tipos)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(tipo),
                              selected: _filtroTipo == tipo,
                              onSelected: (_) => setState(() => _filtroTipo = tipo),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                if (lista.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: MensagemEstado(icone: Icons.inventory_2_outlined, texto: 'Nenhum produto disponível.'),
                  )
                else
                  for (final produto in lista) _CartaoProduto(produto: produto, aoAdicionar: () => _adicionar(produto)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CartaoProduto extends StatelessWidget {
  const _CartaoProduto({required this.produto, required this.aoAdicionar});

  final Produto produto;
  final VoidCallback aoAdicionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome, style: tema.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('${produto.marcaNome} · ${produto.acabamento} · ${litros(produto.volumeLitros)}'),
                  const SizedBox(height: 6),
                  Text(
                    moeda(produto.preco),
                    style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    produto.emEstoque ? '${produto.estoque} em estoque' : 'Sem estoque',
                    style: tema.textTheme.bodySmall?.copyWith(
                      color: produto.emEstoque ? null : tema.colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: produto.emEstoque ? aoAdicionar : null,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
