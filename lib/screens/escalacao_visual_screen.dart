import 'package:flutter/material.dart';

import '../models/jogador.dart';
import '../models/sistema_rotacao.dart';

/// Tela de escalação visual: o técnico arrasta os jogadores do elenco
/// pras 6 posições da quadra (layout padrão de vôlei: P4-P3-P2 perto da
/// rede, P5-P6-P1 no fundo). Valida em tempo real se a composição bate
/// com o que o sistema de rotação escolhido exige.
class TelaEscalacaoVisual extends StatefulWidget {
  final List<Jogador> elenco;
  final SistemaRotacao sistema;
  final List<Jogador?> posicoesIniciais; // 6 posições, pode ter null
  final Jogador? liberoInicial;

  const TelaEscalacaoVisual({
    super.key,
    required this.elenco,
    required this.sistema,
    this.posicoesIniciais = const [null, null, null, null, null, null],
    this.liberoInicial,
  });

  @override
  State<TelaEscalacaoVisual> createState() => _TelaEscalacaoVisualState();
}

class _TelaEscalacaoVisualState extends State<TelaEscalacaoVisual> {
  // índice 0..5 = posição 1..6 (mesma convenção do resto do app)
  late List<Jogador?> _posicoes;
  Jogador? _libero;

  @override
  void initState() {
    super.initState();
    _posicoes = List.of(widget.posicoesIniciais);
    while (_posicoes.length < 6) {
      _posicoes.add(null);
    }
    _libero = widget.liberoInicial;
  }

  List<Jogador> get _jogadoresNaQuadra => _posicoes.whereType<Jogador>().toList();

  List<Jogador> get _jogadoresDisponiveis {
    return widget.elenco
        .where((j) => !_jogadoresNaQuadra.any((q) => q.id == j.id))
        .where((j) => _libero == null || j.id != _libero!.id)
        .toList();
  }

  List<Jogador> get _liberosDisponiveis {
    return widget.elenco.where((j) => j.posicao == PosicaoJogador.libero).toList();
  }

  void _colocarNaPosicao(int indice, Jogador jogador) {
    setState(() {
      // Se o jogador já estava em outra posição, libera ela.
      for (int i = 0; i < _posicoes.length; i++) {
        if (_posicoes[i]?.id == jogador.id) _posicoes[i] = null;
      }
      _posicoes[indice] = jogador;
    });
  }

  void _removerDaPosicao(int indice) {
    setState(() => _posicoes[indice] = null);
  }

  /// Compara a composição atual (jogadores já colocados na quadra) com o
  /// que o sistema exige. Retorna o que falta, função por função.
  Map<PosicaoJogador, int> get _faltando {
    final exigido = widget.sistema.requisitos;
    if (exigido.isEmpty) return {};

    final contagemAtual = <PosicaoJogador, int>{};
    for (final j in _jogadoresNaQuadra) {
      contagemAtual[j.posicao] = (contagemAtual[j.posicao] ?? 0) + 1;
    }

    final faltando = <PosicaoJogador, int>{};
    exigido.forEach((posicao, quantidade) {
      final atual = contagemAtual[posicao] ?? 0;
      if (atual < quantidade) faltando[posicao] = quantidade - atual;
    });
    return faltando;
  }

  bool get _completo => _jogadoresNaQuadra.length == 6;
  bool get _pronto => _completo && _faltando.isEmpty;

