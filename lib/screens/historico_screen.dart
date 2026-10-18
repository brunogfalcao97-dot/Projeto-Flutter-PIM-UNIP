import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/api_config.dart';
import '../models/cor.dart';
import '../models/simulacao.dart';
import '../providers/auth_provider.dart';
import '../services/simulacao_service.dart';
import '../utils/formatar.dart';
import '../widgets/estados.dart';
import 'calculadora_screen.dart';
import 'produtos_screen.dart';

/// "Meus projetos": simulações salvas pelo cliente. As fotos são privadas e baixadas com o token.
class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  late Future<List<Simulacao>> _futuro;

  @override
  void initState() {
    super.initState();
    _futuro = context.read<SimulacaoService>().listar();
  }

  Future<void> _recarregar() async {
    final novo = context.read<SimulacaoService>().listar();
    setState(() => _futuro = novo);
    try {
      await novo;
    } catch (_) {
      // o erro aparece pelo FutureBuilder
    }
  }

  Future<void> _excluir(Simulacao s) async {
    final ok = await confirmar(
      context,
      titulo: 'Excluir projeto?',
      texto: 'A foto salva será apagada da sua conta.',
      confirmarRotulo: 'Excluir',
    );
    if (!ok || !mounted) return;
    try {
      await context.read<SimulacaoService>().excluir(s.id);
      if (!mounted) return;
      mostrarAviso(context, 'Projeto excluído.');
      _recarregar();
    } catch (e) {
      if (mounted) mostrarAviso(context, textoDoErro(e, 'Não foi possível excluir o projeto.'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cabecalhos = context.read<AuthProvider>().api.cabecalhosAutenticados;

    return Scaffold(
      appBar: AppBar(title: const Text('Meus projetos')),
      body: FutureBuilder<List<Simulacao>>(
        future: _futuro,
        builder: (contexto, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return MensagemEstado(
              icone: Icons.cloud_off,
              texto: textoDoErro(snapshot.error!, 'Não foi possível carregar seus projetos.'),
              acao: FilledButton(onPressed: _recarregar, child: const Text('Tentar novamente')),
            );
          }
          final lista = snapshot.data ?? [];
          if (lista.isEmpty) {
            return const MensagemEstado(
              icone: Icons.format_paint_outlined,
              texto: 'Você ainda não salvou nenhum projeto.',
            );
          }
          return RefreshIndicator(
            onRefresh: _recarregar,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: lista.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _ItemProjeto(
                projeto: lista[i],
                cabecalhos: cabecalhos,
                aoExcluir: () => _excluir(lista[i]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ItemProjeto extends StatelessWidget {
  const _ItemProjeto({required this.projeto, required this.cabecalhos, required this.aoExcluir});

  final Simulacao projeto;
  final Map<String, String> cabecalhos;
  final VoidCallback aoExcluir;

  Cor get _cor => Cor.simples(projeto.corId, projeto.corNome, projeto.corHex);

  @override
  Widget build(BuildContext context) {
    final url = ApiConfig.urlImagem(projeto.imagemUrl);
    final amostra = ColoredBox(color: _cor.color);
    final titulo = (projeto.nome != null && projeto.nome!.isNotEmpty) ? projeto.nome! : projeto.corNome;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 64,
          height: 64,
          child: Image.network(
            url,
            headers: cabecalhos,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => amostra,
          ),
        ),
      ),
      title: Text(titulo),
      subtitle: Text('${projeto.corNome} · ${projeto.tipoTintaNome}\n${dataHora(projeto.criadoEm)}'),
      isThreeLine: true,
      trailing: PopupMenuButton<String>(
        onSelected: (acao) {
          switch (acao) {
            case 'ver':
              showDialog<void>(
                context: context,
                builder: (_) => Dialog(
                  child: InteractiveViewer(
                    child: Image.network(
                      url,
                      headers: cabecalhos,
                      errorBuilder: (_, __, ___) => const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Não foi possível carregar a imagem.'),
                      ),
                    ),
                  ),
                ),
              );
            case 'comprar':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ProdutosScreen(corInicial: _cor)),
              );
            case 'calcular':
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CalculadoraScreen(
                    cor: _cor,
                    tipoTintaId: projeto.tipoTintaId,
                    areaM2: projeto.areaM2,
                  ),
                ),
              );
            case 'excluir':
              aoExcluir();
          }
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'ver', child: Text('Ver foto')),
          PopupMenuItem(value: 'comprar', child: Text('Comprar esta cor')),
          PopupMenuItem(value: 'calcular', child: Text('Calcular quantidade')),
          PopupMenuItem(value: 'excluir', child: Text('Excluir')),
        ],
      ),
    );
  }
}
