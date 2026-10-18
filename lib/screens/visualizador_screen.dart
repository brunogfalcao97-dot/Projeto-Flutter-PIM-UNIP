import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../models/tipo_tinta.dart';
import '../providers/auth_provider.dart';
import '../providers/favoritos_provider.dart';
import '../services/api_client.dart';
import '../services/catalogo_service.dart';
import '../services/simulacao_service.dart';
import '../utils/pintura.dart';
import '../widgets/botao_carrinho.dart';
import '../widgets/estados.dart';
import 'calculadora_screen.dart';
import 'produtos_screen.dart';

/// Mostra a foto, deixa tocar na parede, escolher cor e tipo de tinta e salvar.
class VisualizadorScreen extends StatefulWidget {
  const VisualizadorScreen({super.key, required this.imagemBytes});

  final Uint8List imagemBytes;

  @override
  State<VisualizadorScreen> createState() => _VisualizadorScreenState();
}

class _VisualizadorScreenState extends State<VisualizadorScreen> {
  ImagemPreparada? _base;
  Uint8List? _exibicao; // o que aparece na tela (foto original ou já pintada)
  Uint8List? _resultado; // foto pintada (null até a primeira pintura)
  Uint8List? _mascara; // parede selecionada

  List<Cor> _cores = [];
  List<TipoTinta> _tipos = [];
  Cor? _cor;
  TipoTinta? _tipo;

  double _tolerancia = 40;
  Offset? _toque; // posição do toque, de 0 a 1 (para o indicador de carregando)
  int _toqueX = 0;
  int _toqueY = 0;

  // Contadores para descartar resultados antigos quando o usuário mexe rápido.
  int _reqSelecao = 0;
  int _reqPintura = 0;
  int _emAndamento = 0;

  bool _preparando = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  // ---------------------------------------------------------------- carga

  Future<void> _iniciar() async {
    setState(() {
      _preparando = true;
      _erro = null;
    });
    final catalogo = context.read<CatalogoService>();

    try {
      final r = await Future.wait<Object>([
        compute(prepararImagem, widget.imagemBytes),
        catalogo.cores(),
        catalogo.tiposTinta(),
      ]);
      final base = r[0] as ImagemPreparada;
      final cores = r[1] as List<Cor>;
      final tipos = r[2] as List<TipoTinta>;

      if (!mounted) return;
      setState(() {
        _base = base;
        _exibicao = base.jpg;
        _cores = cores;
        _tipos = tipos;
        _cor ??= cores.isNotEmpty ? cores.first : null;
        _tipo ??= tipos.isNotEmpty ? tipos.first : null;
        _preparando = false;
      });
    } on ApiException catch (e) {
      _falhar(e.mensagem);
    } catch (_) {
      _falhar('Não foi possível abrir essa imagem. Tente outra foto.');
    }
  }

  void _falhar(String mensagem) {
    if (!mounted) return;
    setState(() {
      _erro = mensagem;
      _preparando = false;
    });
  }

  void _aviso(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  // ------------------------------------------------------------- pintura

  Future<void> _selecionar(int x, int y) async {
    final base = _base;
    if (base == null) return;

    final id = ++_reqSelecao;
    setState(() => _emAndamento++);
    try {
      final mascara = await compute(
        selecionarParede,
        ParametrosSelecao(
          rgba: base.rgba,
          largura: base.largura,
          altura: base.altura,
          x: x,
          y: y,
          tolerancia: _tolerancia,
        ),
      );
      if (!mounted || id != _reqSelecao) return;
      _mascara = mascara;
      await _aplicar();
    } catch (_) {
      _aviso('Não foi possível selecionar a parede. Tente tocar em outro ponto.');
    } finally {
      if (mounted) setState(() => _emAndamento--);
    }
  }

  Future<void> _aplicar() async {
    final base = _base, mascara = _mascara, cor = _cor;
    if (base == null || mascara == null || cor == null) return;

    final id = ++_reqPintura;
    if (mounted) setState(() => _emAndamento++);
    try {
      final jpg = await compute(
        pintarParede,
        ParametrosPintura(
          rgba: base.rgba,
          largura: base.largura,
          altura: base.altura,
          mascara: mascara,
          corRgb: cor.rgb,
          fatorContraste: _tipo?.fatorContraste ?? 0.95,
        ),
      );
      if (!mounted || id != _reqPintura) return;
      setState(() {
        _exibicao = jpg;
        _resultado = jpg;
      });
    } catch (_) {
      _aviso('Não foi possível aplicar a cor. Tente novamente.');
    } finally {
      if (mounted) setState(() => _emAndamento--);
    }
  }

  void _aoTocarNaImagem(TapUpDetails detalhes, Size area) {
    final base = _base;
    if (base == null) return;

    final fx = (detalhes.localPosition.dx / area.width).clamp(0.0, 1.0).toDouble();
    final fy = (detalhes.localPosition.dy / area.height).clamp(0.0, 1.0).toDouble();
    final x = (fx * base.largura).floor().clamp(0, base.largura - 1).toInt();
    final y = (fy * base.altura).floor().clamp(0, base.altura - 1).toInt();

    setState(() {
      _toque = Offset(fx, fy);
      _toqueX = x;
      _toqueY = y;
    });
    _selecionar(x, y);
  }

  // ---------------------------------------------------------------- salvar

  Future<void> _salvar() async {
    final jpg = _resultado, cor = _cor, tipo = _tipo;
    if (jpg == null || cor == null || tipo == null) return;

    // Visitante: o login só é pedido aqui, na hora de salvar. A simulação na tela é mantida.
    if (!await exigirLogin(context) || !mounted) return;

    final nome = await pedirTexto(
      context,
      titulo: 'Nome do projeto',
      rotulo: 'Ex.: Sala de estar',
      inicial: cor.nome,
    );
    if (nome == null || !mounted) return; // cancelou

    final servico = context.read<SimulacaoService>();
    setState(() => _salvando = true);
    try {
      await servico.salvar(corId: cor.id, tipoTintaId: tipo.id, imagemJpg: jpg, nome: nome);
      _aviso('Projeto salvo em "Meus projetos"!');
    } on ApiException catch (e) {
      _aviso(e.mensagem);
    } catch (_) {
      _aviso('Não foi possível salvar a simulação.');
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  // --------------------------------------------------------------- atalhos

  Future<void> _favoritar() async {
    final cor = _cor;
    if (cor == null) return;
    if (!await exigirLogin(context) || !mounted) return;
    try {
      await context.read<FavoritosProvider>().alternar(cor);
    } catch (e) {
      _aviso(textoDoErro(e, 'Não foi possível atualizar os favoritos.'));
    }
  }

  void _calcular() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalculadoraScreen(cor: _cor, tipoTintaId: _tipo?.id),
      ),
    );
  }

