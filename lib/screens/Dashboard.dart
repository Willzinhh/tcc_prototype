import 'package:flutter/material.dart';

import '../models/sistema_rotacao.dart';
import '../widgets/configuracao_equipe.dart';
import 'estatisticas_screen.dart';
import 'historico_screen.dart';
import 'jogo_volei_screen.dart';

class TelaGerenciamento extends StatefulWidget {
  const TelaGerenciamento({super.key});

  @override
  State<TelaGerenciamento> createState() => _TelaGerenciamentoState();
}

class _TelaGerenciamentoState extends State<TelaGerenciamento> with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  ConfiguracaoEquipeDados _nossaEquipe = ConfiguracaoEquipeDados(
    nome: "Meu Time",
    elenco: const [],
    titulares: const [],
    sistema: SistemaRotacao.cincoPorUm,
  );
  ConfiguracaoEquipeDados _equipeAdversaria = ConfiguracaoEquipeDados(
    nome: "Adversário",
    elenco: const [],
    titulares: const [],
    sistema: SistemaRotacao.cincoPorUm,
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _iniciarScout() {
    if (!_nossaEquipe.pronta || !_equipeAdversaria.pronta) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Escale exatamente 6 titulares nas duas equipes antes de começar.")),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JogoVolei(
          nomeNossaEquipe: _nossaEquipe.nome,
          titularesNossos: _nossaEquipe.titulares,
          bancoNosso: _nossaEquipe.banco,
          sistemaNosso: _nossaEquipe.sistema,
          liberoNosso: _nossaEquipe.libero,
          nomeAdversario: _equipeAdversaria.nome,
          titularesAdversario: _equipeAdversaria.titulares,
          bancoAdversario: _equipeAdversaria.banco,
          sistemaAdversario: _equipeAdversaria.sistema,
          liberoAdversario: _equipeAdversaria.libero,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurar Partida"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.yellow,
          tabs: const [
            Tab(text: "NOSSA EQUIPE"),
            Tab(text: "ADVERSÁRIO"),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: "Estatísticas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaEstatisticas()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: "Histórico de partidas",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaHistorico()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConfiguracaoEquipe(
                    nomeInicial: "Meu Time",
                    onMudou: (dados) => setState(() => _nossaEquipe = dados),
                  ),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: ConfiguracaoEquipe(
                    nomeInicial: "Adversário",
                    onMudou: (dados) => setState(() => _equipeAdversaria = dados),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _iniciarScout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                "INICIAR SCOUT  (${_nossaEquipe.titulares.length}/6 x ${_equipeAdversaria.titulares.length}/6)",
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}