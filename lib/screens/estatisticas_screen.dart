import 'package:flutter/material.dart';

import '../core/utils/estatisticas_calculator.dart';
import '../core/utils/partida_repository.dart';
import '../models/complexo_jogo.dart';
import '../models/fundamento.dart';
import '../models/partida.dart';
import 'tabela_estatisticas_screen.dart';

class TelaEstatisticas extends StatefulWidget {
  const TelaEstatisticas({super.key});

  @override
  State<TelaEstatisticas> createState() => _TelaEstatisticasState();
}

class _TelaEstatisticasState extends State<TelaEstatisticas> {
  final PartidaRepository _repositorio = PartidaRepository();
  late Future<EstatisticasGerais> _futureEstatisticas;

  @override
  void initState() {
    super.initState();
    _futureEstatisticas = _carregar();
  }

  Future<EstatisticasGerais> _carregar() async {
    final List<Partida> partidas = await _repositorio.listar();
    return EstatisticasGerais.calcular(partidas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Estatísticas"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            tooltip: "Tabela detalhada (estilo planilha)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TelaTabelaEstatisticas()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<EstatisticasGerais>(
        future: _futureEstatisticas,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final EstatisticasGerais? stats = snapshot.data;
          if (stats == null || stats.totalPartidas == 0) {
            return const Center(
              child: Text("Salve pelo menos uma partida para ver estatísticas."),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _cardResumo(stats),
              const SizedBox(height: 20),
              _tituloSecao("Nossos Jogadores"),
              const SizedBox(height: 8),
              ..._listaJogadores(stats.porJogadorNosso, stats.porJogadorEFundamento),
              const SizedBox(height: 20),
              _tituloSecao("Jogadores do Adversário"),
              const SizedBox(height: 8),
              ..._listaJogadores(stats.porJogadorAdversario, const {}),
              const SizedBox(height: 20),
              _tituloSecao("Zonas que mais geram pontos"),
              const SizedBox(height: 8),
              ..._listaZonas(stats.pontosPorZona, Colors.greenAccent),
              const SizedBox(height: 20),
              _tituloSecao("Zonas que mais geram erros"),
              const SizedBox(height: 8),
              ..._listaZonas(stats.errosPorZona, Colors.redAccent),
              const SizedBox(height: 20),
              _tituloSecao("Aproveitamento por Complexo de Jogo"),
              const SizedBox(height: 8),
              ..._listaComplexos(stats),
              const SizedBox(height: 20),
              _tituloSecao("Eficiência por Fundamento (equipe)"),
              const SizedBox(height: 8),
              ..._listaFundamentos(stats.porFundamento),
            ],
          );
        },
      ),
    );
  }

  Widget _tituloSecao(String texto) {
    return Text(
      texto,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    );
  }

  Widget _cardResumo(EstatisticasGerais stats) {
    return Card(
      color: Colors.green[900],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${stats.totalPartidas} partida(s) salva(s)",
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _blocoResumo("Vitórias", stats.vitorias, Colors.greenAccent),
                _blocoResumo("Derrotas", stats.derrotas, Colors.redAccent),
                _blocoResumo("Empates", stats.empates, Colors.white70),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Saldo de pontos: ${stats.totalPontosNossos} x ${stats.totalPontosAdversario}",
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blocoResumo(String label, int valor, Color cor) {
    return Column(
      children: [
        Text(
          valor.toString(),
          style: TextStyle(color: cor, fontSize: 22, fontWeight: FontWeight.w900),
        ),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  List<Widget> _listaJogadores(
      Map<String, EstatisticasJogador> porJogador,
      Map<String, Map<String, EstatisticasFundamento>> porJogadorEFundamento,
      ) {
    final entradas = porJogador.entries.toList()
      ..sort((a, b) => b.value.pontos.compareTo(a.value.pontos));

    if (entradas.isEmpty) {
      return [const Text("Nenhuma ação com jogador identificado ainda.")];
    }

    return entradas.map((entrada) {
      final nome = entrada.key;
      final dados = entrada.value;
      final porFundamento = porJogadorEFundamento[nome] ?? {};

      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("${dados.pontos} pts · ${dados.erros} erros",
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: _barraComparativa(dados.pontos, dados.erros),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: porFundamento.isEmpty
                  ? const Text("Sem ações detalhadas por fundamento ainda.",
                  style: TextStyle(fontSize: 11, color: Colors.grey))
                  : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _ordemFundamentos(porFundamento.keys)
                    .map((sigla) => _linhaFundamento(sigla, porFundamento[sigla]!))
                    .toList(),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// Ordena as siglas de fundamento na sequência S-R-E-A-B-D (fica mais
  /// fácil de ler do que ordem alfabética ou de inserção).
  List<String> _ordemFundamentos(Iterable<String> siglas) {
    const ordem = ["S", "R", "E", "A", "B", "D"];
    final presentes = siglas.toSet();
    return ordem.where(presentes.contains).toList();
  }

  List<Widget> _listaFundamentos(Map<String, EstatisticasFundamento> porFundamento) {
    if (porFundamento.isEmpty) {
      return [const Text("Sem dados suficientes ainda.")];
    }
    return _ordemFundamentos(porFundamento.keys)
        .map((sigla) => Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: _linhaFundamento(sigla, porFundamento[sigla]!),
      ),
    ))
        .toList();
  }

  /// Uma linha com o nome do fundamento, o total de ações, a eficiência
  /// (# - =) / total no padrão DataVolley, e uma barrinha com a
  /// distribuição dos 5 símbolos.
  Widget _linhaFundamento(String sigla, EstatisticasFundamento dados) {
    final Fundamento fundamento = FundamentoLabel.porSigla(sigla);
    final double eficiencia = dados.eficiencia;
    final Color corEficiencia = eficiencia > 0
        ? Colors.greenAccent
        : (eficiencia < 0 ? Colors.redAccent : Colors.grey);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$sigla · ${fundamento.nomeCompleto}",
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                "${eficiencia.toStringAsFixed(0)}%  (${dados.total} ações)",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: corEficiencia),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _barraSimbolos(dados),
        ],
      ),
    );
  }

  /// Barra empilhada com a proporção de cada símbolo (#, +, -, =, /).
  Widget _barraSimbolos(EstatisticasFundamento dados) {
    if (dados.total == 0) return const SizedBox(height: 8);

    final partes = <(int, Color)>[
      (dados.excelente, Colors.greenAccent),
      (dados.positivo, Colors.lightGreen),
      (dados.negativo, Colors.orangeAccent),
      (dados.erro, Colors.redAccent),
      (dados.transicao, Colors.blueGrey),
    ];

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 8,
        child: Row(
          children: partes
              .where((p) => p.$1 > 0)
              .map((p) => Expanded(flex: p.$1, child: Container(color: p.$2)))
              .toList(),
        ),
      ),
    );
  }

  Widget _barraComparativa(int pontos, int erros) {
    final int total = pontos + erros;
    return LayoutBuilder(
      builder: (context, constraints) {
        final double larguraTotal = constraints.maxWidth;
        final double larguraPontos = total == 0 ? 0.0 : larguraTotal * (pontos / total);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            width: larguraTotal,
            color: Colors.redAccent.withOpacity(0.35),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(width: larguraPontos, height: 8, color: Colors.greenAccent),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _listaZonas(Map<String, int> porZona, Color cor) {
    if (porZona.isEmpty) {
      return [const Text("Sem dados suficientes ainda.")];
    }

    final entradas = porZona.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = entradas.take(5).toList();
    final int maiorValor = top5.first.value;

    return top5.map((entrada) {
      final double fracao = entrada.value / maiorValor;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(entrada.key, style: const TextStyle(fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 10,
                      width: constraints.maxWidth,
                      color: Colors.white10,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: constraints.maxWidth * fracao,
                          height: 10,
                          color: cor,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Text("${entrada.value}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _listaComplexos(EstatisticasGerais stats) {
    if (stats.porComplexo.isEmpty) {
      return [const Text("Sem dados suficientes ainda.")];
    }

    const ordem = [
      ComplexoJogo.k0,
      ComplexoJogo.kI,
      ComplexoJogo.kII,
      ComplexoJogo.kIII,
      ComplexoJogo.kIV,
      ComplexoJogo.kV,
    ];

    final entradas = ordem
        .where((c) => stats.porComplexo.containsKey(c))
        .map((c) => MapEntry(c, stats.porComplexo[c]!))
        .toList();

    return entradas.map((entrada) {
      final complexo = entrada.key;
      final dados = entrada.value;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      ComplexoJogo.rotulo(complexo),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  Text(
                    "${dados.pontos} pts · ${dados.erros} erros",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _barraComparativa(dados.pontos, dados.erros),
            ],
          ),
        ),
      );
    }).toList();
  }
}