  void _comprar() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProdutosScreen(corInicial: _cor)),
    );
  }

  // ------------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    Widget corpo;
    if (_preparando) {
      corpo = const Center(child: CircularProgressIndicator());
    } else if (_erro != null) {
      corpo = _telaErro();
    } else {
      corpo = Column(
        children: [
          Expanded(child: ColoredBox(color: Colors.black87, child: _areaImagem())),
          _painel(),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular cor'),
        actions: [
          if (!_preparando && _erro == null && _cor != null) ...[
            Builder(builder: (contexto) {
              final favorita = contexto.watch<FavoritosProvider>().ehFavorita(_cor!.id);
              return IconButton(
                tooltip: favorita ? 'Remover dos favoritos' : 'Favoritar cor',
                icon: Icon(favorita ? Icons.favorite : Icons.favorite_border),
                onPressed: _favoritar,
              );
            }),
            IconButton(
              tooltip: 'Calcular quantidade de tinta',
              icon: const Icon(Icons.calculate_outlined),
              onPressed: _calcular,
            ),
            IconButton(
              tooltip: 'Comprar esta cor',
              icon: const Icon(Icons.storefront_outlined),
              onPressed: _comprar,
            ),
          ],
          const BotaoCarrinho(),
        ],
      ),
      body: corpo,
    );
  }

  Widget _telaErro() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 56, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            Text(_erro!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: _iniciar, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }

  Widget _areaImagem() {
    final base = _base!;
    return Center(
      child: AspectRatio(
        aspectRatio: base.largura / base.altura,
        child: LayoutBuilder(
          builder: (contexto, restricoes) {
            final area = Size(restricoes.maxWidth, restricoes.maxHeight);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (d) => _aoTocarNaImagem(d, area),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(_exibicao!, fit: BoxFit.fill, gaplessPlayback: true),
                  if (_emAndamento > 0)
                    Align(
                      alignment: _toque == null
                          ? Alignment.center
                          : Alignment(_toque!.dx * 2 - 1, _toque!.dy * 2 - 1),
                      child: const SizedBox(
                        width: 30,
                        height: 30,
                        child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                      ),
                    ),
                  if (_mascara == null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Toque na parede para pintar',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _painel() {
    final tema = Theme.of(context);
    final logado = context.watch<AuthProvider>().autenticado;

    return Material(
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sensibilidade da seleção
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Icon(Icons.tune, size: 20),
                    const SizedBox(width: 8),
                    const Text('Seleção'),
                    Expanded(
                      child: Slider(
                        min: 10,
                        max: 90,
                        divisions: 16,
                        value: _tolerancia,
                        label: _tolerancia.round().toString(),
                        onChanged: (v) => setState(() => _tolerancia = v),
                        onChangeEnd: (_) {
                          if (_toque != null) _selecionar(_toqueX, _toqueY);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Tipos de tinta
              if (_tipos.isNotEmpty)
                SizedBox(
                  height: 44,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _tipos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final t = _tipos[i];
                      return ChoiceChip(
                        label: Text(t.acabamento.isEmpty ? t.nome : '${t.nome} · ${t.acabamento}'),
                        selected: t.id == _tipo?.id,
                        tooltip: t.descricao,
                        onSelected: (_) {
                          setState(() => _tipo = t);
                          _aplicar();
                        },
                      );
                    },
                  ),
                ),

              // Cores
              if (_cores.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Nenhuma cor cadastrada na API ainda.'),
                )
              else
                SizedBox(
                  height: 88,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    itemCount: _cores.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final c = _cores[i];
                      final selecionada = c.id == _cor?.id;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _cor = c);
                          _aplicar();
                        },
                        child: SizedBox(
                          width: 64,
                          child: Column(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: c.color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: selecionada ? tema.colorScheme.primary : Colors.black26,
                                    width: selecionada ? 3 : 1,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                c.nome,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: tema.textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Salvar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: FilledButton.icon(
                  onPressed: (_resultado == null || _salvando) ? null : _salvar,
                  icon: _salvando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Icon(logado ? Icons.save_alt : Icons.login),
                  label: Text(logado ? 'Salvar simulação' : 'Entrar para salvar'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
