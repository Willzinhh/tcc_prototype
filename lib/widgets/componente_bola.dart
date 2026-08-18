import 'package:flutter/material.dart';

class ComponenteBolaVisual extends StatelessWidget {
  const ComponenteBolaVisual({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: Colors.yellow,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(blurRadius: 10)],
      ),
      child: const Icon(Icons.sports_volleyball, color: Colors.orange, size: 30),
    );
  }
}