enum Fundamento { saque, recepcao, levantamento, ataque, bloqueio, defesa }

extension FundamentoLabel on Fundamento {
  /// Sigla oficial usada no DataVolley 4 (Skill code).
  String get sigla {
    switch (this) {
      case Fundamento.saque:
        return "S";
      case Fundamento.recepcao:
        return "R";
      case Fundamento.levantamento:
        return "E";
      case Fundamento.ataque:
        return "A";
      case Fundamento.bloqueio:
        return "B";
      case Fundamento.defesa:
        return "D";
    }
  }

  String get nomeCompleto {
    switch (this) {
      case Fundamento.saque:
        return "Saque";
      case Fundamento.recepcao:
        return "Recepção";
      case Fundamento.levantamento:
        return "Levantamento";
      case Fundamento.ataque:
        return "Ataque";
      case Fundamento.bloqueio:
        return "Bloqueio";
      case Fundamento.defesa:
        return "Defesa";
    }
  }

  static Fundamento porSigla(String sigla) {
    return Fundamento.values.firstWhere(
          (f) => f.sigla == sigla,
      orElse: () => Fundamento.ataque,
    );
  }
}