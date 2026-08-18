import 'jogador.dart';
import 'partida.dart';
import 'set_resultado.dart';
import 'sistema_rotacao.dart';

/// Uma "foto" completa do estado de um jogo em andamento — guardada
/// automaticamente a cada ponto, pra dar pra fechar o app e continuar
/// depois de onde parou. Diferente de [Partida], que só existe quando o
/// jogo já terminou (ou foi encerrado manualmente) e vai pro histórico.
class PartidaEmAndamento {
  final String nomeNossaEquipe;
  final List<Jogador> bancoInicialNosso; // elenco completo (banco + quadra), pra reconstruir
  final SistemaRotacao sistemaNosso;
  final Jogador? liberoNosso;

  final String nomeAdversario;
  final List<Jogador> bancoInicialAdversario;
  final SistemaRotacao sistemaAdversario;
  final Jogador? liberoAdversario;

  // Estado atual do jogo — exatamente o que precisa pra retomar de onde
  // parou, sem repetir o saque inicial nem perder a rotação.
  final int placarNossaEquipe;
  final int placarAdversario;
  final String ladoComPosse;
  final int numeroSetAtual;
  final int setsVencidosNos;
  final int setsVencidosAdversario;
  final List<SetResultado> setsFinalizados;
  final List<Jogada> jogadas;
  final List<Jogador> posicoesNossoTimeAtual;
  final List<Jogador> posicoesAdversarioAtual;
  final List<Jogador> bancoNossoAtual;
  final List<Jogador> bancoAdversarioAtual;
  final DateTime salvoEm;

  PartidaEmAndamento({
    required this.nomeNossaEquipe,
    required this.bancoInicialNosso,
    required this.sistemaNosso,
    this.liberoNosso,
    required this.nomeAdversario,
    required this.bancoInicialAdversario,
    required this.sistemaAdversario,
    this.liberoAdversario,
    required this.placarNossaEquipe,
    required this.placarAdversario,
    required this.ladoComPosse,
    required this.numeroSetAtual,
    required this.setsVencidosNos,
    required this.setsVencidosAdversario,
    required this.setsFinalizados,
    required this.jogadas,
    required this.posicoesNossoTimeAtual,
    required this.posicoesAdversarioAtual,
    required this.bancoNossoAtual,
    required this.bancoAdversarioAtual,
    required this.salvoEm,
  });

  Map<String, dynamic> toJson() => {
        'nomeNossaEquipe': nomeNossaEquipe,
        'bancoInicialNosso': bancoInicialNosso.map((j) => j.toJson()).toList(),
        'sistemaNosso': sistemaNosso.name,
        'liberoNosso': liberoNosso?.toJson(),
        'nomeAdversario': nomeAdversario,
        'bancoInicialAdversario': bancoInicialAdversario.map((j) => j.toJson()).toList(),
        'sistemaAdversario': sistemaAdversario.name,
        'liberoAdversario': liberoAdversario?.toJson(),
        'placarNossaEquipe': placarNossaEquipe,
        'placarAdversario': placarAdversario,
        'ladoComPosse': ladoComPosse,
        'numeroSetAtual': numeroSetAtual,
        'setsVencidosNos': setsVencidosNos,
        'setsVencidosAdversario': setsVencidosAdversario,
        'setsFinalizados': setsFinalizados.map((s) => s.toJson()).toList(),
        'jogadas': jogadas.map((j) => j.toJson()).toList(),
        'posicoesNossoTimeAtual': posicoesNossoTimeAtual.map((j) => j.toJson()).toList(),
        'posicoesAdversarioAtual': posicoesAdversarioAtual.map((j) => j.toJson()).toList(),
        'bancoNossoAtual': bancoNossoAtual.map((j) => j.toJson()).toList(),
        'bancoAdversarioAtual': bancoAdversarioAtual.map((j) => j.toJson()).toList(),
        'salvoEm': salvoEm.toIso8601String(),
      };

  static List<Jogador> _listaJogadores(dynamic json) => (json as List<dynamic>)
      .map((j) => Jogador.fromJson(j as Map<String, dynamic>))
      .toList();

  factory PartidaEmAndamento.fromJson(Map<String, dynamic> json) => PartidaEmAndamento(
        nomeNossaEquipe: json['nomeNossaEquipe'] as String,
        bancoInicialNosso: _listaJogadores(json['bancoInicialNosso']),
        sistemaNosso: SistemaRotacao.values.firstWhere(
          (s) => s.name == json['sistemaNosso'],
          orElse: () => SistemaRotacao.cincoPorUm,
        ),
        liberoNosso: json['liberoNosso'] == null
            ? null
            : Jogador.fromJson(json['liberoNosso'] as Map<String, dynamic>),
        nomeAdversario: json['nomeAdversario'] as String,
        bancoInicialAdversario: _listaJogadores(json['bancoInicialAdversario']),
        sistemaAdversario: SistemaRotacao.values.firstWhere(
          (s) => s.name == json['sistemaAdversario'],
          orElse: () => SistemaRotacao.cincoPorUm,
        ),
        liberoAdversario: json['liberoAdversario'] == null
            ? null
            : Jogador.fromJson(json['liberoAdversario'] as Map<String, dynamic>),
        placarNossaEquipe: json['placarNossaEquipe'] as int,
        placarAdversario: json['placarAdversario'] as int,
        ladoComPosse: json['ladoComPosse'] as String,
        numeroSetAtual: json['numeroSetAtual'] as int,
        setsVencidosNos: json['setsVencidosNos'] as int,
        setsVencidosAdversario: json['setsVencidosAdversario'] as int,
        setsFinalizados: (json['setsFinalizados'] as List<dynamic>)
            .map((s) => SetResultado.fromJson(s as Map<String, dynamic>))
            .toList(),
        jogadas: (json['jogadas'] as List<dynamic>)
            .map((j) => Jogada.fromJson(j as Map<String, dynamic>))
            .toList(),
        posicoesNossoTimeAtual: _listaJogadores(json['posicoesNossoTimeAtual']),
        posicoesAdversarioAtual: _listaJogadores(json['posicoesAdversarioAtual']),
        bancoNossoAtual: _listaJogadores(json['bancoNossoAtual']),
        bancoAdversarioAtual: _listaJogadores(json['bancoAdversarioAtual']),
        salvoEm: DateTime.parse(json['salvoEm'] as String),
      );
}
