import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CardSearchScreen extends ConsumerWidget {
  const CardSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buscar Cartas (Scryfall)')),
      body: const Center(
        child: Text('Aqui ficará a busca na API da Scryfall.'),
      ),
    );
  }
}
