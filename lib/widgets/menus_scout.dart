import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class MenuRadialJogadores extends StatelessWidget {
  final List<String> jogadores;
  final Function(String) onSelecionado;
  final Function() onPontoDireto;
  final Function() onErroDireto;

  const MenuRadialJogadores({
    super.key,
    required this.jogadores,
    required this.onSelecionado,
    required this.onPontoDireto,
    required this.onErroDireto,
  });

  @override
  Widget build(BuildContext context) {
    // Criamos uma lista combinada: 6 jogadores + Ponto + Erro = 8 itens
    List<String> itensMenu = [...jogadores, "PONTO", "ERRO"];
    int totalItens = itensMenu.length;
    double raio = 65.0; // Distância do centro da bola

    return Container(
      width: double.infinity,
      height: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Círculo central invisível (representa a bola)
          const SizedBox(width: 1, height: 1),

          for (int i = 0; i < totalItens; i++)
            _buildBotaoCircular(i, totalItens, raio, itensMenu[i]),
        ],
      ),
    );
  }

  Widget _buildBotaoCircular(int i, int total, double raio, String texto) {
    // Cálculo do ângulo para distribuir os 8 botões uniformemente
    double angulo = i * (2 * math.pi / total);

    // Cores diferentes para destacar as ações dos jogadores
    Color corBotao = Colors.yellow;
    if (texto == "PONTO") corBotao = Colors.greenAccent;
    if (texto == "ERRO") corBotao = Colors.redAccent;

    return Transform.translate(
      offset: Offset(math.cos(angulo) * raio, math.sin(angulo) * raio),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (texto == "PONTO") {
            onPontoDireto();
          } else if (texto == "ERRO") {
            onErroDireto();
          } else {
            onSelecionado(texto);
          }
        },
        child: Container(
          width: 48, // Tamanho fixo da "moeda"
          height: 48,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.85), // Fundo escuro para destacar
            shape: BoxShape.circle,
            border: Border.all(color: corBotao, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: corBotao.withOpacity(0.4),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: texto.length > 2 ? 9 : 13, // Ajusta fonte para nomes longos
              fontWeight: FontWeight.bold,
              shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          ),
        ),
      ),
    );
  }
}

class MenuQualidadeAcao extends StatelessWidget {
  final Function(String) onAvaliado;

  const MenuQualidadeAcao({super.key, required this.onAvaliado});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220, // Um pouco maior para caber os textos
      height: 220,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // TOPO: Ponto Directo (Ace ou Ataque vencedor)
          _itemQualidade(Alignment(0, -0.85), "##", Colors.green, "PONTO"),

          // BAIXO: Erro (Rede, Fora, Invasão)
          _itemQualidade(Alignment(0, 0.85), "==", Colors.red, "ERRO"),

          // DIREITA: Ação Positiva (Passe na mão ou defesa que gera contra-ataque)
          _itemQualidade(Alignment(0.85, 0), "+", Colors.blue, "POSITIVA"),

          // ESQUERDA: Ação Negativa (Passe "A", bola de xeque ou defesa difícil)
          _itemQualidade(Alignment(-0.85, 0), "-", Colors.orange, "NEGATIVA"),

          // CENTRO: Ação Neutra (Continuidade de jogo)
          _itemQualidade(Alignment(0, 0), "!", Colors.grey, "NEUTRA"),
        ],
      ),
    );
  }

  Widget _itemQualidade(Alignment align, String sigla, Color cor, String desc) {
    return Align(
      alignment: align,
      child: GestureDetector(
        onTap: () => onAvaliado(desc),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: cor,
              radius: 22,
              child: Text(sigla, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}