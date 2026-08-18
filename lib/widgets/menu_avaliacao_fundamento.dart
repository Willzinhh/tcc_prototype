import 'package:flutter/material.dart';

import '../models/avaliacao_fundamento.dart';
import '../models/fundamento.dart';
import 'icone_fundamento.dart';

/// Menu que aparece depois de escolher o jogador: primeiro deixa trocar
/// o fundamento sugerido pelo app (ícones R/E/A/B/D... Saque é tratado
/// à parte), depois mostra as opções de avaliação corretas para aquele
/// fundamento (sintaxe DataVolley 4).
class MenuAvaliacaoFundamento extends StatelessWidget {
  final List<Fundamento> fundamentosDisponiveis;
  final Fundamento fundamentoSelecionado;
  final ValueChanged<Fundamento> onTrocarFundamento;
  final ValueChanged<OpcaoAvaliacao> onAvaliado;

  const MenuAvaliacaoFundamento({
    super.key,
    required this.fundamentosDisponiveis,
    required this.fundamentoSelecionado,
    required this.onTrocarFundamento,
    required this.onAvaliado,
  });

  @override
  Widget build(BuildContext context) {
    final opcoes = AvaliacaoFundamento.opcoesPara(fundamentoSelecionado);

    return Container(
      width: 260,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: fundamentosDisponiveis.map((f) => _botaoFundamento(f)).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            fundamentoSelecionado.nomeCompleto.toUpperCase(),
            style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ...opcoes.map(_botaoAvaliacao),
        ],
      ),
    );
  }

  Widget _botaoFundamento(Fundamento f) {
    final bool selecionado = f == fundamentoSelecionado;
    return GestureDetector(
      onTap: () => onTrocarFundamento(f),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selecionado ? Colors.yellow : Colors.white10,
              border: Border.all(color: selecionado ? Colors.yellow : Colors.white30, width: 1.5),
            ),
            child: IconeFundamento(
              fundamento: f,
              tamanho: 22,
              cor: selecionado ? Colors.black : Colors.white70,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            f.sigla,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: selecionado ? Colors.yellow : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _botaoAvaliacao(OpcaoAvaliacao opcao) {
    Color cor = Colors.blueGrey;
    if (opcao.ehPonto) cor = Colors.greenAccent;
    if (opcao.ehErro) cor = Colors.redAccent;
    if (opcao.geraKV) cor = Colors.orangeAccent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: GestureDetector(
        onTap: () => onAvaliado(opcao),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cor.withOpacity(0.6)),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cor.withOpacity(0.3)),
                child: Text(
                  "${fundamentoSelecionado.sigla}${opcao.simbolo}",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(opcao.rotulo, style: const TextStyle(color: Colors.white, fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}