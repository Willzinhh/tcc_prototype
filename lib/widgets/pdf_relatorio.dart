import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/estatisticas_calculator.dart';
import '../models/partida.dart';
import '../models/set_resultado.dart';
import 'tabela_estatisticas.dart';

/// Gera o relatório de desempenho de uma partida em PDF, no mesmo
/// formato de tabela (jogador × fundamento, por set) mostrado na tela.
class PdfRelatorio {
  static const double _wNome = 62;
  static const double _wSub = 15;
  static const int _subPorGrupo = 7; // 3 símbolos + T + %EF + Coef.
  static const double _alturaLinha = 13;

  static Future<Uint8List> gerar(Partida partida) async {
    final documento = pw.Document();
    final numerosDeSet = partida.sets.map((s) => s.numeroSet).toSet().toList()..sort();

    documento.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(16),
        header: (context) => context.pageNumber == 1 ? _cabecalho(partida) : pw.SizedBox(),
        build: (context) => [
          for (final numeroSet in numerosDeSet) ..._blocoSet(partida, numeroSet),
          _tituloSecao("TOTAL DA PARTIDA — ${partida.nomeEquipe.toUpperCase()}"),
          _tabelaPdf(TabelaEstatisticas.montar(partida.jogadas, numeroSet: null, nosso: true)),
          pw.SizedBox(height: 14),
          _tituloSecao("TOTAL DA PARTIDA — ${partida.nomeAdversario.toUpperCase()}"),
          _tabelaPdf(TabelaEstatisticas.montar(partida.jogadas, numeroSet: null, nosso: false)),
        ],
      ),
    );

    return documento.save();
  }

  static pw.Widget _cabecalho(Partida partida) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Relatório de Desempenho — ${partida.nomeEquipe} x ${partida.nomeAdversario}",
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          "Data: ${_formatarData(partida.data)}   ·   Placar de sets: ${partida.setsVencidosNos} x ${partida.setsVencidosAdversario}",
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.SizedBox(height: 6),
        pw.Divider(thickness: 0.5),
      ],
    );
  }

  static List<pw.Widget> _blocoSet(Partida partida, int numeroSet) {
    final resultado = partida.sets.firstWhere(
          (s) => s.numeroSet == numeroSet,
      orElse: () => SetResultado(numeroSet: numeroSet, placarNosso: 0, placarAdversario: 0),
    );
    return [
      _tituloSecao(
        "${numeroSet}º SET  (${resultado.placarNosso} x ${resultado.placarAdversario})  ·  ${partida.nomeEquipe}",
      ),
      _tabelaPdf(TabelaEstatisticas.montar(partida.jogadas, numeroSet: numeroSet, nosso: true)),
      pw.SizedBox(height: 8),
      _tituloSecao(
        "${numeroSet}º SET  (${resultado.placarNosso} x ${resultado.placarAdversario})  ·  ${partida.nomeAdversario}",
      ),
      _tabelaPdf(TabelaEstatisticas.montar(partida.jogadas, numeroSet: numeroSet, nosso: false)),
      pw.SizedBox(height: 14),
    ];
  }

  static pw.Widget _tituloSecao(String texto) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Text(texto, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
    );
  }

  static String _formatarData(DateTime data) {
    final d = data.toLocal();
    String dois(int n) => n.toString().padLeft(2, '0');
    return "${dois(d.day)}/${dois(d.month)}/${d.year}";
  }

  static pw.Widget _celula(
      String texto,
      double largura, {
        PdfColor? fundo,
        PdfColor? cor,
        bool negrito = false,
        double fonte = 5.5,
      }) {
    return pw.Container(
      width: largura,
      height: _alturaLinha,
      alignment: pw.Alignment.center,
      decoration: pw.BoxDecoration(
        color: fundo,
        border: pw.Border.all(color: PdfColors.grey400, width: 0.4),
      ),
      child: pw.Text(
        texto,
        style: pw.TextStyle(
          fontSize: fonte,
          color: cor ?? PdfColors.black,
          fontWeight: negrito ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static List<String> _valoresColuna(ColunaEstatistica coluna, EstatisticasFundamento dados) {
    final double? eficiencia = coluna.pesos != null
        ? dados.eficienciaPonderada(coluna.pesos!)
        : (dados.total == 0 ? null : dados.eficiencia);
    final double? coeficiente = dados.coeficiente;

    return [
      dados.excelente.toString(),
      dados.positivo.toString(),
      dados.negativoComErro.toString(),
      dados.transicao.toString(),
      dados.total.toString(),
      eficiencia == null ? "-" : "${eficiencia.toStringAsFixed(0)}%",
      coeficiente == null ? "-" : coeficiente.toStringAsFixed(2),
    ];
  }

  static pw.Widget _tabelaPdf(TabelaEstatisticas tabela) {
    if (tabela.linhasJogadores.isEmpty) {
      return pw.Text("Sem jogadas registradas nesse set.", style: const pw.TextStyle(fontSize: 8));
    }

    final linhaGrupos = pw.Row(children: [
      _celula("", _wNome, fundo: PdfColors.green900),
      for (final coluna in tabela.colunas)
        _celula(
          coluna.titulo,
          _wSub * _subPorGrupo,
          fundo: PdfColors.green800,
          cor: PdfColors.white,
          negrito: true,
        ),
    ]);

    final linhaSub = pw.Row(children: [
      _celula("ATLETA", _wNome, fundo: PdfColors.green100, negrito: true),
      for (final coluna in tabela.colunas)
        for (final sub in [...coluna.rotulosSimbolos, "/", "T", "%EF", "Coef."])
          _celula(sub, _wSub, fundo: PdfColors.green100, negrito: true),
    ]);

    pw.Widget linhaDados(LinhaTabela linha, {bool destaque = false}) {
      final fundo = destaque ? PdfColors.yellow100 : PdfColors.white;
      return pw.Row(children: [
        _celula(linha.rotulo, _wNome, fundo: fundo, negrito: destaque),
        for (final coluna in tabela.colunas)
          for (final valor in _valoresColuna(coluna, linha.porColuna[coluna.titulo]!))
            _celula(valor, _wSub, fundo: fundo, negrito: destaque),
      ]);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        linhaGrupos,
        linhaSub,
        for (final linha in tabela.linhasJogadores) linhaDados(linha),
        linhaDados(tabela.linhaTotal, destaque: true),
      ],
    );
  }
}