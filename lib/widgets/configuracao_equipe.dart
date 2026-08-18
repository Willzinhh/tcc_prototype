import 'package:flutter/material.dart';

import '../core/utils/formacao_titular.dart';
import '../models/jogador.dart';
import '../models/sistema_rotacao.dart';
import '../screens/elenco_screen.dart';
import '../screens/escalacao_visual_screen.dart';

/// Dados de configuração de uma equipe (nossa ou adversária) prontos
/// para iniciar uma partida.
class ConfiguracaoEquipeDados {
  final String nome;
  final List<Jogador> elenco;
  final List<Jogador> titulares; // ordem = posições 1 a 6
  final SistemaRotacao sistema;
  final Jogador? libero;

  ConfiguracaoEquipeDados({
    required this.nome,
    required this.elenco,
    required this.titulares,
    required this.sistema,
    this.libero,
  });

  bool get pronta => titulares.length == 6;

  List<Jogador> get banco => elenco
      .where((j) => !titulares.any((t) => t.id == j.id))
      .where((j) => libero == null || j.id != libero!.id)
      .toList();
}

/// Componente reutilizável: gerencia o elenco (até 14), o sistema de
/// rotação, o líbero (opcional) e a escalação dos 6 titulares de UMA
/// equipe — usado duas vezes no Dashboard (nossa equipe / adversário).
///
/// A escalação em si é montada na tela visual (arrastar jogadores pra
/// quadra — ver screens/escalacao_visual_screen.dart), que já valida em
/// tempo real se a composição bate com o que o sistema escolhido exige
/// (ex: 5x1 precisa de 1 levantador, 1 oposto, 2 centrais e 2 ponteiros).
class ConfiguracaoEquipe extends StatefulWidget {
  final String nomeInicial;
  final ValueChanged<ConfiguracaoEquipeDados> onMudou;

  const ConfiguracaoEquipe({
    super.key,
    required this.nomeInicial,
    required this.onMudou,
  });

  @override
  State<ConfiguracaoEquipe> createState() => _ConfiguracaoEquipeState();
}

class _ConfiguracaoEquipeState extends State<ConfiguracaoEquipe> {
  late final TextEditingController _nomeController;
  List<Jogador> _elenco = [];
  List<Jogador?> _posicoes = List<Jogador?>.filled(6, null);
  Jogador? _libero;
  SistemaRotacao _sistemaSelecionado = SistemaRotacao.cincoPorUm;

  @override
  void initState() {
    super.initState();
    _nomeController = TextEditingController(text: widget.nomeInicial);
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  List<Jogador> get _titulares => _posicoes.whereType<Jogador>().toList();

  void _notificar() {
    widget.onMudou(ConfiguracaoEquipeDados(
      nome: _nomeController.text.trim().isEmpty ? widget.nomeInicial : _nomeController.text.trim(),
      elenco: _elenco,
      titulares: _titulares,
      sistema: _sistemaSelecionado,
      libero: _libero,
    ));
  }

  Future<void> _abrirElenco() async {
    final resultado = await Navigator.push<(String, List<Jogador>)>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaElenco(
          nomeInicial: _nomeController.text,
          elencoInicial: _elenco,
        ),
      ),
    );
    if (resultado == null) return;

