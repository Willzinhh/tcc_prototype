import '../../models/jogador.dart';
import '../../models/sistema_rotacao.dart';

/// Organiza os 6 titulares na ordem de rotação (posições 1 a 6) correta
/// pro sistema ofensivo escolhido, garantindo o espaçamento certo entre
/// levantador(es) e as demais funções — a mesma lógica usada em times de
/// verdade: no 5x1 o levantador e o oposto ficam sempre "de frente" um
/// pro outro na rotação (3 posições de distância); no 4x2 os dois
/// levantadores ficam nessa mesma distância entre si.
///
/// Como a escalação já gira ciclicamente a cada saque recuperado, uma
/// vez organizada certinho aqui, o levantador (ou os dois, no 4x2)
/// sempre vai passar pelas 6 posições na ordem certa, rotação após
/// rotação — sem precisar reorganizar nada durante o jogo.
class FormacaoTitular {
  /// Tenta montar a formação padrão. Retorna null se o elenco escolhido
  /// não bate com o que o sistema exige (ex: 5x1 precisa de exatamente
  /// 1 levantador, 2 centrais, 2 ponteiros e 1 oposto) — nesse caso,
  /// quem chama deve usar uma ordem manual como alternativa.
  static List<Jogador>? organizar(List<Jogador> titulares, SistemaRotacao sistema) {
    if (titulares.length != 6) return null;

    switch (sistema) {
      case SistemaRotacao.cincoPorUm:
        return _organizarCincoPorUm(titulares);
      case SistemaRotacao.quatroPorDois:
        return _organizarQuatroPorDois(titulares);
      case SistemaRotacao.seisPorZero:
      // Sem levantador fixo — não há um padrão único de posicionamento
      // a impor; mantém como o técnico organizou manualmente.
        return null;
    }
  }

  static List<Jogador> _porPosicao(List<Jogador> titulares, PosicaoJogador posicao) {
    return titulares.where((j) => j.posicao == posicao).toList();
  }

  static List<Jogador>? _organizarCincoPorUm(List<Jogador> titulares) {
    final levantadores = _porPosicao(titulares, PosicaoJogador.levantador);
    final centrais = _porPosicao(titulares, PosicaoJogador.central);
    final ponteiros = _porPosicao(titulares, PosicaoJogador.ponteiro);
    final opostos = _porPosicao(titulares, PosicaoJogador.oposto);

    if (levantadores.length != 1 ||
        centrais.length != 2 ||
        ponteiros.length != 2 ||
        opostos.length != 1) {
      return null;
    }

    // Ordem de rotação do 5x1, conferida contra o rodízio de referência
    // (posições 1, 2 e 3 batem certinho quando giradas ciclicamente a
    // partir daqui): Levantador, Ponteiro, Central, Oposto (sempre 3
    // posições — "de frente" — do levantador), Ponteiro, Central.
    return [
      levantadores[0],
      ponteiros[0],
      centrais[0],
      opostos[0],
      ponteiros[1],
      centrais[1],
    ];
  }

  static List<Jogador>? _organizarQuatroPorDois(List<Jogador> titulares) {
    final levantadores = _porPosicao(titulares, PosicaoJogador.levantador);
    final centrais = _porPosicao(titulares, PosicaoJogador.central);
    final ponteiros = _porPosicao(titulares, PosicaoJogador.ponteiro);

    if (levantadores.length != 2 || centrais.length != 2 || ponteiros.length != 2) {
      return null;
    }

    // Os dois levantadores sempre a 3 posições de distância um do outro,
    // pra que um deles esteja sempre na rede.
    return [
      levantadores[0],
      centrais[0],
      ponteiros[0],
      levantadores[1],
      centrais[1],
      ponteiros[1],
    ];
  }

  /// Gira a formação [deslocamento] posições, pra deixar o técnico
  /// escolher em qual das 6 rotações válidas o set começa (ex: preferir
  /// começar com o levantador na rede em vez de sacando).
  static List<Jogador> girar(List<Jogador> formacao, int deslocamento) {
    if (formacao.isEmpty) return formacao;
    final int n = formacao.length;
    final int d = ((deslocamento % n) + n) % n;
    return [...formacao.sublist(d), ...formacao.sublist(0, d)];
  }
}