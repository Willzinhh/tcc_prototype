import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/partida.dart';

/// Persiste o histórico de partidas localmente (shared_preferences),
/// como uma lista de JSONs serializados.
class PartidaRepository {
  static const _chave = 'matchcore_partidas';

  Future<List<Partida>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    final partidas = raw
        .map((s) => Partida.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
    partidas.sort((a, b) => b.data.compareTo(a.data)); // mais recente primeiro
    return partidas;
  }

  Future<void> salvar(Partida partida) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    raw.add(jsonEncode(partida.toJson()));
    await prefs.setStringList(_chave, raw);
  }

  Future<void> excluir(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    raw.removeWhere((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return json['id'] == id;
    });
    await prefs.setStringList(_chave, raw);
  }
}