  void _confirmar() {
    if (!_completo) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Preencha as 6 posições antes de confirmar.")),
      );
      return;
    }
    Navigator.pop(context, (_posicoes.whereType<Jogador>().toList(), _libero));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        title: const Text("Escalação na Quadra"),
        backgroundColor: Colors.green[900],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (widget.sistema.requisitos.isNotEmpty) _faixaValidacao(),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _quadraComPosicoes(),
            ),
          ),
          if (_liberosDisponiveis.isNotEmpty) _seletorLibero(),
          Expanded(
            flex: 2,
            child: _painelJogadoresDisponiveis(),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: _pronto || widget.sistema.requisitos.isEmpty ? _confirmar : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                disabledBackgroundColor: Colors.grey[800],
                minimumSize: const Size(double.infinity, 52),
              ),
              child: Text(
                _completo ? "USAR ESSA ESCALAÇÃO" : "PREENCHA AS 6 POSIÇÕES (${_jogadoresNaQuadra.length}/6)",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _faixaValidacao() {
    final faltando = _faltando;
    final bool ok = _completo && faltando.isEmpty;
    final Color cor = ok ? Colors.greenAccent : Colors.orangeAccent;

    String texto;
    if (!_completo) {
      texto = "Sistema ${widget.sistema.rotulo}: arraste os 6 titulares pra quadra.";
    } else if (faltando.isEmpty) {
      texto = "Composição certa pro ${widget.sistema.rotulo}!";
    } else {
      final partes = faltando.entries.map((e) => "${e.value}x ${e.key.nomeCompleto}").join(", ");
      texto = "Faltando pro ${widget.sistema.rotulo}: $partes";
    }

    return Container(
      width: double.infinity,
      color: cor.withOpacity(0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.info_outline, color: cor, size: 16),
          const SizedBox(width: 8),
          Expanded(child: Text(texto, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _seletorLibero() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.shield, color: Colors.white54, size: 16),
          const SizedBox(width: 8),
          const Text("Líbero:", style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(width: 8),
          DropdownButton<Jogador?>(
            value: _libero,
            dropdownColor: const Color(0xFF1A1A1A),
            hint: const Text("Nenhum", style: TextStyle(color: Colors.white54, fontSize: 12)),
            items: [
              const DropdownMenuItem<Jogador?>(
                value: null,
                child: Text("Nenhum", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ),
              ..._liberosDisponiveis.map(
                (j) => DropdownMenuItem<Jogador?>(
                  value: j,
                  child: Text(j.rotuloCompleto, style: const TextStyle(color: Colors.white, fontSize: 12)),
                ),
              ),
            ],
            onChanged: (j) => setState(() => _libero = j),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              "substitui automaticamente o central no fundo (exceto sacando)",
              style: TextStyle(color: Colors.white38, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout padrão de vôlei: perto da rede P4-P3-P2, no fundo P5-P6-P1.
  Widget _quadraComPosicoes() {
    return Column(
      children: [
        const Text("REDE", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 4)),
        const SizedBox(height: 4),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _slotPosicao(3)), // P4
              Expanded(child: _slotPosicao(2)), // P3
              Expanded(child: _slotPosicao(1)), // P2
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _slotPosicao(4)), // P5
              Expanded(child: _slotPosicao(5)), // P6
              Expanded(child: _slotPosicao(0)), // P1 (saque)
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text("FUNDO DA QUADRA", style: TextStyle(color: Colors.white24, fontSize: 10, letterSpacing: 2)),
      ],
    );
  }

  Widget _slotPosicao(int indice) {
    final Jogador? ocupante = _posicoes[indice];

    return Padding(
      padding: const EdgeInsets.all(4),
      child: DragTarget<Jogador>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (detalhe) => _colocarNaPosicao(indice, detalhe.data),
        builder: (context, candidatos, rejeitados) {
          final bool recebendo = candidatos.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: recebendo ? Colors.yellow.withOpacity(0.15) : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: recebendo ? Colors.yellow : Colors.white24,
                width: recebendo ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("P${indice + 1}", style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                if (ocupante == null)
                  const Icon(Icons.add, color: Colors.white24, size: 20)
                else
                  GestureDetector(
                    onTap: () => _removerDaPosicao(indice),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blueAccent,
                          child: Text(ocupante.numero.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          ocupante.nome,
                          style: const TextStyle(color: Colors.white, fontSize: 9),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          ocupante.posicao.sigla,
                          style: const TextStyle(color: Colors.white54, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _painelJogadoresDisponiveis() {
    final disponiveis = _jogadoresDisponiveis;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ELENCO (arraste pra quadra) — ${disponiveis.length} disponíveis",
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: disponiveis.isEmpty
                ? const Center(
                    child: Text("Todos os jogadores já estão em quadra.", style: TextStyle(color: Colors.white38, fontSize: 12)),
                  )
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 90,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: disponiveis.length,
                    itemBuilder: (context, index) => _chipArrastavel(disponiveis[index]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chipArrastavel(Jogador jogador) {
    final card = Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.green[700],
            child: Text(jogador.numero.toString(), style: const TextStyle(color: Colors.white, fontSize: 12)),
          ),
          const SizedBox(height: 4),
          Text(
            jogador.nome,
            style: const TextStyle(color: Colors.white, fontSize: 9),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(jogador.posicao.sigla, style: const TextStyle(color: Colors.white54, fontSize: 8)),
        ],
      ),
    );

    return Draggable<Jogador>(
      data: jogador,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 80, height: 90, child: card),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: card),
      child: card,
    );
  }
}
