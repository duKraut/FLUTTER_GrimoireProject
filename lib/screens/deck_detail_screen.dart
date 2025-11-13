import 'package:flutter/material.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/screens/card_search_screen.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';
import 'package:flutter_grimoire/models/deck_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckDetailScreen extends ConsumerWidget {
  final Deck deck;

  const DeckDetailScreen({super.key, required this.deck});

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _updateCardQuantity(DeckCard card, int change) async {
    if (_userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deck.id)
        .collection('cards')
        .doc(card.id);

    final newQuantity = card.quantity + change;

    if (newQuantity <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({'quantity': newQuantity});
    }
  }

  Future<void> _removeCardFromDeck(BuildContext context, DeckCard card) async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deck.id)
        .collection('cards')
        .doc(card.id);

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Remover Carta'),
            content: Text(
              'Tem certeza que deseja remover ${card.name} do deck?',
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
    final cardsAsyncValue = ref.watch(deckCardsProvider(deck.id));

    return Scaffold(
      appBar: AppBar(title: Text(deck.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardSearchScreen(deck: deck),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: cardsAsyncValue.when(
        data: (cards) {
          if (cards.isEmpty) {
            return const Center(
              child: Text('Este deck ainda não tem cartas. Adicione algumas!'),
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
                      onPressed: () => _removeCardFromDeck(context, card),
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
