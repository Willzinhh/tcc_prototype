import '../../models/partida.dart';

/// Estatísticas agregadas de um jogador ao longo de várias partidas.
class EstatisticasJogador {
  int pontos = 0;
  int erros = 0;
  int positivas = 0;
  int negativas = 0;
  int neutras = 0;

  int get totalAcoes => pontos + erros + positivas + negativas + neutras;
}

/// Contagem de símbolos de avaliação (#, +, -, =, /) pra UM fundamento
/// (S/R/E/A/B/D), com a eficiência calculada no padrão DataVolley:
/// (excelente - erro) / total.
class EstatisticasFundamento {
  int excelente = 0; // #
  int positivo = 0; // +
  int negativo = 0; // -
  int erro = 0; // =
  int transicao = 0; // / (overpass / bola sem ataque)

  int get total => excelente + positivo + negativo + erro + transicao;

  /// Negativo e erro juntos numa coluna só — é assim que a planilha de
  /// referência mostra (ela não separa "regular" de "erro", tudo que não
  /// é # ou + cai nessa coluna).
  int get negativoComErro => negativo + erro;

  /// Eficiência clássica do DataVolley: (excelente - erro) / total, em %.
  /// Pode ser negativa se houver mais erros do que ações excelentes.
  double get eficiencia => total == 0 ? 0 : ((excelente - erro) / total) * 100;

  /// Eficiência ponderada, igual à fórmula da planilha de referência:
  /// (excelente*pesos[0] + positivo*pesos[1] + negativoComErro*pesos[2]
  ///  + transicao*pesos[3]) / (total*pesos[0]), em %. Retorna null
  /// quando não há ações (a planilha mostra "-" nesse caso).
  double? eficienciaPonderada(List<double> pesos) {
    if (total == 0) return null;
    final soma = excelente * pesos[0] +
        positivo * pesos[1] +
        negativoComErro * pesos[2] +
        transicao * pesos[3];
    return (soma / (total * pesos[0])) * 100;
  }

  /// "Coef." da planilha de referência: total de ações dividido pelo
  /// número de ações excelentes (quanto mais perto de 1, mais
  /// consistente). Null quando não há nenhuma ação excelente (a
  /// planilha mostra "-" nesse caso, já que seria divisão por zero).
  double? get coeficiente => excelente == 0 ? null : total / excelente;

  /// % de ações excelentes ou positivas (# ou +).
  double get percentualPositivo => total == 0 ? 0 : ((excelente + positivo) / total) * 100;

  void registrar(String simbolo) {
    switch (simbolo) {
      case "#":
        excelente++;
        break;
      case "+":
        positivo++;
        break;
      case "-":
        negativo++;
        break;
      case "=":
        erro++;
        break;
      case "/":
        transicao++;
        break;
    }
  }
}

/// Estatísticas agregadas de todas as partidas salvas: resultado geral,
/// desempenho por jogador (separado por time), zonas mais frequentes de
/// ponto/erro, aproveitamento por Complexo de Jogo (K0 a KV) e
/// eficiência por fundamento técnico — do NOSSO time (geral e por
/// jogador), já que é sobre isso que um relatório técnico faz sentido.
class EstatisticasGerais {
  final int totalPartidas;
  final int vitorias;
  final int derrotas;
  final int empates;
  final int totalPontosNossos;
  final int totalPontosAdversario;

  /// Ranking de jogadores, separado por time — evita misturar os
  /// jogadores do adversário com os nossos numa lista só.
  final Map<String, EstatisticasJogador> porJogadorNosso;
  final Map<String, EstatisticasJogador> porJogadorAdversario;

  final Map<String, int> pontosPorZona;
  final Map<String, int> errosPorZona;
  final Map<String, EstatisticasJogador> porComplexo;

  /// Fundamento (sigla S/R/E/A/B/D) -> estatísticas do NOSSO time nesse
  /// fundamento (ações do adversário não entram aqui, senão o relatório
  /// técnico ficaria misturado com o desempenho deles).
  final Map<String, EstatisticasFundamento> porFundamento;

  /// Jogador (nosso) -> fundamento -> estatísticas daquele jogador só
  /// nesse fundamento (pra ver, por exemplo, a eficiência de recepção de
  /// um jogador específico).
  final Map<String, Map<String, EstatisticasFundamento>> porJogadorEFundamento;

