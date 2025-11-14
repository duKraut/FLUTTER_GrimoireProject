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
    WidgetRef ref,
    Deck deck,
    DeckCard card,
    String board,
    int change,
  ) async {
    if (_userId == null) return;

    final docRef = _firestore
        .collection('users')
        .doc(_userId!)
        .collection('decks')
        .doc(deck.id)
        .collection('cards')
        .doc(card.id);

    final currentMain = card.mainboardQuantity;
    final currentSide = card.sideboardQuantity;
    final totalCopies = currentMain + currentSide;

    if (change > 0) {
      final bool isBasicLand = card.typeLine.contains('Basic Land');
      if (!isBasicLand) {
        if (deck.format == 'Commander' && totalCopies >= 1) {
          _showErrorSnackbar(
            context,
            'Decks Commander só podem ter 1 cópia de cada carta (exceto terrenos básicos).',
          );
          return;
        }
        if (deck.format != 'Commander' && totalCopies >= 4) {
          _showErrorSnackbar(
            context,
            'Decks só podem ter até 4 cópias de cada carta (exceto terrenos básicos).',
          );
          return;
        }
      }

      if (board == 'side') {
        final sideboardCount =
            ref.read(sideboardCountProvider(deck.id)).value ?? 0;
        if (sideboardCount + change > 15) {
          _showErrorSnackbar(
            context,
            'O sideboard não pode ter mais de 15 cartas.',
          );
          return;
        }
      }
    }

    final newMain = board == 'main' ? currentMain + change : currentMain;
    final newSide = board == 'side' ? currentSide + change : currentSide;

    if (newMain <= 0 && newSide <= 0) {
      await docRef.delete();
    } else {
      await docRef.update({
        'mainboardQuantity': newMain < 0 ? 0 : newMain,
        'sideboardQuantity': newSide < 0 ? 0 : newSide,
      });
    }
  }

  Future<void> _removeCardFromDeck(
    BuildContext context,
    Deck deck,
    DeckCard card,
    String board,
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

    final currentMain = card.mainboardQuantity;
    final currentSide = card.sideboardQuantity;

    final newMain = board == 'main' ? 0 : currentMain;
    final newSide = board == 'side' ? 0 : currentSide;

    if (newMain == 0 && newSide == 0) {
      await docRef.delete();
    } else {
      await docRef.update({
        'mainboardQuantity': newMain,
        'sideboardQuantity': newSide,
      });
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

  Widget _buildCardList(
    BuildContext context,
    WidgetRef ref,
    Deck deck,
    List<DeckCard> cards,
    String board,
  ) {
    return ListView.builder(
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        final quantity = board == 'main'
            ? card.mainboardQuantity
            : card.sideboardQuantity;

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
                    _updateCardQuantity(context, ref, deck, card, board, -1),
              ),
              Text(
                quantity.toString(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () =>
                    _updateCardQuantity(context, ref, deck, card, board, 1),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                onPressed: () =>
                    _removeCardFromDeck(context, deck, card, board),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommanderDeck(BuildContext context, WidgetRef ref, Deck deck) {
    final bool hasCommander = deck.commanderCardId != null;

    return Column(
      children: [
        if (hasCommander) _buildCommanderHeader(context, deck),
        Expanded(
          child: (hasCommander)
              ? ref
                    .watch(deckCardsProvider(deck.id))
                    .when(
                      data: (cards) {
                        final mainboardCards = cards
                            .where((c) => c.mainboardQuantity > 0)
                            .toList();
                        if (mainboardCards.isEmpty) {
                          return const Center(
                            child: Text(
                              'Este deck ainda não tem cartas. Adicione algumas!',
                            ),
                          );
                        }
                        return _buildCardList(
                          context,
                          ref,
                          deck,
                          mainboardCards,
                          'main',
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) =>
                          Center(child: Text('Ocorreu um erro: $error')),
                    )
              : _buildAddCommanderButton(context, deck),
        ),
      ],
    );
  }

  Widget _buildStandardDeck(BuildContext context, WidgetRef ref, Deck deck) {
    final allCardsAsync = ref.watch(deckCardsProvider(deck.id));
    final sideboardCountAsync = ref.watch(sideboardCountProvider(deck.id));

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              const Tab(text: 'Deck Principal'),
              Tab(
                child: sideboardCountAsync.when(
                  data: (count) => Text('Sideboard ($count/15)'),
                  loading: () => const Text('Sideboard (../15)'),
                  error: (e, s) => const Text('Sideboard'),
                ),
              ),
            ],
          ),
          Expanded(
            child: allCardsAsync.when(
              data: (cards) {
                final mainboardCards = cards
                    .where((c) => c.mainboardQuantity > 0)
                    .toList();
                final sideboardCards = cards
                    .where((c) => c.sideboardQuantity > 0)
                    .toList();

                return TabBarView(
                  children: [
                    mainboardCards.isEmpty
                        ? const Center(
                            child: Text(
                              'O deck principal está vazio. Adicione cartas!',
                            ),
                          )
                        : _buildCardList(
                            context,
                            ref,
                            deck,
                            mainboardCards,
                            'main',
                          ),
                    sideboardCards.isEmpty
                        ? const Center(
                            child: Text(
                              'O sideboard está vazio. Adicione cartas!',
                            ),
                          )
                        : _buildCardList(
                            context,
                            ref,
                            deck,
                            sideboardCards,
                            'side',
                          ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  Center(child: Text('Ocorreu um erro: $error')),
            ),
          ),
        ],
      ),
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
          body: isCommanderFormat
              ? _buildCommanderDeck(context, ref, deck)
              : _buildStandardDeck(context, ref, deck),
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
