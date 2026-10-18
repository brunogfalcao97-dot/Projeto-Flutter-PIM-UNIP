import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/pedido.dart';
import '../services/pedido_service.dart';
import '../utils/formatar.dart';
import '../widgets/estados.dart';
import 'pedido_detalhe_screen.dart';

/// Histórico de compras do cliente (GET /api/pedidos).
class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  late Future<List<PedidoResumo>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<PedidoService>().listar();
  }

  Future<void> _recarregar() async {
    final novo = context.read<PedidoService>().listar();
    setState(() => _futuro = novo);
    try {
      await novo;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Meus pedidos')),
      body: FutureBuilder<List<PedidoResumo>>(
        future: _futuro,
        builder: (contexto, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensagemEstado(
              icone: Icons.cloud_off,
              texto: textoDoErro(snapshot.error!, 'Não foi possível carregar os pedidos.'),
              acao: FilledButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
            );
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const MensagemEstado(icone: Icons.receipt_long_outlined, texto: 'Você ainda não fez nenhum pedido.');
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = lista[i];
                return ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: Text('Pedido #${p.id} · ${p.status}'),
                  subtitle: Text('${dataHora(p.criadoEm)} · ${p.quantidadeItens} item(ns)'),
                  trailing: Text(moeda(p.total), style: Theme.of(context).textTheme.titleSmall),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PedidoDetalheScreen(pedidoId: p.id)),
                    );
                    if (mounted) _recarregar(); // o pedido pode ter sido cancelado lá dentro
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
