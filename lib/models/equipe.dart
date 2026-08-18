import 'jogador.dart';

/// Um elenco salvo (até 14 jogadores), reutilizável entre partidas.
class Equipe {
  final String id;
  final String nome;
  final List<Jogador> elenco;

  Equipe({
    required this.id,
    required this.nome,
    required this.elenco,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'nome': nome,
    'elenco': elenco.map((j) => j.toJson()).toList(),
  };

  factory Equipe.fromJson(Map<String, dynamic> json) => Equipe(
    id: json['id'] as String,
    nome: json['nome'] as String,
    elenco: (json['elenco'] as List<dynamic>)
        .map((j) => Jogador.fromJson(j as Map<String, dynamic>))
        .toList(),
  );
}