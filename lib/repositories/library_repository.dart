import '../services/supabase_service.dart';

class LibraryRepository {

  final client = SupabaseService.client;

  Future<void> addGame({
    required String userId,
    required int gameId,
    required String status,
  }) async {

    await client.from('user_games').insert({
      'user_id': userId,
      'game_id': gameId,
      'status': status
    });
  }

  Future<List<dynamic>> getUserGames(String userId) async {

    return await client
        .from('user_games')
        .select()
        .eq('user_id', userId);
  }
}