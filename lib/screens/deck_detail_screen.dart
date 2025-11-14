import 'package:flutter/material.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/screens/card_search_screen.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';
import 'package:flutter_grimoire/models/deck_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeckDetailScreen extends ConsumerWidget {
  final String deckId;

  const DeckDetailScreen({super.key, required this.deckId});

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _showErrorSnackbar(BuildContext context, String message) async {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _updateCardQuantity(
    BuildContext context,
    Deck deck,
    DeckCard card,
    int change,
  ) async {
    if (_userId == null) return;

    if (change > 0) {
      final isCommanderFormat = deck.format == 'Commander';
      if (isCommanderFormat && card.quantity >= 1) {
        _showErrorSnackbar(
          context,
          'Decks Commander só podem ter 1 cópia de cada carta.',
        );
        return;
      }
      if (!isCommanderFormat && card.quantity >= 4) {
        _showErrorSnackbar(
          context,
          'Decks só podem ter até 4 cópias de cada carta.',
        );
        return;
      }
    }

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

  Future<void> _removeCardFromDeck(
    BuildContext context,
    Deck deck,
    DeckCard card,
  ) async {
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

  Future<void> _removeCommander(BuildContext context, Deck deck) async {
    if (_userId == null) return;
    if (!context.mounted) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deck.id);

    bool confirmDelete =
        await showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Trocar Comandante'),
            content: Text(
              'Tem certeza que deseja remover ${deck.commanderName} como comandante?',
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
      await docRef.update({
        'commanderCardId': FieldValue.delete(),
        'commanderName': FieldValue.delete(),
        'commanderImageUrl': FieldValue.delete(),
      });
    }
  }

  void _navigateSearch(
    BuildContext context,
    Deck deck, {
    bool isCommander = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CardSearchScreen(deck: deck, isSearchingCommander: isCommander),
      ),
    );
  }

  Widget _buildCommanderHeader(BuildContext context, Deck deck) {
    return ListTile(
      leading: deck.commanderImageUrl != null
          ? Image.network(deck.commanderImageUrl!)
          : const Icon(Icons.person),
      title: Text(deck.commanderName ?? 'Comandante'),
      subtitle: const Text('Comandante'),
      tileColor: Theme.of(
        context,
      ).colorScheme.primaryContainer.withOpacity(0.3),
      trailing: IconButton(
        icon: const Icon(Icons.change_circle_outlined),
        tooltip: 'Trocar Comandante',
        onPressed: () => _removeCommander(context, deck),
      ),
    );
  }

  Widget _buildAddCommanderButton(BuildContext context, Deck deck) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Este deck de Commander precisa de um comandante.'),
          const SizedBox(height: 16),
          FilledButton.icon(
            icon: const Icon(Icons.person_add),
            label: const Text('Selecionar Comandante'),
            onPressed: () => _navigateSearch(context, deck, isCommander: true),
          ),
        ],
      ),
    );
  }

  Widget _buildCardList(BuildContext context, WidgetRef ref, Deck deck) {
    final cardsAsyncValue = ref.watch(deckCardsProvider(deck.id));
    return cardsAsyncValue.when(
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
                    onPressed: () =>
                        _updateCardQuantity(context, deck, card, -1),
                  ),
                  Text(
                    card.quantity.toString(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: () =>
                        _updateCardQuantity(context, deck, card, 1),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onPressed: () => _removeCardFromDeck(context, deck, card),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Ocorreu um erro: $error')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deckAsyncValue = ref.watch(deckDetailProvider(deckId));

    return deckAsyncValue.when(
      data: (deck) {
        final isCommanderFormat = deck.format == 'Commander';
        final hasCommander = deck.commanderCardId != null;

        return Scaffold(
          appBar: AppBar(title: Text(deck.name)),
          floatingActionButton: (isCommanderFormat && !hasCommander)
              ? null
              : FloatingActionButton(
                  onPressed: () =>
                      _navigateSearch(context, deck, isCommander: false),
                  child: const Icon(Icons.add),
                ),
          body: Column(
            children: [
              if (isCommanderFormat && hasCommander)
                _buildCommanderHeader(context, deck),

              Expanded(
                child: (isCommanderFormat && !hasCommander)
                    ? _buildAddCommanderButton(context, deck)
                    : _buildCardList(context, ref, deck),
              ),
            ],
          ),
        );
      },
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Não foi possível carregar o deck: $error')),
      ),
    );
  }
}
