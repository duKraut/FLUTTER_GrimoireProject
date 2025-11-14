import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/providers/scryfall_provider.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_grimoire/models/scryfall_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_grimoire/providers/deck_provider.dart';

class CardSearchScreen extends ConsumerStatefulWidget {
  final Deck? deck;
  final bool isSearchingCommander;

  const CardSearchScreen({
    super.key,
    this.deck,
    this.isSearchingCommander = false,
  });

  @override
  ConsumerState<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends ConsumerState<CardSearchScreen> {
  Timer? _debounce;
  final _searchController = TextEditingController();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        ref.read(cardSearchResultsProvider.notifier).state = [];
        return;
      }

      ref.read(cardSearchIsLoadingProvider.notifier).state = true;
      final service = ref.read(scryfallServiceProvider);

      final results = await service.searchCards(
        query,
        isCommanderSearch: widget.isSearchingCommander,
      );

      if (mounted) {
        ref.read(cardSearchResultsProvider.notifier).state = results;
        ref.read(cardSearchIsLoadingProvider.notifier).state = false;
      }
    });
  }

  Future<void> _showErrorSnackbar(String message) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _addCard(ScryfallCard card) async {
    if (_userId == null) return;
    if (!mounted) return;

    final isDeckMode = widget.deck != null;

    if (isDeckMode && widget.isSearchingCommander) {
      try {
        final deckDocRef = _firestore
            .collection('users')
            .doc(_userId!)
            .collection('decks')
            .doc(widget.deck!.id);

        await deckDocRef.update({
          'commanderCardId': card.id,
          'commanderName': card.name,
          'commanderImageUrl': card.artCrop ?? card.imageUrlSmall,
        });

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        _showErrorSnackbar('Erro ao definir comandante: $e');
      }
      return;
    }

    if (isDeckMode && widget.deck!.format != 'Commander') {
      final sideboardCount =
          ref.read(sideboardCountProvider(widget.deck!.id)).value ?? 0;

      final String? board = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text('Adicionar ${card.name}'),
          content: const Text(
            'Adicionar esta carta ao deck principal ou ao sideboard?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'main'),
              child: const Text('Deck Principal'),
            ),
            FilledButton(
              onPressed: sideboardCount >= 15
                  ? null
                  : () => Navigator.pop(dialogContext, 'side'),
              child: Text('Sideboard (${sideboardCount}/15)'),
            ),
          ],
        ),
      );

      if (board == null) return;

      if (board == 'side' && sideboardCount >= 15) {
        _showErrorSnackbar('O seu sideboard já tem 15 cartas.');
        return;
      }

      _addCardToBoard(card, board);
    } else {
      _addCardToBoard(card, 'main');
    }
  }

  Future<void> _addCardToBoard(ScryfallCard card, String board) async {
    if (_userId == null) return;
    if (!mounted) return;

    final isDeckMode = widget.deck != null;
    late final DocumentReference docRef;
    late final String successMessage;

    if (isDeckMode) {
      final deckId = widget.deck!.id;
      docRef = _firestore
          .collection('users')
          .doc(_userId!)
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .doc(card.id);
      successMessage = '${card.name} adicionado ao $board!';
    } else {
      docRef = _firestore
          .collection('users')
          .doc(_userId!)
          .collection('collection')
          .doc(card.id);
      successMessage = '${card.name} adicionado à coleção!';
    }

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        final data = snapshot.data() as Map<String, dynamic>?;

        final bool isBasicLand = card.typeLine.contains('Basic Land');

        // ***** LÓGICA ATUALIZADA AQUI *****
        // Se NÃO for modo deck (ou seja, é modo coleção)
        if (!isDeckMode) {
          final currentQuantity = data?['quantity'] ?? 0;
          transaction.set(docRef, {
            'name': card.name,
            'typeLine': card.typeLine,
            'imageUrlSmall': card.imageUrlSmall,
            'artCrop': card.artCrop,
            'addedAt': FieldValue.serverTimestamp(),
            'quantity': currentQuantity + 1, // Usar 'quantity'
          }, SetOptions(merge: true));
          return;
        }
        // ***** FIM DA ATUALIZAÇÃO (MODO COLEÇÃO) *****

        // ***** INÍCIO DA LÓGICA (MODO DECK) *****
        final currentMain = data?['mainboardQuantity'] ?? 0;
        final currentSide = data?['sideboardQuantity'] ?? 0;
        final totalCopies = currentMain + currentSide;

        if (isDeckMode) {
          final isCommanderFormat = widget.deck!.format == 'Commander';

          if (!isBasicLand) {
            if (isCommanderFormat && totalCopies >= 1) {
              throw Exception(
                'Decks Commander só podem ter 1 cópia de cada carta (exceto terrenos básicos).',
              );
            }
            if (!isCommanderFormat && totalCopies >= 4) {
              throw Exception(
                'Decks só podem ter até 4 cópias de cada carta (exceto terrenos básicos).',
              );
            }
          }
        }

        final updateData = {
          'name': card.name,
          'typeLine': card.typeLine,
          'imageUrlSmall': card.imageUrlSmall,
          'artCrop': card.artCrop,
          'addedAt': FieldValue.serverTimestamp(),
          'mainboardQuantity': board == 'main' ? currentMain + 1 : currentMain,
          'sideboardQuantity': board == 'side' ? currentSide + 1 : currentSide,
        };

        if (!snapshot.exists) {
          transaction.set(docRef, updateData);
        } else {
          transaction.update(docRef, updateData);
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackbar(e.toString().replaceFirst("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(cardSearchResultsProvider);
    final isLoading = ref.watch(cardSearchIsLoadingProvider);
    final bool isDeckMode = widget.deck != null;

    String appBarTitle = 'Buscar Cartas';
    if (isDeckMode) {
      appBarTitle = widget.isSearchingCommander
          ? 'Selecionar Comandante'
          : 'Adicionar a: ${widget.deck!.name}';
    }

    return Scaffold(
      appBar: isDeckMode ? AppBar(title: Text(appBarTitle)) : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: widget.isSearchingCommander
                    ? 'Buscar comandante (ex: Urza)...'
                    : 'Buscar carta (ex: Sol Ring)...',
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      )
                    : const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final card = results[index];
                return ListTile(
                  leading: card.imageUrlSmall != null
                      ? Image.network(card.imageUrlSmall!)
                      : const Icon(Icons.image_not_supported),
                  title: Text(card.name),
                  subtitle: Text(card.typeLine),
                  trailing: IconButton(
                    icon: const Icon(Icons.add_circle),
                    onPressed: () => _addCard(card),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
