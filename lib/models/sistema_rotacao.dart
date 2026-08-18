import 'jogador.dart';

enum SistemaRotacao { seisPorZero, quatroPorDois, cincoPorUm }

extension SistemaRotacaoLabel on SistemaRotacao {
  String get rotulo {
    switch (this) {
      case SistemaRotacao.seisPorZero:
        return "6x0";
      case SistemaRotacao.quatroPorDois:
        return "4x2";
      case SistemaRotacao.cincoPorUm:
        return "5x1";
    }
  }

  String get descricao {
    switch (this) {
      case SistemaRotacao.seisPorZero:
        return "6 atacantes, sem levantador fixo — cada jogador levanta quando passa pela posição 3.";
      case SistemaRotacao.quatroPorDois:
        return "4 atacantes e 2 levantadores, sempre opostos na rotação — um levantador está sempre na rede.";
      case SistemaRotacao.cincoPorUm:
        return "5 atacantes e 1 levantador fixo, que joga todas as rotações.";
    }
  }

  /// Quantos titulares de cada função o sistema exige. Isso não limita
  /// quais ações o jogador pode registrar em quadra — é só o requisito
  /// de composição pra montar a escalação inicial.
  Map<PosicaoJogador, int> get requisitos {
    switch (this) {
      case SistemaRotacao.cincoPorUm:
        return {
          PosicaoJogador.levantador: 1,
          PosicaoJogador.oposto: 1,
          PosicaoJogador.central: 2,
          PosicaoJogador.ponteiro: 2,
        };
      case SistemaRotacao.quatroPorDois:
        return {
          PosicaoJogador.levantador: 2,
          PosicaoJogador.central: 2,
          PosicaoJogador.ponteiro: 2,
        };
      case SistemaRotacao.seisPorZero:
        return {}; // sem levantador fixo, sem exigência de composição
    }
  }
}