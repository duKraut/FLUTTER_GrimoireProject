import 'package:dio/dio.dart';
import 'package:flutter_grimoire/models/scryfall_card.dart';

class ScryfallService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.scryfall.com',
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  );

  Future<List<ScryfallCard>> searchCards(
    String query, {
    bool isCommanderSearch = false,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    String searchQuery = query;
    if (isCommanderSearch) {
      searchQuery += ' is:commander';
    }

    try {
      final response = await _dio.get(
        '/cards/search',
        queryParameters: {'q': searchQuery},
      );

      if (response.statusCode == 200) {
        final List<dynamic> cardList = response.data['data'];
        return cardList
            .map((json) => ScryfallCard.fromScryfallJson(json))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Erro no Dio: $e');
      return [];
    } catch (e) {
      print('Erro desconhecido: $e');
      return [];
    }
  }
}
