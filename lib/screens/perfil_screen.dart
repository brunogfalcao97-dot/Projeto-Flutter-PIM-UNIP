import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/perfil.dart';
import '../providers/auth_provider.dart';
import '../services/perfil_service.dart';
import '../widgets/estados.dart';

/// Dados do cliente, troca de senha e saída da conta.
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _telefoneCtrl = TextEditingController();

  Perfil? _perfil;
  String? _erro;
  bool _carregando = true;
  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _telefoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() {
      _carregando = true;
      _erro = null;
    });
    try {
      final p = await context.read<PerfilService>().obter();
      if (!mounted) return;
      _nomeCtrl.text = p.nome;
      _telefoneCtrl.text = p.telefone ?? '';
      setState(() => _perfil = p);
    } catch (e) {
      if (!mounted) return;
      setState(() => _erro = textoDoErro(e, 'Não foi possível carregar o perfil.'));
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    setState(() => _salvando = true);
    try {
      final telefone = _telefoneCtrl.text.trim();
      final p = await context.read<PerfilService>().atualizar(
            nome: _nomeCtrl.text.trim(),
            telefone: telefone.isEmpty ? null : telefone,
          );
      await auth.atualizarNome(p.nome);
      if (!mounted) return;
      setState(() => _perfil = p);
      mostrarAviso(context, 'Perfil atualizado.');
    } catch (e) {
      mostrarAviso(context, textoDoErro(e, 'Não foi possível salvar o perfil.'));
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _alterarSenha() async {
    final atualCtrl = TextEditingController();
    final novaCtrl = TextEditingController();
    final chave = GlobalKey<FormState>();

    final dados = await showDialog<(String, String)>(
      context: context,
      builder: (contexto) => AlertDialog(
        title: const Text('Alterar senha'),
        content: Form(
          key: chave,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: atualCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Senha atual'),
                validator: (v) => (v == null || v.isEmpty) ? 'Informe a senha atual' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: novaCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Nova senha'),
                validator: (v) => (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (chave.currentState!.validate()) {
                Navigator.of(contexto).pop((atualCtrl.text, novaCtrl.text));
              }
            },
            child: const Text('Alterar'),
          ),
        ],
      ),
    );
    atualCtrl.dispose();
    novaCtrl.dispose();
    if (dados == null || !mounted) return;

    try {
      await context.read<PerfilService>().alterarSenha(senhaAtual: dados.$1, novaSenha: dados.$2);
      if (mounted) mostrarAviso(context, 'Senha alterada.');
    } catch (e) {
      if (mounted) mostrarAviso(context, textoDoErro(e, 'Não foi possível alterar a senha.'));
    }
  }

  Future<void> _sair() async {
    final navegador = Navigator.of(context);
    await context.read<AuthProvider>().sair();
    navegador.pop();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Meu perfil')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : _perfil == null
              ? MensagemEstado(
                  icone: Icons.cloud_off,
                  texto: _erro ?? 'Perfil indisponível.',
                  acao: FilledButton(onPressed: _carregar, child: const Text('Tentar novamente')),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            initialValue: _perfil!.email,
                            enabled: false,
                            decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _nomeCtrl,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                            validator: (v) => (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _telefoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Telefone', prefixIcon: Icon(Icons.phone_outlined)),
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _salvando ? null : _salvar,
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            child: _salvando
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                                : const Text('Salvar alterações'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _alterarSenha,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Alterar senha'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    ),
                    if (auth.ehAdmin) ...[
                      const SizedBox(height: 16),
                      const Card(
                        child: ListTile(
                          leading: Icon(Icons.admin_panel_settings_outlined),
                          title: Text('Conta de administrador'),
                          subtitle: Text('Catálogo, estoque, cupons e pedidos são gerenciados pela API (documentação Scalar).'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextButton.icon(
                      onPressed: _sair,
                      icon: const Icon(Icons.logout),
                      label: const Text('Sair da conta'),
                    ),
                  ],
                ),
    );
  }
}
