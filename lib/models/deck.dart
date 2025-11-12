import 'package:cloud_firestore/cloud_firestore.dart';

class Deck {
  final String id;
  final String name;
  final String format;
  final Timestamp createdAt;

  Deck({
    required this.id,
    required this.name,
    required this.format,
    required this.createdAt,
  });

  factory Deck.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Deck(
      id: doc.id,
      name: data['name'] ?? 'Deck Sem Nome',
      format: data['format'] ?? 'N/D',
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }
}
