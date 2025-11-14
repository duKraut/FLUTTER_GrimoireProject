import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/providers/scryfall_provider.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_grimoire/models/scryfall_card.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      successMessage = '${card.name} adicionado ao deck!';
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
        final currentQuantity =
            (snapshot.data() as Map<String, dynamic>?)?['quantity'] ?? 0;

        if (isDeckMode) {
          final isCommanderFormat = widget.deck!.format == 'Commander';
          if (isCommanderFormat && currentQuantity >= 1) {
            throw Exception(
              'Decks Commander só podem ter 1 cópia de cada carta.',
            );
          }
          if (!isCommanderFormat && currentQuantity >= 4) {
            throw Exception('Decks só podem ter até 4 cópias de cada carta.');
          }
        }

        if (!snapshot.exists) {
          transaction.set(docRef, {
            'name': card.name,
            'typeLine': card.typeLine,
            'imageUrlSmall': card.imageUrlSmall,
            'artCrop': card.artCrop,
            'quantity': 1,
            'addedAt': FieldValue.serverTimestamp(),
          });
        } else {
          final newQuantity = currentQuantity + 1;
          transaction.update(docRef, {'quantity': newQuantity});
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
