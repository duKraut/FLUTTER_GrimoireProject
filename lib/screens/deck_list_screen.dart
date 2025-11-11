import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DeckListScreen extends ConsumerWidget {
  const DeckListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Decks'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: () {})],
      ),
      body: const Center(
        child: Text('Aqui ficará a lista de decks do usuário.'),
      ),
    );
  }
}
