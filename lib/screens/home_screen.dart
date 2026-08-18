import 'package:flutter/material.dart';

import '../core/utils/partida_em_andamento_repository.dart';
import '../models/jogador.dart';
import '../models/partida_em_andamento.dart';
import 'dashboard.dart';
import 'estatisticas_screen.dart';
import 'jogo_volei_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PartidaEmAndamentoRepository _repositorioEmAndamento = PartidaEmAndamentoRepository();
  late Future<PartidaEmAndamento?> _futureJogoEmAndamento;

  @override
  void initState() {
    super.initState();
    _futureJogoEmAndamento = _repositorioEmAndamento.carregar();
  }

  void _recarregar() {
    setState(() {
      _futureJogoEmAndamento = _repositorioEmAndamento.carregar();
    });
  }

  Future<void> _continuarJogo() async {
    final estado = await _repositorioEmAndamento.carregar();
    if (estado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nenhuma partida em andamento pra continuar.")),
      );
      return;
    }

    // O elenco/titulares/banco iniciais servem só de referência pro
    // construtor — o estado salvo (com a rotação/banco JÁ atualizados)
    // é o que realmente é retomado dentro da tela.
    final Jogador? liberoNosso = estado.liberoNosso;
    final Jogador? liberoAdversario = estado.liberoAdversario;

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JogoVolei(
          nomeNossaEquipe: estado.nomeNossaEquipe,
          titularesNossos: estado.posicoesNossoTimeAtual,
          bancoNosso: estado.bancoNossoAtual,
          sistemaNosso: estado.sistemaNosso,
          liberoNosso: liberoNosso,
          nomeAdversario: estado.nomeAdversario,
          titularesAdversario: estado.posicoesAdversarioAtual,
          bancoAdversario: estado.bancoAdversarioAtual,
          sistemaAdversario: estado.sistemaAdversario,
          liberoAdversario: liberoAdversario,
          estadoSalvo: estado,
        ),
      ),
    );
    _recarregar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'MatchCore Scout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.blue.shade800,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Cabeçalho de boas-vindas
              Text(
                'Bem-vindo ao Scout',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[900],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'O que você deseja fazer hoje?',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.blueGrey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Card de partida em andamento (só aparece se existir uma)
              FutureBuilder<PartidaEmAndamento?>(
                future: _futureJogoEmAndamento,
                builder: (context, snapshot) {
                  final estado = snapshot.data;
                  if (estado == null) return const SizedBox.shrink();
                  return Card(
                    color: Colors.orange.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.orange.shade200),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.play_circle_fill, color: Colors.orange.shade700, size: 32),
                      title: Text(
                        "${estado.nomeNossaEquipe} x ${estado.nomeAdversario}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "Set ${estado.numeroSetAtual} · ${estado.placarNossaEquipe} x ${estado.placarAdversario} · Sets ${estado.setsVencidosNos}x${estado.setsVencidosAdversario}",
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _continuarJogo,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // Grid com os botões principais
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                  children: [
                    _MenuCard(
                      titulo: 'Nova Partida',
                      subtitulo: 'Iniciar scout do zero',
                      icone: Icons.sports_volleyball,
                      cor: Colors.blue.shade600,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaGerenciamento()),
                        );
                        _recarregar();
                      },
                    ),
                    FutureBuilder<PartidaEmAndamento?>(
                      future: _futureJogoEmAndamento,
                      builder: (context, snapshot) {
                        final temJogo = snapshot.data != null;
                        return _MenuCard(
                          titulo: 'Continuar Jogo',
                          subtitulo: temJogo ? 'Partida em andamento' : 'Nenhuma partida salva',
                          icone: Icons.play_arrow_rounded,
                          cor: temJogo ? Colors.orange.shade600 : Colors.grey.shade400,
                          onTap: _continuarJogo,
                        );
                      },
                    ),
                    _MenuCard(
                      titulo: 'Estatísticas',
                      subtitulo: 'Análise de desempenho',
                      icone: Icons.bar_chart_rounded,
                      cor: Colors.purple.shade500,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaEstatisticas()),
                        );
                      },
                    ),
                    _MenuCard(
                      titulo: 'Equipes',
                      subtitulo: 'Gerenciar elencos',
                      icone: Icons.group_rounded,
                      cor: Colors.teal.shade500,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const TelaGerenciamento()),
                        );
                        _recarregar();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Componente de Card reutilizável para o menu principal
class _MenuCard extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icone;
  final Color cor;
  final VoidCallback onTap;

  const _MenuCard({
    required this.titulo,
    required this.subtitulo,
    required this.icone,
    required this.cor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icone, size: 36, color: cor),
              ),
              const Spacer(),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitulo,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}