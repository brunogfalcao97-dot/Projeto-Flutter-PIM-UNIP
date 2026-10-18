import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/cor.dart';
import '../providers/auth_provider.dart';
import '../screens/login_screen.dart';
import '../services/api_client.dart';

/// Mostra uma mensagem rápida na parte de baixo da tela.
void mostrarAviso(BuildContext context, String mensagem, {String? rotuloAcao, VoidCallback? aoAcionar}) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(mensagem),
      action: rotuloAcao == null ? null : SnackBarAction(label: rotuloAcao, onPressed: aoAcionar ?? () {}),
    ));
}

/// Texto de um erro qualquer para mostrar ao cliente.
String textoDoErro(Object erro, [String padrao = 'Ocorreu um erro inesperado. Tente novamente.']) =>
    erro is ApiException ? erro.mensagem : padrao;

/// Abre o login se o cliente ainda não entrou. Devolve true quando há sessão.
/// Depois do `await`, quem chamou deve conferir `mounted`.
Future<bool> exigirLogin(BuildContext context) async {
  if (context.read<AuthProvider>().autenticado) return true;
  final entrou = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return entrou == true;
}

/// Pede um texto curto ao cliente. Devolve null se ele cancelar.
Future<String?> pedirTexto(
  BuildContext context, {
  required String titulo,
  required String rotulo,
  String inicial = '',
  String confirmar = 'Salvar',
}) {
  final controlador = TextEditingController(text: inicial);
  return showDialog<String>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: TextField(
        controller: controlador,
        autofocus: true,
        maxLength: 80,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: rotulo),
        onSubmitted: (v) => Navigator.of(contexto).pop(v.trim()),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(contexto).pop(), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.of(contexto).pop(controlador.text.trim()),
          child: Text(confirmar),
        ),
      ],
    ),
  );
}

/// Pergunta sim/não antes de uma ação que não dá para desfazer.
Future<bool> confirmar(
  BuildContext context, {
  required String titulo,
  required String texto,
  String confirmarRotulo = 'Confirmar',
}) async {
  final resposta = await showDialog<bool>(
    context: context,
    builder: (contexto) => AlertDialog(
      title: Text(titulo),
      content: Text(texto),
      actions: [
        TextButton(onPressed: () => Navigator.of(contexto).pop(false), child: const Text('Voltar')),
        FilledButton(onPressed: () => Navigator.of(contexto).pop(true), child: Text(confirmarRotulo)),
      ],
    ),
  );
  return resposta == true;
}

/// Ícone + texto (+ botão) para telas vazias ou com erro.
class MensagemEstado extends StatelessWidget {
  const MensagemEstado({super.key, required this.icone, required this.texto, this.acao});

  final IconData icone;
  final String texto;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(texto, textAlign: TextAlign.center),
            if (acao != null) ...[const SizedBox(height: 16), acao!],
          ],
        ),
      ),
    );
  }
}

/// Bolinha com a cor.
class AmostraCor extends StatelessWidget {
  const AmostraCor({super.key, required this.cor, this.tamanho = 36});

  final Cor cor;
  final double tamanho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        color: cor.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26),
      ),
    );
  }
}
