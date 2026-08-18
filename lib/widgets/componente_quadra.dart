import 'package:flutter/material.dart';

class ComponenteQuadraVisual extends StatelessWidget {
  final double largura;
  final double altura;

  const ComponenteQuadraVisual({
    super.key,
    required this.largura,
    required this.altura,
  });

  // Mapa de zonas por metade da quadra, em [linha][coluna].
  // Linha 0 = mais longe da rede (fundo), linha 2 = mais perto da rede.
  // Precisa bater exatamente com VoleiUtils.identificarZona.
  static const List<List<String>> _zonasLadoCima = [
    ["", "", ""], // fundo (topo da tela) - lado do adversário
    ["", "", ""], // meio
    ["", "", ""], // perto da rede
  ];

  static const List<List<String>> _zonasLadoBaixo = [
    ["", "", ""], // perto da rede - nosso lado
    ["", "", ""], // meio
    ["", "", ""], // fundo (base da tela)
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: largura,
      height: altura,
      decoration: BoxDecoration(
        color: Colors.orange[300],
        border: Border.all(color: Colors.white, width: 4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size(largura, altura),
            painter: _QuadraGridPainter(),
          ),
          ..._buildRotulos(),
        ],
      ),
    );
  }

  List<Widget> _buildRotulos() {
    final List<Widget> rotulos = [];
    final double alturaMeia = altura / 2;
    final double larguraCel = largura / 3;
    final double alturaCel = alturaMeia / 3;

    for (int linha = 0; linha < 3; linha++) {
      for (int col = 0; col < 3; col++) {
        rotulos.add(_rotulo(
          _zonasLadoCima[linha][col],
          col * larguraCel,
          linha * alturaCel,
          larguraCel,
          alturaCel,
        ));

        rotulos.add(_rotulo(
          _zonasLadoBaixo[linha][col],
          col * larguraCel,
          alturaMeia + linha * alturaCel,
          larguraCel,
          alturaCel,
        ));
      }
    }
    return rotulos;
  }

  Widget _rotulo(String texto, double left, double top, double w, double h) {
    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: IgnorePointer(
        child: Center(
          child: Text(
            texto,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuadraGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint linhaFina = Paint()
      ..color = Colors.white.withOpacity(0.35)
      ..strokeWidth = 1.5;
    final Paint linhaRede = Paint()
      ..color = Colors.white
      ..strokeWidth = 4;

    final double larguraCel = size.width / 3;
    final double alturaMeia = size.height / 2;
    final double alturaCel = alturaMeia / 3;

    // Linhas verticais (colunas), atravessam a quadra inteira.
    for (int i = 1; i < 3; i++) {
      final double x = larguraCel * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linhaFina);
    }

    // Linhas horizontais dentro de cada metade (profundidade).
    for (int i = 1; i < 3; i++) {
      final double yCima = alturaCel * i;
      canvas.drawLine(Offset(0, yCima), Offset(size.width, yCima), linhaFina);

      final double yBaixo = alturaMeia + alturaCel * i;
      canvas.drawLine(Offset(0, yBaixo), Offset(size.width, yBaixo), linhaFina);
    }

    // Linha da rede (centro), mais grossa que as demais.
    canvas.drawLine(Offset(0, alturaMeia), Offset(size.width, alturaMeia), linhaRede);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}