  EstatisticasGerais({
    required this.totalPartidas,
    required this.vitorias,
    required this.derrotas,
    required this.empates,
    required this.totalPontosNossos,
    required this.totalPontosAdversario,
    required this.porJogadorNosso,
    required this.porJogadorAdversario,
    required this.pontosPorZona,
    required this.errosPorZona,
    required this.porComplexo,
    required this.porFundamento,
    required this.porJogadorEFundamento,
  });

  factory EstatisticasGerais.calcular(List<Partida> partidas) {
    int vitorias = 0;
    int derrotas = 0;
    int empates = 0;
    int totalNossos = 0;
    int totalAdversario = 0;

    final Map<String, EstatisticasJogador> porJogadorNosso = {};
    final Map<String, EstatisticasJogador> porJogadorAdversario = {};
    final Map<String, int> pontosPorZona = {};
    final Map<String, int> errosPorZona = {};
    final Map<String, EstatisticasJogador> porComplexo = {};
    final Map<String, EstatisticasFundamento> porFundamento = {};
    final Map<String, Map<String, EstatisticasFundamento>> porJogadorEFundamento = {};

    for (final partida in partidas) {
      totalNossos += partida.sets.fold<int>(0, (soma, s) => soma + s.placarNosso);
      totalAdversario += partida.sets.fold<int>(0, (soma, s) => soma + s.placarAdversario);

      if (partida.setsVencidosNos > partida.setsVencidosAdversario) {
        vitorias++;
      } else if (partida.setsVencidosNos < partida.setsVencidosAdversario) {
        derrotas++;
      } else {
        empates++;
      }

      for (final jogada in partida.jogadas) {
        if (jogada.jogador != null) {
          // jogadorEhNosso pode ser null em dados antigos (salvos antes
          // desse campo existir) — nesse caso, assume nosso por padrão
          // pra não sumir com o histórico já registrado.
          final bool ehNosso = jogada.jogadorEhNosso ?? true;
          final Map<String, EstatisticasJogador> mapaDoTime =
          ehNosso ? porJogadorNosso : porJogadorAdversario;

          final stats = mapaDoTime.putIfAbsent(
            jogada.jogador!,
                () => EstatisticasJogador(),
          );
          switch (jogada.tipo) {
            case "PONTO":
              stats.pontos++;
              break;
            case "ERRO":
              stats.erros++;
              break;
            case "POSITIVA":
              stats.positivas++;
              break;
            case "NEGATIVA":
              stats.negativas++;
              break;
            case "NEUTRA":
              stats.neutras++;
              break;
          }
        }

        if (jogada.tipo == "PONTO") {
          pontosPorZona[jogada.zona] = (pontosPorZona[jogada.zona] ?? 0) + 1;
        } else if (jogada.tipo == "ERRO") {
          errosPorZona[jogada.zona] = (errosPorZona[jogada.zona] ?? 0) + 1;
        }

        if (jogada.tipo == "PONTO" || jogada.tipo == "ERRO") {
          final complexoStats = porComplexo.putIfAbsent(
            jogada.complexo,
                () => EstatisticasJogador(),
          );
          if (jogada.tipo == "PONTO") {
            complexoStats.pontos++;
          } else {
            complexoStats.erros++;
          }
        }

        // Eficiência por fundamento: só do NOSSO time, e ignora
        // substituições (não têm um fundamento técnico de verdade).
        final bool ehNossoOuDesconhecido = jogada.jogadorEhNosso ?? true;
        if (jogada.tipo != "SUBSTITUICAO" && ehNossoOuDesconhecido) {
          porFundamento
              .putIfAbsent(jogada.fundamento, () => EstatisticasFundamento())
              .registrar(jogada.simbolo);

          if (jogada.jogador != null) {
            final mapaDoJogador = porJogadorEFundamento.putIfAbsent(jogada.jogador!, () => {});
            mapaDoJogador
                .putIfAbsent(jogada.fundamento, () => EstatisticasFundamento())
                .registrar(jogada.simbolo);
          }
        }
      }
    }

    return EstatisticasGerais(
      totalPartidas: partidas.length,
      vitorias: vitorias,
      derrotas: derrotas,
      empates: empates,
      totalPontosNossos: totalNossos,
      totalPontosAdversario: totalAdversario,
      porJogadorNosso: porJogadorNosso,
      porJogadorAdversario: porJogadorAdversario,
      pontosPorZona: pontosPorZona,
      errosPorZona: errosPorZona,
      porComplexo: porComplexo,
      porFundamento: porFundamento,
      porJogadorEFundamento: porJogadorEFundamento,
    );
  }
}