import 'package:flutter/material.dart';

import '../models/fundamento.dart';

/// Desenha um bonequinho (cabeça + tronco + pernas + braços) na pose de
/// cada fundamento — em vez de usar ícones genéricos do Material, que
/// não têm nada a ver com vôlei.
class IconeFundamento extends StatelessWidget {
  final Fundamento fundamento;
  final double tamanho;
  final Color cor;

  const IconeFundamento({
    super.key,
    required this.fundamento,
    this.tamanho = 24,
    this.cor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(tamanho, tamanho),
      painter: _BonecoFundamentoPainter(fundamento: fundamento, cor: cor),
    );
  }
}

class _BonecoFundamentoPainter extends CustomPainter {
  final Fundamento fundamento;
  final Color cor;

  _BonecoFundamentoPainter({required this.fundamento, required this.cor});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint traco = Paint()
      ..color = cor
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    late Offset cabeca, ombro, quadril, peA, peB, maoA, maoB;

    switch (fundamento) {
      case Fundamento.saque:
        // Braço armado atrás/em cima, prestes a sacar; outro à frente
        // apontando a bola.
        cabeca = Offset(w * 0.46, h * 0.16);
        ombro = Offset(w * 0.46, h * 0.36);
        quadril = Offset(w * 0.44, h * 0.62);
        peA = Offset(w * 0.30, h * 0.94);
        peB = Offset(w * 0.58, h * 0.94);
        maoA = Offset(w * 0.20, h * 0.34);
        maoB = Offset(w * 0.86, h * 0.06);
        break;

      case Fundamento.recepcao:
        // Braços juntos, esticados pra frente/baixo (plataforma de
        // recepção), pernas afastadas em base firme.
        cabeca = Offset(w * 0.5, h * 0.20);
        ombro = Offset(w * 0.5, h * 0.40);
        quadril = Offset(w * 0.5, h * 0.66);
        peA = Offset(w * 0.30, h * 0.94);
        peB = Offset(w * 0.70, h * 0.94);
        maoA = Offset(w * 0.16, h * 0.60);
        maoB = Offset(w * 0.20, h * 0.64);
        break;

      case Fundamento.levantamento:
        // Braços erguidos acima da cabeça, formando um "V" — mãos indo
        // ao encontro da bola.
        cabeca = Offset(w * 0.5, h * 0.24);
        ombro = Offset(w * 0.5, h * 0.44);
        quadril = Offset(w * 0.5, h * 0.66);
        peA = Offset(w * 0.36, h * 0.94);
        peB = Offset(w * 0.62, h * 0.94);
        maoA = Offset(w * 0.26, h * 0.04);
        maoB = Offset(w * 0.74, h * 0.04);
        break;

      case Fundamento.ataque:
        // Corpo inclinado no ar (salto), um braço todo esticado pra
        // cima/frente batendo na bola, outro pra trás em equilíbrio.
        cabeca = Offset(w * 0.56, h * 0.12);
        ombro = Offset(w * 0.52, h * 0.30);
        quadril = Offset(w * 0.44, h * 0.54);
        peA = Offset(w * 0.28, h * 0.78);
        peB = Offset(w * 0.54, h * 0.86);
        maoA = Offset(w * 0.94, h * 0.00);
        maoB = Offset(w * 0.16, h * 0.46);
        break;

      case Fundamento.bloqueio:
        // Os dois braços retos, colados, apontando pra cima — postura de
        // bloqueio duplo na rede.
        cabeca = Offset(w * 0.5, h * 0.14);
        ombro = Offset(w * 0.5, h * 0.32);
        quadril = Offset(w * 0.5, h * 0.56);
        peA = Offset(w * 0.38, h * 0.82);
        peB = Offset(w * 0.62, h * 0.82);
        maoA = Offset(w * 0.34, h * 0.00);
        maoB = Offset(w * 0.66, h * 0.00);
        break;

      case Fundamento.defesa:
        // Postura baixa/agachada, um braço esticado pro lado tentando
        // alcançar a bola — clássica posição de manchete.
        cabeca = Offset(w * 0.40, h * 0.32);
        ombro = Offset(w * 0.42, h * 0.46);
        quadril = Offset(w * 0.50, h * 0.66);
        peA = Offset(w * 0.30, h * 0.94);
        peB = Offset(w * 0.70, h * 0.88);
        maoA = Offset(w * 0.02, h * 0.62);
        maoB = Offset(w * 0.50, h * 0.50);
        break;
    }

    // Tronco
    canvas.drawLine(ombro, quadril, traco);
    // Pernas
    canvas.drawLine(quadril, peA, traco);
    canvas.drawLine(quadril, peB, traco);
    // Braços
    canvas.drawLine(ombro, maoA, traco);
    canvas.drawLine(ombro, maoB, traco);
    // Cabeça
    canvas.drawCircle(cabeca, w * 0.13, Paint()..color = cor);
  }

  @override
  bool shouldRepaint(covariant _BonecoFundamentoPainter oldDelegate) {
    return oldDelegate.fundamento != fundamento || oldDelegate.cor != cor;
  }
}
