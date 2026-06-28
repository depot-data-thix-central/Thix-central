import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ChatService {
  final SupabaseClient _client;

  ChatService(this._client);

  String? get currentUserId => _client.auth.currentUser?.id;

  /// Fetch conversations for current user
  Future<List<Conversation>> getConversations({int limit = 50, int offset = 0}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('conversations')
          .select(
            '''id, name, is_group, description, avatar_url, created_by, created_at, updated_at,
            conversation_participants!inner(user_id)'''
          )
          .eq('conversation_participants.user_id', userId)
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((c) => Conversation.fromJson(c as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new 1-to-1 conversation
  Future<Conversation> createDirectConversation(String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      // Check if conversation already exists
      final existing = await _client
          .from('conversations')
          .select('id')
          .eq('is_group', false)
          .order('created_at', ascending: false);

      for (var conv in existing) {
        final participants = await _client
            .from('conversation_participants')
            .select('user_id')
            .eq('conversation_id', conv['id'] as String);

        final ids = (participants as List).map((p) => p['user_id']).toList();
        if (ids.length == 2 && ids.contains(currentUserId) && ids.contains(userId)) {
          return Conversation.fromJson(conv as Map<String, dynamic>);
        }
      }

      // Create new conversation
      final response = await _client
          .from('conversations')
          .insert({
            'name': null,
            'is_group': false,
            'created_by': currentUserId,
          })
          .select()
          .single();

      final conversationId = response['id'] as String;

      // Add participants
      await _client.from('conversation_participants').insert([
        {'conversation_id': conversationId, 'user_id': currentUserId, 'role': 'member'},
        {'conversation_id': conversationId, 'user_id': userId, 'role': 'member'},
      ]);

      return Conversation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Create a group conversation
  Future<Conversation> createGroupConversation({
    required String name,
    required List<String> memberIds,
    String? description,
    String? avatarUrl,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('conversations')
          .insert({
            'name': name,
            'is_group': true,
            'description': description,
            'avatar_url': avatarUrl,
            'created_by': currentUserId,
          })
          .select()
          .single();

      final conversationId = response['id'] as String;
      final allMembers = [currentUserId, ...memberIds].toSet().toList();

      // Add all participants with creator as admin
      final participants = allMembers.map((userId) => {
        'conversation_id': conversationId,
        'user_id': userId,
        'role': userId == currentUserId ? 'admin' : 'member',
      }).toList();

      await _client.from('conversation_participants').insert(participants);

      return Conversation.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to messages in real-time for a conversation
  Stream<List<Message>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .eq('deleted_at', null)
        .order('created_at')
        .map((rows) => rows.map((row) => Message.fromJson(row as Map<String, dynamic>)).toList());
  }

  /// Send a message
  Future<Message> sendMessage({
    required String conversationId,
    required String content,
    MessageType messageType = MessageType.text,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    String? replyToId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': messageType.value,
            'file_url': fileUrl,
            'file_name': fileName,
            'file_size': fileSize,
            'reply_to_id': replyToId,
          })
          .select()
          .single();

      // Create read receipt for sender
      await _client.from('read_receipts').insert({
        'message_id': response['id'],
        'user_id': userId,
        'status': 'sent',
        'delivered_at': DateTime.now().toIso8601String(),
      });

      return Message.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Edit a message
  Future<Message> editMessage({
    required String messageId,
    required String newContent,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .update({
            'content': newContent,
            'is_edited': true,
          })
          .eq('id', messageId)
          .select()
          .single();

      return Message.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').update({'deleted_at': DateTime.now().toIso8601String()}).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  /// Add reaction to message
  Future<void> addReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('message_reactions').insert({
        'message_id': messageId,
        'user_id': userId,
        'emoji': emoji,
      }).onError((error, stackTrace) {
        // Reaction already exists, ignore
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove reaction from message
  Future<void> removeReaction({
    required String messageId,
    required String emoji,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('message_reactions')
          .delete()
          .eq('message_id', messageId)
          .eq('user_id', userId)
          .eq('emoji', emoji);
    } catch (e) {
      rethrow;
    }
  }

  /// Get reactions for a message
  Future<List<MessageReaction>> getReactions(String messageId) async {
    try {
      final response = await _client.from('message_reactions').select().eq('message_id', messageId);

      return (response as List).map((r) => MessageReaction.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Mark message as read
  Future<void> markAsRead(String messageId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('read_receipts')
          .update({
            'status': 'read',
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('message_id', messageId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get read receipts for a message
  Future<List<ReadReceipt>> getReadReceipts(String messageId) async {
    try {
      final response = await _client.from('read_receipts').select().eq('message_id', messageId);

      return (response as List).map((r) => ReadReceipt.fromJson(r as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Get user presence
  Future<UserPresence?> getUserPresence(String userId) async {
    try {
      final response = await _client.from('user_presence').select().eq('user_id', userId).maybeSingle();

      return response != null ? UserPresence.fromJson(response as Map<String, dynamic>) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update user presence
  Future<void> updateUserPresence({required bool isOnline}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('user_presence').upsert({
        'user_id': userId,
        'is_online': isOnline,
        'last_seen_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to typing indicator
  Stream<List<String>> typingIndicatorStream(String conversationId) {
    return _client
        .from('typing_indicators')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .map((rows) => rows.map((row) => row['user_id'] as String).toList());
  }

  /// Set typing indicator
  Future<void> setTyping(String conversationId, bool isTyping) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (isTyping) {
        await _client.from('typing_indicators').insert({
          'conversation_id': conversationId,
          'user_id': userId,
        }).onError((error, stackTrace) {
          // Already typing, ignore
        });
      } else {
        await _client
            .from('typing_indicators')
            .delete()
            .eq('conversation_id', conversationId)
            .eq('user_id', userId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get conversation participants
  Future<List<ConversationParticipant>> getParticipants(String conversationId) async {
    try {
      final response = await _client
          .from('conversation_participants')
          .select()
          .eq('conversation_id', conversationId);

      return (response as List).map((p) => ConversationParticipant.fromJson(p as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add participant to conversation
  Future<void> addParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client.from('conversation_participants').insert({
        'conversation_id': conversationId,
        'user_id': userId,
        'role': 'member',
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Remove participant from conversation
  Future<void> removeParticipant({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await _client
          .from('conversation_participants')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Update participant role
  Future<void> updateParticipantRole({
    required String conversationId,
    required String userId,
    required UserRole role,
  }) async {
    try {
      await _client
          .from('conversation_participants')
          .update({'role': role.value})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}