    final (nome, elencoAtualizado) = resultado;
    setState(() {
      _nomeController.text = nome;
      _elenco = elencoAtualizado;
      // Tira da escalação/líbero quem saiu do elenco.
      _posicoes = _posicoes
          .map((j) => (j != null && _elenco.any((e) => e.id == j.id)) ? j : null)
          .toList();
      if (_libero != null && !_elenco.any((e) => e.id == _libero!.id)) {
        _libero = null;
      }
    });
    _notificar();
  }

  /// Só um ponto de partida pra tela visual não abrir vazia: tenta achar
  /// 6 jogadores do elenco que batam com as funções exigidas pelo
  /// sistema, já na ordem certa. O técnico pode reorganizar à vontade.
  List<Jogador?>? _sugerirFormacao() {
    final exigido = _sistemaSelecionado.requisitos;
    if (exigido.isEmpty) return null;

    final porFuncao = <PosicaoJogador, List<Jogador>>{};
    for (final j in _elenco) {
      porFuncao.putIfAbsent(j.posicao, () => []).add(j);
    }

    final candidatos = <Jogador>[];
    for (final entrada in exigido.entries) {
      final disponiveis = porFuncao[entrada.key] ?? [];
      if (disponiveis.length < entrada.value) return null;
      candidatos.addAll(disponiveis.take(entrada.value));
    }

    return FormacaoTitular.organizar(candidatos, _sistemaSelecionado);
  }

  Future<void> _abrirEscalacaoVisual() async {
    List<Jogador?> posicoesIniciais = _posicoes;
    if (_titulares.isEmpty) {
      final sugestao = _sugerirFormacao();
      if (sugestao != null) posicoesIniciais = sugestao;
    }

    final resultado = await Navigator.push<(List<Jogador>, Jogador?)>(
      context,
      MaterialPageRoute(
        builder: (context) => TelaEscalacaoVisual(
          elenco: _elenco,
          sistema: _sistemaSelecionado,
          posicoesIniciais: posicoesIniciais,
          liberoInicial: _libero,
        ),
      ),
    );
    if (resultado == null) return;

    final (titulares, libero) = resultado;
    setState(() {
      _posicoes = List<Jogador?>.of(titulares);
      _libero = libero;
    });
    _notificar();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _nomeController,
          decoration: const InputDecoration(
            labelText: "Nome da equipe",
            border: OutlineInputBorder(),
            isDense: true,
          ),
          onChanged: (_) => _notificar(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Elenco (${_elenco.length}/14)", style: const TextStyle(fontWeight: FontWeight.bold)),
            OutlinedButton.icon(
              onPressed: _abrirElenco,
              icon: const Icon(Icons.groups),
              label: const Text("Gerenciar"),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_elenco.length < 6)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              "Adicione pelo menos 6 jogadores no elenco para escalar o time.",
              style: TextStyle(color: Colors.grey),
            ),
          )
        else ...[
          const Text("Sistema de rotação:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButtonFormField<SistemaRotacao>(
            value: _sistemaSelecionado,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: SistemaRotacao.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.rotulo)))
                .toList(),
            onChanged: (s) {
              if (s == null) return;
              setState(() {
                _sistemaSelecionado = s;
                // Uma escalação montada pra outro sistema pode não bater
                // mais com as exigências do novo — melhor remontar.
                _posicoes = List<Jogador?>.filled(6, null);
              });
              _notificar();
            },
          ),
          if (_sistemaSelecionado.requisitos.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              "Exige: ${_sistemaSelecionado.requisitos.entries.map((e) => "${e.value}x ${e.key.nomeCompleto}").join(", ")}",
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _abrirEscalacaoVisual,
            icon: const Icon(Icons.sports_volleyball),
            label: Text(_titulares.length == 6 ? "Editar escalação na quadra" : "Montar escalação na quadra"),
            style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
          ),
          const SizedBox(height: 12),
          if (_titulares.length == 6) _resumoEscalacao() else _avisoSemEscalacao(),
        ],
      ],
    );
  }

  Widget _resumoEscalacao() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[800], size: 16),
              const SizedBox(width: 6),
              Text(
                "Escalação pronta",
                style: TextStyle(color: Colors.green[900], fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (int i = 0; i < _titulares.length; i++)
                Chip(
                  label: Text("P${i + 1}: ${_titulares[i].rotuloCompleto}", style: const TextStyle(fontSize: 11)),
                  backgroundColor: _titulares[i].posicao == PosicaoJogador.levantador
                      ? Colors.yellow[200]
                      : Colors.white,
                  visualDensity: VisualDensity.compact,
                ),
              if (_libero != null)
                Chip(
                  avatar: const Icon(Icons.shield, size: 14),
                  label: Text("Líbero: ${_libero!.rotuloCompleto}", style: const TextStyle(fontSize: 11)),
                  backgroundColor: Colors.blue[100],
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _avisoSemEscalacao() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[800], size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "Ainda falta montar a escalação — toque em \"Montar escalação na quadra\".",
              style: TextStyle(color: Colors.deepOrange, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}