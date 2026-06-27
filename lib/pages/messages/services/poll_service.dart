import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class PollService {
  final SupabaseClient _client;

  PollService(this._client);

  /// Create a poll
  Future<Poll> createPoll({
    required String messageId,
    required String question,
    required List<String> options,
    bool isAnonymous = false,
    bool allowMultiple = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final pollResponse = await _client
          .from('polls')
          .insert({
            'message_id': messageId,
            'question': question,
            'created_by': userId,
            'is_anonymous': isAnonymous,
            'allow_multiple': allowMultiple,
          })
          .select()
          .single();

      final pollId = pollResponse['id'] as String;

      // Add options
      final optionsList = List.generate(
        options.length,
        (index) => {
          'poll_id': pollId,
          'option_text': options[index],
          'position': index,
        },
      );

      await _client.from('poll_options').insert(optionsList);

      return Poll.fromJson(pollResponse as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Vote on poll option
  Future<void> votePoll({
    required String pollId,
    required String optionId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('poll_votes').insert({
        'poll_id': pollId,
        'option_id': optionId,
        'voted_by': userId,
      }).onError((error, stackTrace) {
        // Vote already exists, ignore
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get poll with results
  Future<Poll> getPoll(String pollId) async {
    try {
      final response = await _client
          .from('polls')
          .select(
            '''id, message_id, question, created_by, is_anonymous, allow_multiple, created_at, closed_at,
            poll_options(id, option_text, position)'''
          )
          .eq('id', pollId)
          .single();

      return Poll.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Close poll
  Future<void> closePoll(String pollId) async {
    try {
      await _client.from('polls').update({'closed_at': DateTime.now().toIso8601String()}).eq('id', pollId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get votes for option
  Future<int> getOptionVoteCount(String optionId) async {
    try {
      final response = await _client
          .from('poll_votes')
          .select()
          .eq('option_id', optionId);

      return (response as List).length;
    } catch (e) {
      rethrow;
    }
  }
}
