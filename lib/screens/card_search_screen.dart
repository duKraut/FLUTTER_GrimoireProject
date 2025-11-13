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

  const CardSearchScreen({super.key, this.deck});

  @override
  ConsumerState<CardSearchScreen> createState() => _CardSearchScreenState();
}

class _CardSearchScreenState extends ConsumerState<CardSearchScreen> {
  Timer? _debounce;
  final _searchController = TextEditingController();

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
      final results = await service.searchCards(query);
      if (mounted) {
        ref.read(cardSearchResultsProvider.notifier).state = results;
        ref.read(cardSearchIsLoadingProvider.notifier).state = false;
      }
    });
  }

  Future<void> _addCard(ScryfallCard card) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (!mounted) return;

    final bool isDeckMode = widget.deck != null;
    late final DocumentReference docRef;
    late final String successMessage;

    if (isDeckMode) {
      final deckId = widget.deck!.id;
      docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('decks')
          .doc(deckId)
          .collection('cards')
          .doc(card.id);
      successMessage = '${card.name} adicionado ao deck!';
    } else {
      docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('collection')
          .doc(card.id);
      successMessage = '${card.name} adicionado à coleção!';
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);

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
          final data = snapshot.data() as Map<String, dynamic>;
          final newQuantity = (data['quantity'] ?? 0) + 1;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar carta: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(cardSearchResultsProvider);
    final isLoading = ref.watch(cardSearchIsLoadingProvider);
    final bool isDeckMode = widget.deck != null;

    return Scaffold(
      appBar: isDeckMode
          ? AppBar(title: Text('Adicionar a: ${widget.deck!.name}'))
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                labelText: 'Buscar carta...',
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
