import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../widgets/botao_carrinho.dart';
import '../widgets/estados.dart';
import '../widgets/logo_empresa.dart';
import 'calculadora_screen.dart';
import 'favoritos_screen.dart';
import 'historico_screen.dart';
import 'login_screen.dart';
import 'pedidos_screen.dart';
import 'perfil_screen.dart';
import 'produtos_screen.dart';
import 'visualizador_screen.dart';

/// Tela inicial: fotografar o ambiente e atalhos para o resto do app.
/// Câmera, catálogo e calculadora funcionam sem login; o que é pessoal pede a conta.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();
  bool _abrindo = false;

  void _abrir(Widget tela) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => tela));
  }

  /// Telas pessoais: pede o login antes, se for preciso.
  Future<void> _abrirProtegida(Widget tela) async {
    if (!await exigirLogin(context) || !mounted) return;
    _abrir(tela);
  }

  Future<void> _escolher(ImageSource origem) async {
    if (_abrindo) return;
    setState(() => _abrindo = true);
    try {
      final arquivo = await _picker.pickImage(source: origem, maxWidth: 2000, imageQuality: 90);
      if (arquivo == null) return; // o cliente cancelou
      final bytes = await arquivo.readAsBytes();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VisualizadorScreen(imagemBytes: bytes)),
      );
    } catch (_) {
      if (!mounted) return;
      mostrarAviso(context, 'Não foi possível abrir a câmera/galeria. Verifique as permissões do app.');
    } finally {
      if (mounted) setState(() => _abrindo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final logado = auth.autenticado;
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const LogoEmpresa(altura: 44, compacto: true),
        actions: [
          const BotaoCarrinho(),
          if (logado)
            IconButton(
              tooltip: 'Meu perfil',
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => _abrir(const PerfilScreen()),
            )
          else
            TextButton.icon(
              onPressed: () => _abrir(const LoginScreen()),
              icon: const Icon(Icons.login),
              label: const Text('Entrar'),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              logado ? 'Olá, ${auth.nome}!' : 'Bem-vindo!',
              style: tema.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text('Fotografe o ambiente, toque na parede e veja como ela ficaria com a cor que você escolher.'),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _abrindo ? null : () => _escolher(ImageSource.camera),
              icon: const Icon(Icons.photo_camera),
              label: const Text('Tirar foto do ambiente'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _abrindo ? null : () => _escolher(ImageSource.gallery),
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Escolher da galeria'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
            const SizedBox(height: 28),
            Text('Atalhos', style: tema.textTheme.titleMedium),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _Atalho(
                  icone: Icons.storefront_outlined,
                  rotulo: 'Comprar tintas',
                  aoTocar: () => _abrir(const ProdutosScreen()),
                ),
                _Atalho(
                  icone: Icons.calculate_outlined,
                  rotulo: 'Calcular quantidade',
                  aoTocar: () => _abrir(const CalculadoraScreen()),
                ),
                _Atalho(
                  icone: Icons.photo_library_outlined,
                  rotulo: 'Meus projetos',
                  bloqueado: !logado,
                  aoTocar: () => _abrirProtegida(const HistoricoScreen()),
                ),
                _Atalho(
                  icone: Icons.favorite_border,
                  rotulo: 'Favoritas',
                  bloqueado: !logado,
                  aoTocar: () => _abrirProtegida(const FavoritosScreen()),
                ),
                _Atalho(
                  icone: Icons.receipt_long_outlined,
                  rotulo: 'Meus pedidos',
                  bloqueado: !logado,
                  aoTocar: () => _abrirProtegida(const PedidosScreen()),
                ),
                _Atalho(
                  icone: Icons.person_outline,
                  rotulo: 'Meu perfil',
                  bloqueado: !logado,
                  aoTocar: () => _abrirProtegida(const PerfilScreen()),
                ),
              ],
            ),
            if (!logado) ...[
              const SizedBox(height: 16),
              Text(
                'Simular, ver o catálogo e calcular tinta não exigem conta. '
                'Entre para salvar projetos, favoritar cores e fazer pedidos.',
                textAlign: TextAlign.center,
                style: tema.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.icone, required this.rotulo, required this.aoTocar, this.bloqueado = false});

  final IconData icone;
  final String rotulo;
  final VoidCallback aoTocar;
  final bool bloqueado;

  @override
  Widget build(BuildContext context) {
    final cores = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aoTocar,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icone, size: 30, color: cores.primary),
                  if (bloqueado)
                    Positioned(
                      right: -8,
                      bottom: -4,
                      child: Icon(Icons.lock, size: 14, color: cores.outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(rotulo, textAlign: TextAlign.center, maxLines: 2),
            ],
          ),
        ),
      ),
    );
  }
}
