import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../utils/formatar.dart';
import '../widgets/estados.dart';

/// Detalhes de um pedido. A API diz se ainda dá para cancelar ([Pedido.podeCancelar]).
class PedidoDetalheScreen extends StatefulWidget {
  const PedidoDetalheScreen({super.key, required this.pedidoId, this.inicial, this.recemCriado = false});

  final int pedidoId;
  final Pedido? inicial;
  final bool recemCriado;

  @override
  State<PedidoDetalheScreen> createState() => _PedidoDetalheScreenState();
}

class _PedidoDetalheScreenState extends State<PedidoDetalheScreen> {
  Pedido? _pedido;
  String? _erro;
  bool _carregando = false;
  bool _cancelando = false;

  @override
  void initState() {
    super.initState();
    _pedido = widget.inicial;
    if (_pedido == null) _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await context.read<PedidoService>().obter(widget.pedidoId);
      if (!mounted) return;
      setState(() => _pedido = p);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = textoDoErro(e, 'Não foi possível carregar o pedido.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _cancelar() async {
    final ok = await confirmar(
      context,
      titulo: 'Cancelar pedido?',
      texto: 'O estoque será devolvido e o cupom (se houver) volta a ficar disponível.',
      confirmarRotulo: 'Cancelar pedido',
    );
    if (!ok || !mounted) return;

    setState(() => _cancelando = true);
    try {
      final p = await context.read<PedidoService>().cancelar(widget.pedidoId);
      if (!mounted) return;
      setState(() => _pedido = p);
      mostrarAviso(context, 'Pedido cancelado.');
    } catch (e) {
      mostrarAviso(context, textoDoErro(e, 'Não foi possível cancelar o pedido.'));
    } finally {
      if (mounted) setState(() => _cancelando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pedido = _pedido;
    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.pedidoId}')),
      body: pedido == null
          ? (_carregando
              ? const Center(child: CircularProgressIndicator())
              : MensagemEstado(
                  icone: Icons.cloud_off,
                  texto: _erro ?? 'Pedido não encontrado.',
                  acao: FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                ))
          : _conteudo(pedido),
    );
  }

  Widget _conteudo(Pedido p) {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (widget.recemCriado)
          Card(
            color: tema.colorScheme.primaryContainer,
            child: const ListTile(
              leading: Icon(Icons.check_circle_outline),
              title: Text('Pedido realizado com sucesso!'),
            ),
          ),
        Row(
          children: [
            Expanded(child: Text(dataHora(p.criadoEm), style: tema.textTheme.bodyMedium)),
            Chip(label: Text(p.status)),
          ],
        ),
        const SizedBox(height: 8),
        for (final linha in p.itens)
          Card(
            child: ListTile(
              leading: AmostraCor(cor: Cor.simples(linha.corId, linha.corNome, linha.corHex)),
              title: Text('${linha.quantidade}× ${linha.produtoDescricao}'),
              subtitle: Text('Cor: ${linha.corNome} · ${moeda(linha.precoUnitario)} cada'),
              trailing: Text(moeda(linha.total), style: tema.textTheme.titleSmall),
            ),
          ),
        const SizedBox(height: 8),
        _linha('Subtotal', moeda(p.subtotal)),
        if (p.descontoVolume > 0) _linha('Desconto por volume', '- ${moeda(p.descontoVolume)}'),
        if (p.descontoCupom > 0) _linha('Cupom ${p.cupom ?? ''}', '- ${moeda(p.descontoCupom)}'),
        const Divider(),
        _linha('Total', moeda(p.total), destaque: true),
        if (p.podeCancelar) ...[
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _cancelando ? null : _cancelar,
            icon: _cancelando
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Icon(Icons.cancel_outlined),
            label: const Text('Cancelar pedido'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
          ),
        ],
      ],
    );
  }

  Widget _linha(String rotulo, String valor, {bool destaque = false}) {
    final tema = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(rotulo, style: destaque ? tema.textTheme.titleMedium : null)),
          Text(valor, style: destaque ? tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }
}
