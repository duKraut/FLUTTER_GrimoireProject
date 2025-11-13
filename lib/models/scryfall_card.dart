class ScryfallCard {
  final String id;
  final String name;
  final String typeLine;
  final String? oracleText;
  final String? imageUrlNormal;
  final String? imageUrlSmall;
  final String? artCrop;

  ScryfallCard({
    required this.id,
    required this.name,
    required this.typeLine,
    this.oracleText,
    this.imageUrlNormal,
    this.imageUrlSmall,
    this.artCrop,
  });

  factory ScryfallCard.fromScryfallJson(Map<String, dynamic> json) {
    String? imgNormal, imgSmall, imgArtCrop;

    if (json.containsKey('image_uris')) {
      imgNormal = json['image_uris']['normal'];
      imgSmall = json['image_uris']['small'];
      imgArtCrop = json['image_uris']['art_crop'];
    } else if (json.containsKey('card_faces')) {
      imgNormal = json['card_faces'][0]['image_uris']?['normal'];
      imgSmall = json['card_faces'][0]['image_uris']?['small'];
      imgArtCrop = json['card_faces'][0]['image_uris']?['art_crop'];
    }

    return ScryfallCard(
      id: json['id'],
      name: json['name'],
      typeLine: json['type_line'] ?? '',
      oracleText: json['oracle_text'],
      imageUrlNormal: imgNormal,
      imageUrlSmall: imgSmall,
      artCrop: imgArtCrop,
    );
  }
}
