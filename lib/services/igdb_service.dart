import 'dart:convert';
import 'package:http/http.dart' as http;

class IGDBService {

  final String clientId = "SEU_CLIENT_ID";
  final String token = "SEU_ACCESS_TOKEN";

  Future<List<dynamic>> searchGames(String query) async {

    final response = await http.post(
      Uri.parse("https://api.igdb.com/v4/games"),
      headers: {
        "Client-ID": clientId,
        "Authorization": "Bearer $token",
      },
      body: '''
      search "$query";
      fields name, cover.url, rating, first_release_date;
      limit 10;
      '''
    );

    return jsonDecode(response.body);
  }
}