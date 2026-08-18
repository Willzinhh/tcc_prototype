import '../core/utils/estatisticas_calculator.dart';
import '../models/partida.dart';

/// Uma coluna da tabela (ex: "SAQUE", "ATAQUE SIDE OUT") — define quais
/// jogadas entram nela através de [filtro].
class ColunaEstatistica {
  final String titulo;
  final bool Function(Jogada) filtro;

  /// Pesos [excelente, positivo, negativoComErro, transicao] pra
  /// calcular o "%EF" ponderado, igual à planilha de referência. Null
  /// quando essa coluna não tem fórmula ponderada lá (nesse caso usamos
  /// a eficiência simples como alternativa).
  final List<double>? pesos;

  /// Rótulos mostrados nas 3 primeiras subcolunas de símbolo — a
  /// planilha usa "#/+/-" pra a maioria dos fundamentos, mas "A/B/C"
  /// pra Recepção e Defesa.
  final List<String> rotulosSimbolos;

  const ColunaEstatistica(
      this.titulo,
      this.filtro, {
        this.pesos,
        this.rotulosSimbolos = const ["#", "+", "-"],
      });
}

/// As 7 colunas usadas na planilha de referência, com os mesmos pesos
/// de "%EF" (extraídos das fórmulas da planilha). "Ataque" é separado
/// por complexo (side-out no KI, ou transição no KII/KIII) porque tem
/// significado tático diferente, mesmo sendo o mesmo fundamento (A).
/// Bloqueio e Defesa não tinham fórmula de %EF preenchida na planilha
/// de referência — pra esses dois, a tabela cai pra eficiência simples.
final List<ColunaEstatistica> colunasPadraoTabela = [
  ColunaEstatistica("SAQUE", (j) => j.fundamento == "S", pesos: [10, 7, 4, 0]),
  ColunaEstatistica(
    "RECEPÇÃO",
        (j) => j.fundamento == "R",
    pesos: [10, 7, 3, -1],
    rotulosSimbolos: const ["A", "B", "C"],
  ),
  ColunaEstatistica(
    "ATAQUE SIDE OUT",
        (j) => j.fundamento == "A" && j.complexo == "KI",
    pesos: [10, 5, 3, 0],
  ),
  ColunaEstatistica("BLOQUEIO", (j) => j.fundamento == "B"),
  ColunaEstatistica(
    "DEFESA",
        (j) => j.fundamento == "D",
    rotulosSimbolos: const ["A", "B", "C"],
  ),
  ColunaEstatistica(
    "ATAQUE KII E KIII",
        (j) => j.fundamento == "A" && (j.complexo == "KII" || j.complexo == "KIII"),
    pesos: [10, 5, 3, 0],
  ),
  ColunaEstatistica("BOLA DE GRAÇA", (j) => j.complexo == "KV", pesos: [10, 5, 3, 0]),
];

/// Uma linha da tabela: um jogador (ou o TOTAL da equipe) com suas
/// estatísticas em cada coluna.
class LinhaTabela {
  final String rotulo; // nome do jogador, ou "TOTAL"
  final Map<String, EstatisticasFundamento> porColuna;

  LinhaTabela({required this.rotulo, required this.porColuna});
}

class TabelaEstatisticas {
  final int? numeroSet; // null = todos os sets somados
  final List<ColunaEstatistica> colunas;
  final List<LinhaTabela> linhasJogadores;
  final LinhaTabela linhaTotal;

  TabelaEstatisticas({
    required this.numeroSet,
    required this.colunas,
    required this.linhasJogadores,
    required this.linhaTotal,
  });

  static TabelaEstatisticas montar(
      List<Jogada> todasAsJogadas, {
        int? numeroSet,
        // null = ambos os times juntos; true = só nosso; false = só adversário.
        bool? nosso = true,
      }) {
    Iterable<Jogada> jogadas = numeroSet == null
        ? todasAsJogadas
        : todasAsJogadas.where((j) => j.numeroSet == numeroSet);
    if (nosso != null) {
      jogadas = jogadas.where((j) => (j.jogadorEhNosso ?? true) == nosso);
    }
    jogadas = jogadas.toList();

    final jogadoresComAcao = jogadas
        .where((j) => j.jogador != null && j.tipo != "SUBSTITUICAO")
        .map((j) => j.jogador!)
        .toSet()
        .toList()
      ..sort();

    final Map<String, Map<String, EstatisticasFundamento>> porJogadorEColuna = {
      for (final jogador in jogadoresComAcao)
        jogador: {for (final coluna in colunasPadraoTabela) coluna.titulo: EstatisticasFundamento()},
    };
    final Map<String, EstatisticasFundamento> totalPorColuna = {
      for (final coluna in colunasPadraoTabela) coluna.titulo: EstatisticasFundamento(),
    };

    for (final jogada in jogadas) {
      if (jogada.jogador == null || jogada.tipo == "SUBSTITUICAO") continue;
      for (final coluna in colunasPadraoTabela) {
        if (coluna.filtro(jogada)) {
          porJogadorEColuna[jogada.jogador]![coluna.titulo]!.registrar(jogada.simbolo);
          totalPorColuna[coluna.titulo]!.registrar(jogada.simbolo);
        }
      }
    }

    final linhas = jogadoresComAcao
        .map((jogador) => LinhaTabela(rotulo: jogador, porColuna: porJogadorEColuna[jogador]!))
        .toList();

    return TabelaEstatisticas(
      numeroSet: numeroSet,
      colunas: colunasPadraoTabela,
      linhasJogadores: linhas,
      linhaTotal: LinhaTabela(rotulo: "TOTAL", porColuna: totalPorColuna),
    );
  }
}