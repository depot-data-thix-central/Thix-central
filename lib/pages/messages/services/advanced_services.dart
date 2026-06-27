import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class ScheduledMessageService {
  final SupabaseClient _client;

  ScheduledMessageService(this._client);

  /// Schedule a message to be sent at a specific time
  Future<void> scheduleMessage({
    required String conversationId,
    required String content,
    required DateTime scheduledFor,
    String? recurrence, // 'once', 'daily', 'weekly', 'monthly'
    DateTime? recurrenceEndDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('scheduled_messages').insert({
        'conversation_id': conversationId,
        'sender_id': userId,
        'content': content,
        'message_type': 'text',
        'scheduled_for': scheduledFor.toIso8601String(),
        'recurrence': recurrence ?? 'once',
        'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
        'is_active': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a scheduled message
  Future<void> cancelScheduledMessage(String messageId) async {
    try {
      await _client.from('scheduled_messages').update({'is_active': false}).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }
}

class EphemeralMessageService {
  final SupabaseClient _client;

  EphemeralMessageService(this._client);

  /// Send an ephemeral message that auto-deletes
  Future<void> sendEphemeralMessage({
    required String conversationId,
    required String content,
    required int durationSeconds,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final messageResponse = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': 'text',
          })
          .select()
          .single();

      await _client.from('ephemeral_messages').insert({
        'message_id': messageResponse['id'],
        'duration_seconds': durationSeconds,
        'expires_at': DateTime.now().add(Duration(seconds: durationSeconds)).toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }
}

class ConfidentialMessageService {
  final SupabaseClient _client;

  ConfidentialMessageService(this._client);

  /// Send a confidential message protected with PIN
  Future<void> sendConfidentialMessage({
    required String conversationId,
    required String content,
    required String pinHash,
    bool biometricRequired = false,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final messageResponse = await _client
          .from('messages')
          .insert({
            'conversation_id': conversationId,
            'sender_id': userId,
            'content': content,
            'message_type': 'text',
          })
          .select()
          .single();

      await _client.from('confidential_messages').insert({
        'message_id': messageResponse['id'],
        'pin_hash': pinHash,
        'biometric_required': biometricRequired,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Record access to confidential message
  Future<void> recordAccess(String messageId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final current = await _client
          .from('confidential_messages')
          .select('accessed_by')
          .eq('message_id', messageId)
          .single();

      final accessedBy = (current['accessed_by'] as List<dynamic>? ?? []).cast<String>();
      if (!accessedBy.contains(userId)) {
        accessedBy.add(userId);
      }

      await _client.from('confidential_messages').update({'accessed_by': accessedBy}).eq('message_id', messageId);
    } catch (e) {
      rethrow;
    }
  }
}

class MessageReminderService {
  final SupabaseClient _client;

  MessageReminderService(this._client);

  /// Set a reminder for a message
  Future<void> setReminder({
    required String messageId,
    required DateTime remindAt,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('message_reminders').insert({
        'message_id': messageId,
        'user_id': userId,
        'remind_at': remindAt.toIso8601String(),
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get reminders for user
  Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      return await _client
          .from('message_reminders')
          .select('*, messages(*)')
          .eq('user_id', userId)
          .eq('is_sent', false)
          .lt('remind_at', DateTime.now().toIso8601String());
    } catch (e) {
      rethrow;
    }
  }

  /// Mark reminder as sent
  Future<void> markAsSent(String reminderId) async {
    try {
      await _client.from('message_reminders').update({'is_sent': true}).eq('id', reminderId);
    } catch (e) {
      rethrow;
    }
  }
}

class MessageDraftService {
  final SupabaseClient _client;

  MessageDraftService(this._client);

  /// Save a draft message
  Future<void> saveDraft({
    required String conversationId,
    required String content,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('message_drafts').upsert({
        'conversation_id': conversationId,
        'user_id': userId,
        'content': content,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Get draft for conversation
  Future<String?> getDraft(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('message_drafts')
          .select('content')
          .eq('conversation_id', conversationId)
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? response['content'] as String? : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete draft
  Future<void> deleteDraft(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('message_drafts')
          .delete()
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }
}

class BlockedUserService {
  final SupabaseClient _client;

  BlockedUserService(this._client);

  /// Block a user
  Future<void> blockUser(String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client.from('blocked_users').insert({
        'user_id': currentUserId,
        'blocked_user_id': userId,
      }).onError((error, stackTrace) {
        // Already blocked, ignore
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a user
  Future<void> unblockUser(String userId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await _client
          .from('blocked_users')
          .delete()
          .eq('user_id', currentUserId)
          .eq('blocked_user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get blocked users
  Future<List<String>> getBlockedUsers() async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('blocked_users')
          .select('blocked_user_id')
          .eq('user_id', currentUserId);

      return (response as List).map((r) => r['blocked_user_id'] as String).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Check if user is blocked
  Future<bool> isUserBlocked(String userId) async {
    try {
      final blocked = await getBlockedUsers();
      return blocked.contains(userId);
    } catch (e) {
      rethrow;
    }
  }
}

class ReportedContentService {
  final SupabaseClient _client;

  ReportedContentService(this._client);

  /// Report a message or user
  Future<void> reportContent({
    required String contentType, // 'message', 'user'
    required String contentId,
    required String reason,
    String? description,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('reported_content').insert({
        'content_type': contentType,
        'content_id': contentId,
        'reported_by': userId,
        'reason': reason,
        'description': description,
        'status': 'pending',
      });
    } catch (e) {
      rethrow;
    }
  }
}

class PinnedMessageService {
  final SupabaseClient _client;

  PinnedMessageService(this._client);

  /// Pin a message (admin only)
  Future<void> pinMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client.from('pinned_messages').insert({
        'conversation_id': conversationId,
        'message_id': messageId,
        'pinned_by': userId,
      }).onError((error, stackTrace) {
        // Already pinned, ignore
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Unpin a message
  Future<void> unpinMessage(String messageId) async {
    try {
      await _client.from('pinned_messages').delete().eq('message_id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get pinned messages for conversation
  Future<List<String>> getPinnedMessages(String conversationId) async {
    try {
      final response = await _client
          .from('pinned_messages')
          .select('message_id')
          .eq('conversation_id', conversationId);

      return (response as List).map((r) => r['message_id'] as String).toList();
    } catch (e) {
      rethrow;
    }
  }
}
