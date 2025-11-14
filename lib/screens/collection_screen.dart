import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';
import 'package:flutter_grimoire/models/collection_card.dart'; // <-- MUDANÇA IMPORTANTE
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionScreen extends ConsumerWidget {
  const CollectionScreen({super.key});

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  // Lógica atualizada para usar 'quantity'
  Future<void> _updateCardQuantity(CollectionCard card, int change) async {
    if (_userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('collection')
        .doc(card.id);

    final newQuantity = card.quantity + change;

    if (newQuantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQuantity});
    }
  }

  // Lógica atualizada para usar 'quantity'
  Future<void> _removeCardFromCollection(
    BuildContext context,
    CollectionCard card,
  ) async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('collection')
        .doc(card.id);

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remover Carta'),
            content: Text(
              'Tem certeza que deseja remover ${card.name} da sua coleção?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remover'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmDelete && context.mounted) {
      await docRef.delete();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agora usa o 'collectionProvider'
    final collectionAsyncValue = ref.watch(collectionProvider);

    return Scaffold(
      body: collectionAsyncValue.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Text(
                'Sua coleção está vazia. Use a tela "Buscar" para adicionar cartas!',
              ),
            );
          }
          return ListView.builder(
            itemCount: cards.length,
            itemBuilder: (context, index) {
              final card = cards[index];
              return ListTile(
                leading: card.imageUrlSmall != null
                    ? Image.network(card.imageUrlSmall!)
                    : const Icon(Icons.image),
                title: Text(card.name),
                subtitle: Text(card.typeLine),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () => _updateCardQuantity(card, -1),
                    ),
                    Text(
                      // Agora 'card.quantity' existe e está correto
                      card.quantity.toString(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _updateCardQuantity(card, 1),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: () => _removeCardFromCollection(context, card),
                    ),
                  ],
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Ocorreu um erro: $error')),
      ),
    );
  }
}
