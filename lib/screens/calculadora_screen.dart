import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/calculo_tinta.dart';
import '../models/cor.dart';
import '../models/pedido.dart';
import '../models/tipo_tinta.dart';
import '../providers/carrinho_provider.dart';
import '../services/calculo_service.dart';
import '../services/catalogo_service.dart';
import '../utils/formatar.dart';
import '../widgets/botao_carrinho.dart';
import '../widgets/estados.dart';
import '../widgets/seletor_cor.dart';
import 'carrinho_screen.dart';

/// Quanto de tinta comprar. O app só envia as medidas; litros, perda, demãos e a combinação
/// de latas mais barata são calculados pela API.
class CalculadoraScreen extends StatefulWidget {
  const CalculadoraScreen({super.key, this.cor, this.tipoTintaId, this.areaM2});

  final Cor? cor;
  final int? tipoTintaId;
  final double? areaM2;

  @override
  State<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends State<CalculadoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _alturaCtrl = TextEditingController();
  final _larguraCtrl = TextEditingController();
  final _areaCtrl = TextEditingController();
  final _descontoCtrl = TextEditingController();

  bool _porMedidas = true;
  bool _carregandoDados = true;
  bool _calculando = false;
  String? _erroDados;

  List<TipoTinta> _tipos = [];
  List<Cor> _cores = [];
  TipoTinta? _tipo;
  Cor? _cor;
  int? _demaos; // null = recomendadas do tipo

