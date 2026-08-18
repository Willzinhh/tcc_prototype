import 'package:flutter/material.dart';

import '../core/utils/partida_repository.dart';
import '../models/partida.dart';

class TelaHistorico extends StatefulWidget {
  const TelaHistorico({super.key});

  @override
  State<TelaHistorico> createState() => _TelaHistoricoState();
}

class _TelaHistoricoState extends State<TelaHistorico> {
  final PartidaRepository _repositorio = PartidaRepository();
  late Future<List<Partida>> _futurePartidas;

  @override
  void initState() {
    super.initState();
    _futurePartidas = _repositorio.listar();
  }

  void _recarregar() {
    setState(() {
      _futurePartidas = _repositorio.listar();
    });
  }

  Future<void> _confirmarExclusao(Partida partida) async {
    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Excluir partida?"),
        content: Text(
          "Remover o registro de ${partida.nomeEquipe} de ${_formatarData(partida.data)}?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Excluir"),
          ),
        ],
      ),
    );
    if (confirmar == true) {
      await _repositorio.excluir(partida.id);
      _recarregar();
    }
  }

  String _formatarData(DateTime data) {
    final DateTime d = data.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(d.day)}/${dois(d.month)}/${d.year} ${dois(d.hour)}:${dois(d.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Histórico de Partidas"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<Partida>>(
        future: _futurePartidas,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Partida> partidas = snapshot.data ?? [];
          if (partidas.isEmpty) {
            return const Center(
              child: Text("Nenhuma partida salva ainda."),
            );
          }

          return ListView.builder(
            itemCount: partidas.length,
            itemBuilder: (context, index) {
              final Partida partida = partidas[index];
              final bool vitoria = partida.vencemosPartida;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: vitoria ? Colors.green[700] : Colors.red[700],
                    child: Icon(
                      vitoria ? Icons.emoji_events : Icons.close,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  title: Text(
                    "${partida.nomeEquipe}  ${partida.setsVencidosNos} x ${partida.setsVencidosAdversario} (sets)  Adversário",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    "${_formatarData(partida.data)} · ${partida.sets.map((s) => '${s.placarNosso}x${s.placarAdversario}').join(', ')}",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _confirmarExclusao(partida),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}