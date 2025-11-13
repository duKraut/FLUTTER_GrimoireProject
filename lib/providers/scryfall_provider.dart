import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_grimoire/api/scryfall_service.dart';
import 'package:flutter_grimoire/models/scryfall_card.dart';
import 'package:flutter_riverpod/legacy.dart';

final scryfallServiceProvider = Provider((ref) => ScryfallService());

final cardSearchResultsProvider = StateProvider.autoDispose<List<ScryfallCard>>(
  (ref) => [],
);
final cardSearchIsLoadingProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
