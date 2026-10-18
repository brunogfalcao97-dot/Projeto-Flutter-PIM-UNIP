import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../widgets/logo_empresa.dart';

/// Login e cadastro (alterna pelo botão de baixo).
///
/// É aberta por cima da tela anterior e devolve `true` quando o cliente entra,
/// ou `false`/`null` se ele desistir. Assim quem abriu sabe se pode continuar.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();

  bool _cadastro = false;
  bool _carregando = false;
  bool _ocultarSenha = true;

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    setState(() => _carregando = true);
    try {
      final email = _emailCtrl.text.trim();
      if (_cadastro) {
        await auth.cadastrar(_nomeCtrl.text.trim(), email, _senhaCtrl.text);
      } else {
        await auth.entrar(email, _senhaCtrl.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _mostrarErro(e.mensagem);
    } catch (_) {
      _mostrarErro('Ocorreu um erro inesperado. Tente novamente.');
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  void _mostrarErro(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(child: LogoEmpresa(altura: 120)),
                    const SizedBox(height: 16),
                    Text(
                      _cadastro
                          ? 'Crie sua conta para salvar suas simulações'
                          : 'Entre para salvar e rever suas simulações',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 28),
                    if (_cadastro) ...[
                      TextFormField(
                        controller: _nomeCtrl,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Nome', prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v == null || v.trim().length < 2) ? 'Informe seu nome' : null,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(labelText: 'E-mail', prefixIcon: Icon(Icons.mail_outline)),
                      validator: (v) {
                        final email = v?.trim() ?? '';
                        return (!email.contains('@') || !email.contains('.')) ? 'Informe um e-mail válido' : null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _senhaCtrl,
                      obscureText: _ocultarSenha,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Senha',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_ocultarSenha ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                          onPressed: () => setState(() => _ocultarSenha = !_ocultarSenha),
                        ),
                      ),
                      validator: (v) => (v == null || v.length < 6) ? 'A senha precisa ter ao menos 6 caracteres' : null,
                      onFieldSubmitted: (_) => _enviar(),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _carregando ? null : _enviar,
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: _carregando
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                          : Text(_cadastro ? 'Criar conta' : 'Entrar'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _carregando ? null : () => setState(() => _cadastro = !_cadastro),
                      child: Text(_cadastro ? 'Já tenho conta' : 'Ainda não tenho conta'),
                    ),
                    TextButton(
                      onPressed: _carregando ? null : () => Navigator.of(context).pop(false),
                      child: const Text('Continuar sem entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
