import 'package:flutter/material.dart';

class HeaderPlacar extends StatelessWidget {
  final int placarNossaEquipe;
  final int placarAdversario;
  final String zonaTexto;
  final int numeroSet;
  final int setsNossos;
  final int setsAdversario;
  final String ladoComPosse; // "cima" ou "baixo"
  final String logAcao;

  const HeaderPlacar({
    super.key,
    required this.placarNossaEquipe,
    required this.placarAdversario,
    required this.zonaTexto,
    this.numeroSet = 1,
    this.setsNossos = 0,
    this.setsAdversario = 0,
    this.ladoComPosse = "baixo",
    this.logAcao = "",
  });

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;
    final double larguraMaximaLog = (larguraTela - 32).clamp(220.0, 340.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Text(
              "SET $numeroSet",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _boxSets(setsNossos, Colors.blueAccent),
                const SizedBox(width: 8),
                _buildBoxPlacar("NÓS", placarNossaEquipe, Colors.blueAccent),
                const SizedBox(width: 14),
                _indicadorPosse(),
                const SizedBox(width: 14),
                _buildBoxPlacar("ELES", placarAdversario, Colors.redAccent),
                const SizedBox(width: 8),
                _boxSets(setsAdversario, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              zonaTexto.toUpperCase(),
              style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, letterSpacing: 2, fontWeight: FontWeight.bold),
            ),
            if (logAcao.isNotEmpty) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: larguraMaximaLog),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Text(
                    logAcao.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.yellowAccent, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Caixinha do lado de fora de cada placar, contando quantos sets
  /// aquela equipe já ganhou na partida.
  Widget _boxSets(int sets, Color cor) {
    return Column(
      children: [
        Text(
          "SETS",
          style: TextStyle(color: cor.withOpacity(0.7), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        const SizedBox(height: 4),
        Container(
          width: 34,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: cor.withOpacity(0.5), width: 1.5),
          ),
          child: Text(
            "$sets",
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  /// Retângulo menor entre os dois placares: mostra a bola do lado de
  /// quem tem a posse no momento (embaixo = nossa, em cima = deles).
  Widget _indicadorPosse() {
    final bool nossa = ladoComPosse == "baixo";
    final Color cor = nossa ? Colors.blueAccent : Colors.redAccent;

    return Container(
      width: 42,
      height: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cor.withOpacity(0.6), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_volleyball, color: cor, size: 22),
          const SizedBox(height: 2),
          Icon(
            nossa ? Icons.arrow_downward : Icons.arrow_upward,
            color: cor,
            size: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildBoxPlacar(String label, int pontos, Color cor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(color: cor.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
        const SizedBox(height: 4),
        Container(
          width: 65,
          height: 55,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cor.withOpacity(0.4), width: 2),
          ),
          child: Text(
            pontos.toString().padLeft(2, '0'),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }
}