  CalculoTinta? _resultado;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _cor = widget.cor;
    if (widget.areaM2 != null) {
      _porMedidas = false;
      _areaCtrl.text = numero(widget.areaM2!);
    }
    _carregar();
  }

  @override
  void dispose() {
    _alturaCtrl.dispose();
    _larguraCtrl.dispose();
    _areaCtrl.dispose();
    _descontoCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregandoDados = true;
      _erroDados = null;
    });
    final catalogo = context.read<CatalogoService>();
    try {
      final tipos = await catalogo.tiposTinta();
      final cores = await catalogo.cores();
      if (!mounted) return;
      setState(() {
        _tipos = tipos;
        _cores = cores;
        _tipo = tipos.where((t) => t.id == widget.tipoTintaId).firstOrNull ?? tipos.firstOrNull;
        _carregandoDados = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _erroDados = textoDoErro(e, 'Não foi possível carregar os tipos de tinta.');
        _carregandoDados = false;
      });
    }
  }

  String? _validarMedida(String? v, {bool obrigatorio = true}) {
    final texto = v?.trim() ?? '';
    if (texto.isEmpty) return obrigatorio ? 'Informe um valor' : null;
    final n = lerNumero(texto);
    if (n == null || n < 0 || (obrigatorio && n == 0)) return 'Valor inválido';
    return null;
  }

  Future<void> _calcular() async {
    if (!_formKey.currentState!.validate() || _tipo == null) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _calculando = true;
      _erro = null;
    });
    try {
      final r = await context.read<CalculoService>().calcularTinta(
            tipoTintaId: _tipo!.id,
            alturaM: _porMedidas ? lerNumero(_alturaCtrl.text) : null,
            larguraM: _porMedidas ? lerNumero(_larguraCtrl.text) : null,
            areaM2: _porMedidas ? null : lerNumero(_areaCtrl.text),
            areaDescontarM2: lerNumero(_descontoCtrl.text) ?? 0,
            demaos: _demaos,
          );
      if (!mounted) return;
      setState(() => _resultado = r);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultado = null;
        _erro = textoDoErro(e, 'Não foi possível calcular agora.');
      });
    } finally {
      if (mounted) setState(() => _calculando = false);
    }
  }

  Future<void> _escolherCor() async {
    final escolhida = await escolherCor(context, _cores, atual: _cor);
    if (escolhida != null && mounted) setState(() => _cor = escolhida);
  }

  Future<void> _adicionarOpcao(OpcaoCompra opcao) async {
    var cor = _cor;
    if (cor == null) {
      cor = await escolherCor(context, _cores);
      if (cor == null || !mounted) return;
      setState(() => _cor = cor);
    }

    final carrinho = context.read<CarrinhoProvider>();
    for (final item in opcao.itens) {
      carrinho.adicionar(ItemCarrinho(
        produtoId: item.produtoId,
        corId: cor.id,
        quantidade: item.quantidade,
        descricao: item.descricao,
        corNome: cor.nome,
        corHex: cor.codigoHex,
      ));
    }
    mostrarAviso(
      context,
      'Itens adicionados ao carrinho na cor ${cor.nome}.',
      rotuloAcao: 'Ver carrinho',
      aoAcionar: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const CarrinhoScreen()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calculadora de tinta'), actions: const [BotaoCarrinho()]),
      body: _carregandoDados
          ? const Center(child: CircularProgressIndicator())
          : _erroDados != null
              ? MensagemEstado(
                  icone: Icons.cloud_off,
                  texto: _erroDados!,
                  acao: FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                )
              : _formulario(),
    );
  }

  Widget _formulario() {
    final tema = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Altura × largura'), icon: Icon(Icons.straighten)),
                  ButtonSegment(value: false, label: Text('Área em m²'), icon: Icon(Icons.square_foot)),
                ],
                selected: {_porMedidas},
                onSelectionChanged: (s) => setState(() => _porMedidas = s.first),
              ),
              const SizedBox(height: 16),
              if (_porMedidas)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _alturaCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Altura (m)'),
                        validator: _validarMedida,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _larguraCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Largura (m)'),
                        validator: _validarMedida,
                      ),
                    ),
                  ],
                )
              else
                TextFormField(
                  controller: _areaCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Área a pintar (m²)'),
                  validator: _validarMedida,
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descontoCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Descontar portas e janelas (m²)',
                  helperText: 'Opcional',
                ),
                validator: (v) => _validarMedida(v, obrigatorio: false),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _tipo?.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tipo de tinta'),
                items: [
                  for (final t in _tipos) DropdownMenuItem(value: t.id, child: Text(t.rotulo)),
                ],
                onChanged: (id) => setState(() => _tipo = _tipos.firstWhere((t) => t.id == id)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _demaos,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Demãos'),
                items: [
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Recomendado${_tipo == null ? '' : ' (${_tipo!.demaosRecomendadas})'}'),
                  ),
                  for (final n in [1, 2, 3, 4]) DropdownMenuItem<int?>(value: n, child: Text('$n')),
                ],
                onChanged: (v) => setState(() => _demaos = v),
              ),
              const SizedBox(height: 16),
              Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: _cor == null ? const Icon(Icons.palette_outlined) : AmostraCor(cor: _cor!),
                  title: Text(_cor?.nome ?? 'Cor (opcional)'),
                  subtitle: const Text('Usada ao adicionar as latas ao carrinho'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _cores.isEmpty ? null : _escolherCor,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: (_calculando || _tipo == null) ? null : _calcular,
                icon: _calculando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Icon(Icons.calculate_outlined),
                label: const Text('Calcular'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ],
          ),
        ),
        if (_erro != null) ...[
          const SizedBox(height: 16),
          Text(_erro!, style: TextStyle(color: tema.colorScheme.error)),
        ],
        if (_resultado != null) ..._blocoResultado(_resultado!),
      ],
    );
  }

  List<Widget> _blocoResultado(CalculoTinta r) {
    final tema = Theme.of(context);
    return [
      const SizedBox(height: 24),
      Card(
        color: tema.colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Você vai precisar de', style: tema.textTheme.labelLarge),
              Text(
                litros(r.litrosNecessarios),
                style: tema.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Área líquida ${metrosQuadrados(r.areaLiquidaM2)} · ${r.demaos} demão(s) · '
                'rende ${numero(r.rendimentoM2PorLitro)} m²/L · margem de perda ${numero(r.margemPerdaPercentual)}%',
              ),
              if (r.aviso != null && r.aviso!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(r.aviso!, style: TextStyle(color: tema.colorScheme.error)),
              ],
            ],
          ),
        ),
      ),
      if (r.opcoes.isEmpty)
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Nenhuma combinação de latas disponível em estoque para esse tipo de tinta.'),
        )
      else
        for (final opcao in r.opcoes) _CartaoOpcao(opcao: opcao, aoAdicionar: () => _adicionarOpcao(opcao)),
    ];
  }
}

class _CartaoOpcao extends StatelessWidget {
  const _CartaoOpcao({required this.opcao, required this.aoAdicionar});

  final OpcaoCompra opcao;
  final VoidCallback aoAdicionar;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(opcao.marcaNome, style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            for (final item in opcao.itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(child: Text('${item.quantidade}× ${item.descricao}')),
                    Text(moeda(item.subtotal)),
                  ],
                ),
              ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${litros(opcao.litrosComprados)} no total · sobram ${litros(opcao.sobraLitros)}',
                    style: tema.textTheme.bodySmall,
                  ),
                ),
                Text(moeda(opcao.total), style: tema.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: aoAdicionar,
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Adicionar ao carrinho'),
            ),
          ],
        ),
      ),
    );
  }
}
