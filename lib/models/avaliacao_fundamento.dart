import 'fundamento.dart';

/// Uma opção de avaliação (símbolo + significado) para um fundamento
/// específico — segue a sintaxe do DataVolley 4 (Skill + Evaluation
/// Symbol), conforme o manual oficial: cada fundamento tem seu próprio
/// conjunto de símbolos e efeitos táticos.
class OpcaoAvaliacao {
  final String simbolo; // #, +, -, = ou /
  final String rotulo;
  final bool ehPonto; // fecha o rally a favor de quem fez a ação
  final bool ehErro; // fecha o rally contra quem fez a ação
  final bool geraKV; // vira bola de graça/down ball pro adversário

  const OpcaoAvaliacao({
    required this.simbolo,
    required this.rotulo,
    this.ehPonto = false,
    this.ehErro = false,
    this.geraKV = false,
  });
}

class AvaliacaoFundamento {
  static List<OpcaoAvaliacao> opcoesPara(Fundamento fundamento) {
    switch (fundamento) {
      case Fundamento.saque:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Ace / ponto direto", ehPonto: true),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Positivo — quebra a recepção adversária"),
          OpcaoAvaliacao(simbolo: "-", rotulo: "Tático/conservado — facilita o KI adversário"),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro de saque (rede ou fora)", ehErro: true),
        ];
      case Fundamento.recepcao:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Perfeita — bola \"na mão\""),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Positiva, levemente deslocada"),
          OpcaoAvaliacao(simbolo: "-", rotulo: "Negativa/quebrada — limita o ataque"),
          OpcaoAvaliacao(simbolo: "/", rotulo: "Overpass — bola de graça pro adversário", geraKV: true),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro de recepção (ace sofrido)", ehErro: true),
        ];
      case Fundamento.levantamento:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Excelente — todas as opções de ataque abertas"),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Bom levantamento"),
          OpcaoAvaliacao(simbolo: "-", rotulo: "Levantamento difícil"),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro de levantamento", ehErro: true),
        ];
      case Fundamento.ataque:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Ponto direto", ehPonto: true),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Positivo — dificulta a defesa adversária"),
          OpcaoAvaliacao(simbolo: "-", rotulo: "Amortecido/defendido com facilidade"),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro (rede, antena, fora ou bloqueado)", ehErro: true),
        ];
      case Fundamento.bloqueio:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Bloqueio ponto", ehPonto: true),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Amortece — facilita a defesa de campo"),
          OpcaoAvaliacao(simbolo: "-", rotulo: "Não interfere na trajetória"),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro — invasão/toque na rede", ehErro: true),
        ];
      case Fundamento.defesa:
        return const [
          OpcaoAvaliacao(simbolo: "#", rotulo: "Excelente — permite contra-ataque rápido"),
          OpcaoAvaliacao(simbolo: "+", rotulo: "Exige contra-ataque de segurança"),
          OpcaoAvaliacao(simbolo: "/", rotulo: "Recuperada sem ataque — bola de graça", geraKV: true),
          OpcaoAvaliacao(simbolo: "=", rotulo: "Erro direto de defesa", ehErro: true),
        ];
    }
  }
}
