import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/equipe.dart';

/// Persiste elencos (equipes com até 14 jogadores) localmente, para
/// reutilizar entre partidas.
class EquipeRepository {
  static const _chave = 'matchcore_equipes';

  Future<List<Equipe>> listar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    return raw
        .map((s) => Equipe.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> salvar(Equipe equipe) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    raw.removeWhere(
          (s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == equipe.id,
    );
    raw.add(jsonEncode(equipe.toJson()));
    await prefs.setStringList(_chave, raw);
  }

  Future<void> excluir(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_chave) ?? [];
    raw.removeWhere((s) => (jsonDecode(s) as Map<String, dynamic>)['id'] == id);
    await prefs.setStringList(_chave, raw);
  }
}