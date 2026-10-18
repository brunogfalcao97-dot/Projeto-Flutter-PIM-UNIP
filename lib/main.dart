import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/app_theme.dart';
import 'config/branding.dart';
import 'providers/auth_provider.dart';
import 'providers/carrinho_provider.dart';
import 'providers/favoritos_provider.dart';
import 'screens/app_inicial.dart';
import 'services/cache_local.dart';
import 'services/calculo_service.dart';
import 'services/catalogo_service.dart';
import 'services/favorito_service.dart';
import 'services/pedido_service.dart';
import 'services/perfil_service.dart';
import 'services/simulacao_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // A sessão salva no aparelho é carregada pela tela de abertura (AppInicial).
  final auth = AuthProvider();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
        Provider<CacheLocal>(create: (_) => CacheLocal()),
        Provider<CatalogoService>(
          create: (c) => CatalogoService(c.read<AuthProvider>().api, c.read<CacheLocal>()),
        ),
        Provider<CalculoService>(create: (c) => CalculoService(c.read<AuthProvider>().api)),
        Provider<PedidoService>(create: (c) => PedidoService(c.read<AuthProvider>().api)),
        Provider<PerfilService>(create: (c) => PerfilService(c.read<AuthProvider>().api)),
        Provider<SimulacaoService>(create: (c) => SimulacaoService(c.read<AuthProvider>().api)),
        Provider<FavoritoService>(create: (c) => FavoritoService(c.read<AuthProvider>().api)),
        ChangeNotifierProvider<CarrinhoProvider>(create: (_) => CarrinhoProvider()),
        ChangeNotifierProvider<FavoritosProvider>(
          lazy: false,
          create: (c) => FavoritosProvider(c.read<AuthProvider>(), c.read<FavoritoService>()),
        ),
      ],
      child: const PimTintasApp(),
    ),
  );
}

class PimTintasApp extends StatelessWidget {
  const PimTintasApp({super.key});

  @override
  Widget build(BuildContext context) {
    // O app abre numa tela de carregamento com a logo e vai direto para a tela
    // inicial: câmera, pintura, catálogo e cálculo não exigem login. A conta só é
    // pedida para salvar projetos, favoritar e fechar pedidos.
    return MaterialApp(
      title: Branding.nomeEmpresa,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.claro,
      home: const AppInicial(),
    );
  }
}
