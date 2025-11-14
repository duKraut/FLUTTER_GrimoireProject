import 'package:cloud_firestore/cloud_firestore.dart';

class CollectionCard {
  final String id;
  final String name;
  final String typeLine;
  final String? imageUrlSmall;
  final String? artCrop;
  final int quantity;

  CollectionCard({
    required this.id,
    required this.name,
    required this.typeLine,
    this.imageUrlSmall,
    this.artCrop,
    required this.quantity,
  });

  factory CollectionCard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return CollectionCard(
      id: doc.id,
      name: data['name'] ?? 'Carta Sem Nome',
      typeLine: data['typeLine'] ?? 'N/D',
      imageUrlSmall: data['imageUrlSmall'],
      artCrop: data['artCrop'],
      quantity: data['quantity'] ?? 0,
    );
  }
}
