import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class MediaService {
  final SupabaseClient _client;
  static const uuid = Uuid();

  MediaService(this._client);

  /// Upload image to storage
  Future<String> uploadImage(File imageFile) async {
    try {
      final fileName = '${uuid.v4()}_${imageFile.path.split('/').last}';
      final bytes = await imageFile.readAsBytes();

      await _client.storage.from('chat-media').uploadBinary(
        'images/$fileName',
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600'),
      );

      final publicUrl = _client.storage.from('chat-media').getPublicUrl('images/$fileName');
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload video to storage
  Future<String> uploadVideo(File videoFile) async {
    try {
      final fileName = '${uuid.v4()}_${videoFile.path.split('/').last}';
      final bytes = await videoFile.readAsBytes();

      await _client.storage.from('chat-media').uploadBinary(
        'videos/$fileName',
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600'),
      );

      final publicUrl = _client.storage.from('chat-media').getPublicUrl('videos/$fileName');
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload document to storage
  Future<String> uploadDocument(File documentFile) async {
    try {
      final fileName = '${uuid.v4()}_${documentFile.path.split('/').last}';
      final bytes = await documentFile.readAsBytes();

      await _client.storage.from('chat-media').uploadBinary(
        'documents/$fileName',
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600'),
      );

      final publicUrl = _client.storage.from('chat-media').getPublicUrl('documents/$fileName');
      return publicUrl;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideo() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
      return pickedFile != null ? File(pickedFile.path) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Compress image
  Future<File?> compressImage(File imageFile, {int quality = 80}) async {
    try {
      // In a real implementation, use flutter_image_compress or similar
      // For now, just return the original file
      return imageFile;
    } catch (e) {
      rethrow;
    }
  }

  /// Get file size in MB
  static double getFileSizeInMB(int bytes) {
    return bytes / (1024 * 1024);
  }

  /// Format file size for display
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Check if file should be downloaded (respecting data saver mode)
  static bool shouldDownloadFile(bool dataSaverMode, bool wifiOnly, double fileSizeInMB) {
    if (!dataSaverMode) return true;
    if (fileSizeInMB > 10 && wifiOnly) return false; // Large files only on WiFi
    return true;
  }
}

class VoiceMessageService {
  // Placeholder for voice recording service
  // In implementation, integrate with flutter_sound or audio_waveforms

  /// Start recording voice message
  Future<void> startRecording(String conversationId) async {
    // Record audio
  }

  /// Stop recording and upload
  Future<String?> stopRecordingAndUpload(
    String conversationId,
    SupabaseClient client,
  ) async {
    // Stop recording and upload to storage
    return null;
  }

  /// Play voice message
  Future<void> playVoiceMessage(String url) async {
    // Play audio from URL
  }

  /// Cancel recording
  Future<void> cancelRecording() async {
    // Cancel ongoing recording
  }
}

class TranslationService {
  final SupabaseClient _client;

  TranslationService(this._client);

  /// Translate message content
  Future<String> translateMessage({
    required String content,
    required String targetLanguage,
  }) async {
    try {
      // Call Supabase Edge Function for translation
      final response = await _client.functions.invoke(
        'translate-message',
        body: {
          'content': content,
          'targetLanguage': targetLanguage,
        },
      );

      return response['translatedText'] as String? ?? content;
    } catch (e) {
      // Fallback to original content if translation fails
      return content;
    }
  }

  /// Transcribe voice message
  Future<String?> transcribeVoiceMessage(String audioUrl) async {
    try {
      // Call Supabase Edge Function for transcription
      final response = await _client.functions.invoke(
        'transcribe-audio',
        body: {
          'audioUrl': audioUrl,
        },
      );

      return response['transcription'] as String?;
    } catch (e) {
      return null;
    }
  }
}

class NotificationService {
  // Placeholder for notification service
  // In implementation, integrate Firebase Cloud Messaging

  /// Request notification permission
  Future<bool> requestPermission() async {
    // Request permission from user
    return true;
  }

  /// Register FCM token
  Future<void> registerFCMToken(String userId, SupabaseClient client) async {
    // Get FCM token and store in database
  }

  /// Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Show local notification
  }

  /// Handle notification tap
  void handleNotificationTap(String? payload) {
    // Navigate to conversation or message
  }
}

class SearchService {
  final SupabaseClient _client;

  SearchService(this._client);

  /// Search messages in conversation
  Future<List<Map<String, dynamic>>> searchMessages({
    required String conversationId,
    required String query,
    int limit = 20,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .textSearch('content', query)
          .limit(limit)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      rethrow;
    }
  }

  /// Search messages by date range
  Future<List<Map<String, dynamic>>> searchMessagesByDate({
    required String conversationId,
    required DateTime startDate,
    required DateTime endDate,
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .gte('created_at', startDate.toIso8601String())
          .lte('created_at', endDate.toIso8601String())
          .limit(limit)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      rethrow;
    }
  }

  /// Search messages by type
  Future<List<Map<String, dynamic>>> searchMessagesByType({
    required String conversationId,
    required String messageType, // 'text', 'voice', 'video', 'image', 'document'
    int limit = 50,
  }) async {
    try {
      final response = await _client
          .from('messages')
          .select()
          .eq('conversation_id', conversationId)
          .eq('message_type', messageType)
          .limit(limit)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      rethrow;
    }
  }

  /// Global search across all conversations
  Future<List<Map<String, dynamic>>> globalSearch(String query, {int limit = 50}) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('messages')
          .select('*, conversations(id, name, is_group)')
          .textSearch('content', query)
          .limit(limit)
          .order('created_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      rethrow;
    }
  }
}

class ArchiveService {
  final SupabaseClient _client;

  ArchiveService(this._client);

  /// Archive conversation
  Future<void> archiveConversation(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('conversation_participants')
          .update({'archived_at': DateTime.now().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Unarchive conversation
  Future<void> unarchiveConversation(String conversationId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _client
          .from('conversation_participants')
          .update({'archived_at': null})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Get archived conversations
  Future<List<Map<String, dynamic>>> getArchivedConversations() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('conversation_participants')
          .select('*, conversations(*)')
          .eq('user_id', userId)
          .isNotNull('archived_at')
          .order('archived_at', ascending: false);

      return response as List<Map<String, dynamic>>;
    } catch (e) {
      rethrow;
    }
  }
}

class ExportService {
  /// Export conversation as JSON
  static String exportAsJSON(List<Map<String, dynamic>> messages) {
    return messages.toString(); // In real implementation, use jsonEncode
  }

  /// Export conversation as TXT
  static String exportAsTXT(List<Map<String, dynamic>> messages) {
    final buffer = StringBuffer();
    for (var msg in messages) {
      buffer.writeln('${msg['created_at']}: ${msg['content']}');
    }
    return buffer.toString();
  }

  /// Export conversation as CSV
  static String exportAsCSV(List<Map<String, dynamic>> messages) {
    final buffer = StringBuffer();
    buffer.writeln('timestamp,sender,content,type');
    for (var msg in messages) {
      buffer.writeln('${msg['created_at']},${msg['sender_id']},${msg['content']},${msg['message_type']}');
    }
    return buffer.toString();
  }
}
