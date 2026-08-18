/// Placar final de um set já encerrado.
class SetResultado {
  final int numeroSet;
  final int placarNosso;
  final int placarAdversario;

  SetResultado({
    required this.numeroSet,
    required this.placarNosso,
    required this.placarAdversario,
  });

  bool get vencemos => placarNosso > placarAdversario;

  Map<String, dynamic> toJson() => {
        'numeroSet': numeroSet,
        'placarNosso': placarNosso,
        'placarAdversario': placarAdversario,
      };

  factory SetResultado.fromJson(Map<String, dynamic> json) => SetResultado(
        numeroSet: json['numeroSet'] as int,
        placarNosso: json['placarNosso'] as int,
        placarAdversario: json['placarAdversario'] as int,
      );
}
