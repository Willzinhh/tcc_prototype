import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/partida_em_andamento.dart';

/// Guarda (e recupera) o progresso da partida em andamento — só um jogo
/// por vez, já que não faz sentido escalar dois times enquanto outro
/// jogo ainda está rolando. Salvo automaticamente a cada ponto, pra
/// sobreviver a fechar o app.
class PartidaEmAndamentoRepository {
  static const _chave = 'matchcore_partida_em_andamento';

  Future<void> salvar(PartidaEmAndamento estado) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, jsonEncode(estado.toJson()));
  }

  Future<PartidaEmAndamento?> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_chave);
    if (raw == null) return null;
    try {
      return PartidaEmAndamento.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Dado corrompido ou de uma versão antiga incompatível — melhor
      // descartar do que travar o app tentando continuar um jogo ilegível.
      await limpar();
      return null;
    }
  }

  Future<void> limpar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_chave);
  }
}
