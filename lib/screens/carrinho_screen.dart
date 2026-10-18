import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../models/pedido.dart';
import '../providers/carrinho_provider.dart';
import '../services/api_client.dart';
import '../services/pedido_service.dart';
import '../utils/formatar.dart';
import '../widgets/estados.dart';
import 'pedido_detalhe_screen.dart';

/// Carrinho: o app guarda o que o cliente escolheu; preços, descontos, cupom e estoque
/// vêm do orçamento calculado pela API a cada mudança.
class CarrinhoScreen extends StatefulWidget {
  const CarrinhoScreen({super.key});

  @override
  State<CarrinhoScreen> createState() => _CarrinhoScreenState();
}

class _CarrinhoScreenState extends State<CarrinhoScreen> {
  final _cupomCtrl = TextEditingController();

  Orcamento? _orcamento;
  String? _cupom; // cupom aceito pela API
  String? _erro;
  bool _carregando = false;
  bool _finalizando = false;
  int _requisicao = 0;

  @override
  void initState() {
    super.initState();
    _atualizar();
  }

  @override
  void dispose() {
    _cupomCtrl.dispose();
    super.dispose();
  }

  Future<void> _atualizar({String? cupomTentativa, bool mostrarErroDeCupom = false}) async {
    final itens = context.read<CarrinhoProvider>().itens;
    final id = ++_requisicao;
    if (itens.isEmpty) {
      setState(() {
        _orcamento = null;
        _erro = null;
        _carregando = false;
      });
      return;
    }

    setState(() {
      _carregando = true;
      _erro = null;
    });

    final servico = context.read<PedidoService>();
    final cupom = cupomTentativa ?? _cupom;
    Orcamento? orcamento;
    String? erro;
    String? cupomFinal = cupom;

    try {
      orcamento = await servico.orcamento(itens, cupom: cupom);
    } on ApiException catch (e) {
      if (cupom != null) {
        // O cupom pode ser o motivo da recusa: tenta sem ele para mostrar o carrinho.
        try {
          orcamento = await servico.orcamento(itens);
          cupomFinal = null;
          if (mostrarErroDeCupom || cupomTentativa == null) erro = e.mensagem;
        } on ApiException catch (e2) {
          erro = e2.mensagem;
        }
      } else {
        erro = e.mensagem;
      }
    } catch (_) {
      erro = 'Não foi possível calcular o carrinho agora.';
    }

    if (!mounted || id != _requisicao) return;
    setState(() {
      _orcamento = orcamento;
      _cupom = cupomFinal;
      _erro = erro;
      _carregando = false;
      if (cupomFinal == null) _cupomCtrl.clear();
    });
  }

  void _aplicarCupom() {
    final codigo = _cupomCtrl.text.trim();
    if (codigo.isEmpty) return;
    FocusScope.of(context).unfocus();
    _atualizar(cupomTentativa: codigo, mostrarErroDeCupom: true);
  }

  void _removerCupom() {
    setState(() => _cupom = null);
    _cupomCtrl.clear();
    _atualizar();
  }

  void _mudarQuantidade(ItemCarrinho item, int nova) {
    context.read<CarrinhoProvider>().alterarQuantidade(item, nova);
    _atualizar();
  }

  Future<void> _finalizar() async {
    final carrinho = context.read<CarrinhoProvider>();
    if (!await exigirLogin(context) || !mounted) return;

    setState(() => _finalizando = true);
    try {
      final pedido = await context.read<PedidoService>().criar(carrinho.itens, cupom: _cupom);
      carrinho.limpar();
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PedidoDetalheScreen(pedidoId: pedido.id, inicial: pedido, recemCriado: true)),
      );
    } catch (e) {
      if (!mounted) return;
      mostrarAviso(context, textoDoErro(e, 'Não foi possível finalizar o pedido.'));
      _atualizar(); // estoque ou preço podem ter mudado
    } finally {
      if (mounted) setState(() => _finalizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final carrinho = context.watch<CarrinhoProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        actions: [
          if (!carrinho.vazio)
            IconButton(
              tooltip: 'Esvaziar',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () async {
                final ok = await confirmar(
                  context,
                  titulo: 'Esvaziar carrinho?',
                  texto: 'Todos os itens serão removidos.',
                  confirmarRotulo: 'Esvaziar',
                );
                if (!ok || !context.mounted) return;
                context.read<CarrinhoProvider>().limpar();
                _atualizar();
              },
            ),
        ],
      ),
      body: carrinho.vazio
          ? const MensagemEstado(icone: Icons.shopping_cart_outlined, texto: 'Seu carrinho está vazio.')
          : _conteudo(carrinho),
    );
  }

  Widget _conteudo(CarrinhoProvider carrinho) {
    final tema = Theme.of(context);
    final orcamento = _orcamento;

    return Column(
      children: [
        if (_carregando) const LinearProgressIndicator(minHeight: 2),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in carrinho.itens)
                _LinhaCarrinho(
                  item: item,
                  total: orcamento?.linhaDe(item)?.total,
                  aoMudar: (n) => _mudarQuantidade(item, n),
                ),
              const SizedBox(height: 8),
              if (_cupom != null)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sell_outlined),
                    title: Text('Cupom $_cupom aplicado'),
                    trailing: TextButton(onPressed: _removerCupom, child: const Text('Remover')),
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _cupomCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(labelText: 'Cupom de desconto'),
                        onSubmitted: (_) => _aplicarCupom(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(onPressed: _carregando ? null : _aplicarCupom, child: const Text('Aplicar')),
                  ],
                ),
              if (_erro != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
                ),
            ],
          ),
        ),
        if (orcamento != null) _resumo(orcamento),
      ],
    );
  }

  Widget _resumo(Orcamento o) {
    final tema = Theme.of(context);
    Widget linha(String rotulo, String valor, {bool destaque = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(rotulo, style: destaque ? tema.textTheme.titleMedium : null)),
              Text(
                valor,
                style: destaque ? tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) : null,
              ),
            ],
          ),
        );

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              linha('Subtotal (${litros(o.litrosTotais)})', moeda(o.subtotal)),
              if (o.descontoVolume > 0) linha('Desconto por volume', '- ${moeda(o.descontoVolume)}'),
              if (o.descontoCupom > 0) linha('Cupom ${o.cupom ?? ''}', '- ${moeda(o.descontoCupom)}'),
              const Divider(),
              linha('Total', moeda(o.total), destaque: true),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: (_finalizando || _carregando) ? null : _finalizar,
                icon: _finalizando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.check),
                label: const Text('Finalizar pedido'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinhaCarrinho extends StatelessWidget {
  const _LinhaCarrinho({required this.item, required this.total, required this.aoMudar});

  final ItemCarrinho item;
  final double? total;
  final ValueChanged<int> aoMudar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(
          children: [
            AmostraCor(cor: Cor.simples(item.corId, item.corNome, item.corHex)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.descricao, style: tema.textTheme.titleSmall),
                  Text('Cor: ${item.corNome}', style: tema.textTheme.bodySmall),
                  if (total != null)
                    Text(moeda(total!), style: tema.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Menos',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () => aoMudar(item.quantidade - 1),
            ),
            Text('${item.quantidade}', style: tema.textTheme.titleMedium),
            IconButton(
              tooltip: 'Mais',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => aoMudar(item.quantidade + 1),
            ),
          ],
        ),
      ),
    );
  }
}
