import 'set_resultado.dart';

/// Uma jogada individual registrada durante a partida (ponto, erro ou
/// avaliação de qualidade), usada tanto no log em tela quanto em futuras
/// telas de estatística.
class Jogada {
  final String? jogador;
  final String tipo; // PONTO, ERRO, POSITIVA, NEGATIVA, NEUTRA ou SUBSTITUICAO
  final String zona;
  final DateTime horario;

  /// Complexo de jogo (K0 a KV), conforme Laporta et al. (2023):
  /// K0=saque, KI=recepção/ataque, KII=defesa/contra-ataque,
  /// KIII=transição prolongada, KIV=cobertura de ataque,
  /// KV=bola de graça/down ball.
  final String complexo;

  /// Fundamento técnico (S/R/E/A/B/D) e símbolo de avaliação (#, +, -, =
  /// ou /), na sintaxe do DataVolley 4 — ex: "R" + "+" = recepção
  /// positiva. Ver models/fundamento.dart e models/avaliacao_fundamento.dart.
  final String fundamento;
  final String simbolo;

  /// Em qual set da partida essa jogada aconteceu (1, 2, 3...) — usado
  /// pra montar tabelas de estatística separadas por set.
  final int numeroSet;

  /// De qual time é o [jogador] — true = nossa equipe, false = time
  /// adversário, null quando não há um jogador específico (ação rápida,
  /// erro automático). Usado pra separar as estatísticas por time.
  final bool? jogadorEhNosso;

  Jogada({
    this.jogador,
    required this.tipo,
    required this.zona,
    required this.horario,
    this.complexo = "KI",
    this.fundamento = "A",
    this.simbolo = "-",
    this.numeroSet = 1,
    this.jogadorEhNosso,
  });

  /// Código no padrão DataVolley, ex: "R+", "A#", "S=".
  String get codigo => "$fundamento$simbolo";

  Map<String, dynamic> toJson() => {
    'jogador': jogador,
    'tipo': tipo,
    'zona': zona,
    'horario': horario.toIso8601String(),
    'complexo': complexo,
    'fundamento': fundamento,
    'simbolo': simbolo,
    'numeroSet': numeroSet,
    'jogadorEhNosso': jogadorEhNosso,
  };

  factory Jogada.fromJson(Map<String, dynamic> json) => Jogada(
    jogador: json['jogador'] as String?,
    tipo: json['tipo'] as String,
    zona: json['zona'] as String,
    horario: DateTime.parse(json['horario'] as String),
    complexo: json['complexo'] as String? ?? "KI",
    fundamento: json['fundamento'] as String? ?? "A",
    simbolo: json['simbolo'] as String? ?? "-",
    numeroSet: json['numeroSet'] as int? ?? 1,
    jogadorEhNosso: json['jogadorEhNosso'] as bool?,
  );
}

/// Uma partida completa (melhor de 3 a 5 sets), com o placar de sets
/// vencidos, o placar de cada set individual e a lista de jogadas
/// registradas ao longo do jogo inteiro.
class Partida {
  final String id;
  final DateTime data;
  final String nomeEquipe;
  final String nomeAdversario;
  final int setsVencidosNos;
  final int setsVencidosAdversario;
  final List<SetResultado> sets;
  final List<Jogada> jogadas;

  Partida({
    required this.id,
    required this.data,
    required this.nomeEquipe,
    this.nomeAdversario = "Adversário",
    required this.setsVencidosNos,
    required this.setsVencidosAdversario,
    required this.sets,
    required this.jogadas,
  });

  bool get vencemosPartida => setsVencidosNos > setsVencidosAdversario;

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toIso8601String(),
    'nomeEquipe': nomeEquipe,
    'nomeAdversario': nomeAdversario,
    'setsVencidosNos': setsVencidosNos,
    'setsVencidosAdversario': setsVencidosAdversario,
    'sets': sets.map((s) => s.toJson()).toList(),
    'jogadas': jogadas.map((j) => j.toJson()).toList(),
  };

  factory Partida.fromJson(Map<String, dynamic> json) => Partida(
    id: json['id'] as String,
    data: DateTime.parse(json['data'] as String),
    nomeEquipe: json['nomeEquipe'] as String,
    nomeAdversario: json['nomeAdversario'] as String? ?? "Adversário",
    setsVencidosNos: json['setsVencidosNos'] as int,
    setsVencidosAdversario: json['setsVencidosAdversario'] as int,
    sets: (json['sets'] as List<dynamic>)
        .map((s) => SetResultado.fromJson(s as Map<String, dynamic>))
        .toList(),
    jogadas: (json['jogadas'] as List<dynamic>)
        .map((j) => Jogada.fromJson(j as Map<String, dynamic>))
        .toList(),
  );
}