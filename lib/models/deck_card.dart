import 'package:cloud_firestore/cloud_firestore.dart';

class DeckCard {
  final String id;
  final String name;
  final String typeLine;
  final String? imageUrlSmall;
  final String? artCrop;
  final String? imageUrlNormal;
  final List<String> colorIdentity;
  final int mainboardQuantity;
  final int sideboardQuantity;

  DeckCard({
    required this.id,
    required this.name,
    required this.typeLine,
    this.imageUrlSmall,
    this.artCrop,
    this.imageUrlNormal,
    required this.colorIdentity,
    required this.mainboardQuantity,
    required this.sideboardQuantity,
  });

  factory DeckCard.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return DeckCard(
      id: doc.id,
      name: data['name'] ?? 'Carta Sem Nome',
      typeLine: data['typeLine'] ?? 'N/D',
      imageUrlSmall: data['imageUrlSmall'],
      artCrop: data['artCrop'],
      imageUrlNormal: data['imageUrlNormal'],
      colorIdentity: List<String>.from(data['colorIdentity'] ?? []),
      mainboardQuantity: data['mainboardQuantity'] ?? 0,
      sideboardQuantity: data['sideboardQuantity'] ?? 0,
    );
  }
}
