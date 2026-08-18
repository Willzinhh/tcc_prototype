import 'package:flutter/material.dart';

class PainelInferiorStatus extends StatelessWidget {
  final String logAcao;
  final String ladoComPosse;
  final int contadorToques;
  final String complexoAtual;

  const PainelInferiorStatus({
    super.key,
    required this.logAcao,
    required this.ladoComPosse,
    required this.contadorToques,
    this.complexoAtual = "K0",
  });

  @override
  Widget build(BuildContext context) {
    final double larguraTela = MediaQuery.of(context).size.width;
    final double larguraMaxima = (larguraTela - 24).clamp(240.0, 340.0);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: larguraMaxima),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
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
          const SizedBox(height: 12),
          Container(
            width: larguraMaxima,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
              border: Border(bottom: BorderSide(color: Colors.blueAccent.withOpacity(0.5), width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text("POSSE", style: TextStyle(color: Colors.white30, fontSize: 8)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(ladoComPosse == "baixo" ? Icons.arrow_downward : Icons.arrow_upward, color: Colors.blueAccent, size: 14),
                        const SizedBox(width: 5),
                        Text(ladoComPosse == "baixo" ? "NOSSA" : "DELES",
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ],
                ),
                Container(width: 1, height: 20, color: Colors.white10),
                Column(
                  children: [
                    const Text("COMPLEXO", style: TextStyle(color: Colors.white30, fontSize: 8)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.deepPurpleAccent.withOpacity(0.6)),
                      ),
                      child: Text(
                        complexoAtual,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                Container(width: 1, height: 20, color: Colors.white10),
                Column(
                  children: [
                    const Text("TOQUES", style: TextStyle(color: Colors.white30, fontSize: 8)),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(3, (i) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 10, height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < contadorToques ? Colors.yellow : Colors.white10,
                          boxShadow: i < contadorToques ? [BoxShadow(color: Colors.yellow.withOpacity(0.4), blurRadius: 4)] : [],
                        ),
                      )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}