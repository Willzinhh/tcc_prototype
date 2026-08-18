import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../core/utils/estatisticas_calculator.dart';
import '../core/utils/partida_repository.dart';
import '../models/partida.dart';
import '../widgets/pdf_relatorio.dart';
import '../widgets/tabela_estatisticas.dart';

/// Mostra as estatísticas de UMA partida no formato de planilha
/// (jogador × fundamento, por set), parecido com o relatório clássico
/// de análise de desempenho — com exportação em PDF (ver
/// utils/pdf_relatorio.dart).
class TelaTabelaEstatisticas extends StatefulWidget {
  const TelaTabelaEstatisticas({super.key});

  @override
  State<TelaTabelaEstatisticas> createState() => _TelaTabelaEstatisticasState();
}

class _TelaTabelaEstatisticasState extends State<TelaTabelaEstatisticas> {
  final PartidaRepository _repositorio = PartidaRepository();
  late Future<List<Partida>> _futurePartidas;
  Partida? _partidaSelecionada;
  bool _mostrandoNosso = true;

  @override
  void initState() {
    super.initState();
    _futurePartidas = _carregar();
  }

  Future<List<Partida>> _carregar() async {
    final partidas = await _repositorio.listar();
    if (partidas.isNotEmpty) {
      setState(() => _partidaSelecionada = partidas.first);
    }
    return partidas;
  }

  Future<void> _exportarPdf() async {
    final partida = _partidaSelecionada;
    if (partida == null) return;
    final bytes = await PdfRelatorio.gerar(partida);
    await Printing.layoutPdf(
      onLayout: (formato) async => bytes,
      name: "relatorio_${partida.nomeEquipe}_${partida.data.toIso8601String().split('T').first}.pdf",
    );
  }

  static const double _wNome = 130;
  static const double _wSub = 34;
  static const int _subPorGrupo = 7; // 3 símbolos + T + %EF + Coef.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tabela Detalhada"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            tooltip: "Exportar PDF",
            onPressed: _partidaSelecionada == null ? null : _exportarPdf,
          ),
        ],
      ),
      body: FutureBuilder<List<Partida>>(
        future: _futurePartidas,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final partidas = snapshot.data ?? [];
          if (partidas.isEmpty) {
            return const Center(child: Text("Nenhuma partida salva ainda."));
          }

          final partida = _partidaSelecionada ?? partidas.first;
          final numerosDeSet = partida.sets.map((s) => s.numeroSet).toSet().toList()..sort();

          return DefaultTabController(
            length: numerosDeSet.length + 1, // + aba TOTAL
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: DropdownButton<Partida>(
                    isExpanded: true,
                    value: partida,
                    items: partidas
                        .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        "${p.nomeEquipe} — ${p.setsVencidosNos}x${p.setsVencidosAdversario} (${_formatarData(p.data)})",
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                        .toList(),
                    onChanged: (p) => setState(() => _partidaSelecionada = p),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: SegmentedButton<bool>(
                    segments: [
                      ButtonSegment(value: true, label: Text(partida.nomeEquipe)),
                      ButtonSegment(value: false, label: Text(partida.nomeAdversario)),
                    ],
                    selected: {_mostrandoNosso},
                    onSelectionChanged: (selecionado) {
                      setState(() => _mostrandoNosso = selecionado.first);
                    },
                  ),
                ),
                const SizedBox(height: 8),
                TabBar(
                  isScrollable: true,
                  labelColor: Colors.green[900],
                  tabs: [
                    for (final n in numerosDeSet) Tab(text: "${n}º Set"),
                    const Tab(text: "TOTAL"),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final n in numerosDeSet)
                        _tabelaParaSet(
                          TabelaEstatisticas.montar(partida.jogadas, numeroSet: n, nosso: _mostrandoNosso),
                        ),
                      _tabelaParaSet(
                        TabelaEstatisticas.montar(partida.jogadas, numeroSet: null, nosso: _mostrandoNosso),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatarData(DateTime data) {
    final d = data.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(d.day)}/${dois(d.month)}/${d.year}";
  }

  Widget _tabelaParaSet(TabelaEstatisticas tabela) {
    if (tabela.linhasJogadores.isEmpty) {
      return const Center(child: Text("Sem jogadas registradas nesse set."));
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _linhaCabecalhoGrupos(tabela),
            _linhaCabecalhoSubColunas(tabela),
            for (final linha in tabela.linhasJogadores) _linhaDados(tabela, linha, destaque: false),
            _linhaDados(tabela, tabela.linhaTotal, destaque: true),
          ],
        ),
      ),
    );
  }

  Widget _linhaCabecalhoGrupos(TabelaEstatisticas tabela) {
    return Row(
      children: [
        Container(width: _wNome, height: 28, color: Colors.green[900]),
        for (final coluna in tabela.colunas)
          Container(
            width: _wSub * _subPorGrupo,
            height: 28,
            alignment: Alignment.center,
            color: Colors.green[800],
            child: Text(
              coluna.titulo,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _linhaCabecalhoSubColunas(TabelaEstatisticas tabela) {
    return Row(
      children: [
        Container(
          width: _wNome,
          height: 24,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: Colors.green[100],
          child: const Text("ATLETA", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ),
        for (final coluna in tabela.colunas)
          for (final sub in [...coluna.rotulosSimbolos, "/", "T", "%EF", "Coef."])
            Container(
              width: _wSub,
              height: 24,
              alignment: Alignment.center,
              color: Colors.green[100],
              child: Text(sub, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            ),
      ],
    );
  }

  Widget _linhaDados(TabelaEstatisticas tabela, LinhaTabela linha, {required bool destaque}) {
    final Color corFundo = destaque ? Colors.yellow[100]! : Colors.white;

    return Row(
      children: [
        Container(
          width: _wNome,
          height: 26,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          color: corFundo,
          child: Text(
            linha.rotulo,
            style: TextStyle(fontSize: 10, fontWeight: destaque ? FontWeight.bold : FontWeight.normal),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        for (final coluna in tabela.colunas)
          ..._celulasDaColuna(coluna, linha.porColuna[coluna.titulo]!, corFundo, destaque),
      ],
    );
  }

  List<Widget> _celulasDaColuna(
      ColunaEstatistica coluna,
      EstatisticasFundamento dados,
      Color corFundo,
      bool destaque,
      ) {
    final double? eficiencia = coluna.pesos != null
        ? dados.eficienciaPonderada(coluna.pesos!)
        : (dados.total == 0 ? null : dados.eficiencia);
    final double? coeficiente = dados.coeficiente;

    final valores = [
      dados.excelente.toString(),
      dados.positivo.toString(),
      dados.negativoComErro.toString(),
      dados.transicao.toString(),
      dados.total.toString(),
      eficiencia == null ? "-" : "${eficiencia.toStringAsFixed(0)}%",
      coeficiente == null ? "-" : coeficiente.toStringAsFixed(2),
    ];

    return List.generate(
      valores.length,
          (i) => Container(
        width: _wSub,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: corFundo,
          border: Border.all(color: Colors.grey[300]!, width: 0.5),
        ),
        child: Text(
          valores[i],
          style: TextStyle(
            fontSize: 10,
            fontWeight: destaque ? FontWeight.bold : FontWeight.normal,
            color: i == 5 && eficiencia != null && eficiencia < 0 ? Colors.red : Colors.black87,
          ),
        ),
      ),
    );
  }
}