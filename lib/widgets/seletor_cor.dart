import 'package:flutter/material.dart';

import '../models/cor.dart';
import 'estados.dart';

/// Abre uma folha com busca para escolher uma cor do catálogo. Devolve null se fechar sem escolher.
Future<Cor?> escolherCor(BuildContext context, List<Cor> cores, {Cor? atual}) {
  return showModalBottomSheet<Cor>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _FolhaCores(cores: cores, atualId: atual?.id),
  );
}

class _FolhaCores extends StatefulWidget {
  const _FolhaCores({required this.cores, this.atualId});

  final List<Cor> cores;
  final int? atualId;

  @override
  State<_FolhaCores> createState() => _FolhaCoresState();
}

class _FolhaCoresState extends State<_FolhaCores> {
  String _busca = '';

  @override
  Widget build(BuildContext context) {
    final termo = _busca.trim().toLowerCase();
    final lista = termo.isEmpty
        ? widget.cores
        : widget.cores
            .where((c) =>
                c.nome.toLowerCase().contains(termo) ||
                c.codigoHex.toLowerCase().contains(termo) ||
                (c.familia ?? '').toLowerCase().contains(termo) ||
                (c.codigoPantone ?? '').toLowerCase().contains(termo))
            .toList();

    final altura = MediaQuery.of(context).size.height * 0.75;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: altura,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  labelText: 'Buscar cor (nome, HEX, Pantone)',
                ),
                onChanged: (v) => setState(() => _busca = v),
              ),
            ),
            Expanded(
              child: lista.isEmpty
                  ? const MensagemEstado(icone: Icons.search_off, texto: 'Nenhuma cor encontrada.')
                  : ListView.builder(
                      itemCount: lista.length,
                      itemBuilder: (_, i) {
                        final c = lista[i];
                        final detalhes = [
                          c.codigoHex.toUpperCase(),
                          if (c.codigoPantone != null && c.codigoPantone!.isNotEmpty) c.codigoPantone!,
                        ].join(' · ');
                        return ListTile(
                          leading: AmostraCor(cor: c),
                          title: Text(c.nome),
                          subtitle: Text(detalhes),
                          trailing: c.id == widget.atualId ? const Icon(Icons.check_circle) : null,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
