class VoleiUtils {
  /// Identifica a zona de vôlei (1-9) a partir de uma posição (x, y)
  /// relativa ao canto superior esquerdo da quadra.
  /// Retorna um texto amigável, ex: "Zona 5 (Fundo Esq)".
  static String identificarZona(double x, double y, double qLargura, double qAltura) {
    bool ladoSuperior = y < (qAltura / 2);
    int col = (x / (qLargura / 3)).floor() + 1;
    col = col.clamp(1, 3);

    double yRelativo = ladoSuperior ? y : (y - qAltura / 2);
    int profundidade = (yRelativo / ((qAltura / 2) / 3)).floor() + 1;
    profundidade = profundidade.clamp(1, 3);

    if (!ladoSuperior) profundidade = 4 - profundidade;

    if (!ladoSuperior) {
      if (profundidade == 1) {
        if (col == 1) return "Zona 5 (Fundo Esq)";
        if (col == 2) return "Zona 6 (Fundo Meio)";
        return "Zona 1 (Fundo Dir/Saque)";
      } else if (profundidade == 2) {
        if (col == 1) return "Zona 7 (Meio Esq)";
        if (col == 2) return "Zona 8 (Meio Meio)";
        return "Zona 9 (Meio Dir)";
      } else {
        if (col == 1) return "Zona 4 (Entrada)";
        if (col == 2) return "Zona 3 (Meio)";
        return "Zona 2 (Saída)";
      }
    } else {
      if (profundidade == 1) {
        if (col == 1) return "Zona 1 (Fundo Dir/Saque)";
        if (col == 2) return "Zona 6 (Fundo Meio)";
        return "Zona 5 (Fundo Esq)";
      } else if (profundidade == 2) {
        if (col == 1) return "Zona 9 (Meio Dir)";
        if (col == 2) return "Zona 8 (Meio Meio)";
        return "Zona 7 (Meio Esq)";
      } else {
        if (col == 1) return "Zona 2 (Saída)";
        if (col == 2) return "Zona 3 (Meio)";
        return "Zona 4 (Entrada)";
      }
    }
  }
}