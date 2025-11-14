import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/models/deck.dart';
import 'package:flutter_grimoire/models/deck_card.dart';
import 'package:flutter_grimoire/models/collection_card.dart'; // <-- IMPORTAR NOVO MODELO

final deckListProvider = StreamProvider<List<Deck>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks')
      .orderBy('name');

  return collectionRef.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Deck.fromFirestore(doc)).toList();
  });
});

final deckCardsProvider = StreamProvider.family<List<DeckCard>, String>((
  ref,
  deckId,
) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks')
      .doc(deckId)
      .collection('cards')
      .orderBy('name');

  return collectionRef.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => DeckCard.fromFirestore(doc)).toList();
  });
});

// ***** LÓGICA ATUALIZADA AQUI *****
// Agora retorna <List<CollectionCard>> e usa CollectionCard.fromFirestore
final collectionProvider = StreamProvider<List<CollectionCard>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('collection')
      .orderBy('name');

  return collectionRef.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => CollectionCard.fromFirestore(doc))
        .toList();
  });
});
// ***** FIM DA ATUALIZAÇÃO *****

final deckDetailProvider = StreamProvider.family<Deck, String>((ref, deckId) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    throw Exception('Usuário não autenticado.');
  }

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks')
      .doc(deckId);

  return docRef.snapshots().map((snapshot) {
    if (!snapshot.exists) {
      throw Exception('Deck não encontrado.');
    }
    return Deck.fromFirestore(snapshot);
  });
});

final sideboardCountProvider = StreamProvider.family<int, String>((
  ref,
  deckId,
) {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    return Stream.value(0);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks')
      .doc(deckId)
      .collection('cards');

  return collectionRef.snapshots().map((snapshot) {
    int total = 0;
    for (var doc in snapshot.docs) {
      total += (doc.data()['sideboardQuantity'] ?? 0) as int;
    }
    return total;
  });
});
