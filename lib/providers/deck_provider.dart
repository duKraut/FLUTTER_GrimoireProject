import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/models/deck.dart';

final deckListProvider = StreamProvider<List<Deck>>((ref) {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return Stream.value([]);
  }

  final collectionRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('decks');

  return collectionRef.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => Deck.fromFirestore(doc)).toList();
  });
});
