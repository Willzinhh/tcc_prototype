enum PosicaoJogador { levantador, oposto, central, ponteiro, libero }

extension PosicaoJogadorLabel on PosicaoJogador {
  String get sigla {
    switch (this) {
      case PosicaoJogador.levantador:
        return "L";
      case PosicaoJogador.oposto:
        return "O";
      case PosicaoJogador.central:
        return "C";
      case PosicaoJogador.ponteiro:
        return "P";
      case PosicaoJogador.libero:
        return "LIB";
    }
  }

  String get nomeCompleto {
    switch (this) {
      case PosicaoJogador.levantador:
        return "Levantador";
      case PosicaoJogador.oposto:
        return "Oposto";
      case PosicaoJogador.central:
        return "Central";
      case PosicaoJogador.ponteiro:
        return "Ponteiro";
      case PosicaoJogador.libero:
        return "Líbero";
    }
  }
}

class Jogador {
  final String id;
  final String nome;
  final int numero;
  final PosicaoJogador posicao;

  Jogador({
    required this.id,
    required this.nome,
    required this.numero,
    required this.posicao,
  });

  /// Usado nos botões pequenos do menu radial (espaço é curto).
  String get rotuloCurto => numero.toString();

  /// Usado em listas, diálogos de substituição e no log de jogadas.
  String get rotuloCompleto => "$numero $nome";

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'numero': numero,
    'posicao': posicao.name,
  };

  factory Jogador.fromJson(Map<String, dynamic> json) => Jogador(
    id: json['id'] as String,
    nome: json['nome'] as String,
    numero: json['numero'] as int,
    posicao: PosicaoJogador.values.firstWhere(
          (p) => p.name == json['posicao'],
      orElse: () => PosicaoJogador.ponteiro,
    ),
  );
}