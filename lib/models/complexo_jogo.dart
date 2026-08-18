/// Complexos de Jogo do voleibol (Laporta et al., 2023): representam o
/// fluxo lógico e interdependente das ações dentro de um rally.
class ComplexoJogo {
  static const String k0 = "K0";
  static const String kI = "KI";
  static const String kII = "KII";
  static const String kIII = "KIII";
  static const String kIV = "KIV";
  static const String kV = "KV";

  /// Nome curto do complexo + as ações típicas dele, para mostrar no log
  /// de jogadas (ex: "[KI] Recepção/Levantamento/Ataque").
  static String rotulo(String complexo) {
    switch (complexo) {
      case k0:
        return "K0 · Saque";
      case kI:
        return "KI · Recepção/Levantamento/Ataque";
      case kII:
        return "KII · Bloqueio/Defesa/Contra-ataque";
      case kIII:
        return "KIII · Transição prolongada";
      case kIV:
        return "KIV · Cobertura de ataque";
      case kV:
        return "KV · Bola de graça/Down ball";
      default:
        return complexo;
    }
  }

  /// Só a sigla, pra usar em espaços curtos (chip, badge).
  static String sigla(String complexo) => complexo;
}
