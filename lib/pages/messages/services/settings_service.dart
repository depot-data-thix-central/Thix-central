import 'package:supabase_flutter/supabase_flutter.dart';

class ChatSettingsModel {
  final String userId;
  final String theme; // 'light', 'dark', 'system'
  final String notificationPriority; // 'all', 'mentions_only', 'none'
  final TimeOfDay? silentHoursStart;
  final TimeOfDay? silentHoursEnd;
  final bool dataSaverEnabled;
  final bool wifiOnlyMedia;
  final bool autoTranslateEnabled;
  final String translateToLanguage;

  ChatSettingsModel({
    required this.userId,
    required this.theme,
    required this.notificationPriority,
    this.silentHoursStart,
    this.silentHoursEnd,
    required this.dataSaverEnabled,
    required this.wifiOnlyMedia,
    required this.autoTranslateEnabled,
    required this.translateToLanguage,
  });

  factory ChatSettingsModel.fromJson(Map<String, dynamic> json) {
    return ChatSettingsModel(
      userId: json['user_id'] as String,
      theme: json['theme'] as String? ?? 'system',
      notificationPriority: json['notification_priority'] as String? ?? 'all',
      silentHoursStart: json['silent_hours_start'] != null
          ? _parseTimeOfDay(json['silent_hours_start'] as String)
          : null,
      silentHoursEnd: json['silent_hours_end'] != null
          ? _parseTimeOfDay(json['silent_hours_end'] as String)
          : null,
      dataSaverEnabled: json['data_saver_enabled'] as bool? ?? false,
      wifiOnlyMedia: json['wifi_only_media'] as bool? ?? false,
      autoTranslateEnabled: json['auto_translate_enabled'] as bool? ?? false,
      translateToLanguage: json['translate_to_language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'theme': theme,
    'notification_priority': notificationPriority,
    'silent_hours_start': silentHoursStart != null ? _timeOfDayToString(silentHoursStart!) : null,
    'silent_hours_end': silentHoursEnd != null ? _timeOfDayToString(silentHoursEnd!) : null,
    'data_saver_enabled': dataSaverEnabled,
    'wifi_only_media': wifiOnlyMedia,
    'auto_translate_enabled': autoTranslateEnabled,
    'translate_to_language': translateToLanguage,
  };

  static TimeOfDay _parseTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

class ConversationSettingsModel {
  final String conversationId;
  final String? customWallpaperUrl;
  final String? bubbleColor;
  final String bubbleShape; // 'rounded', 'sharp'
  final double bubbleOpacity;
  final String? customNotificationSound;
  final bool isEncrypted;
  final bool pinProtected;

  ConversationSettingsModel({
    required this.conversationId,
    this.customWallpaperUrl,
    this.bubbleColor,
    required this.bubbleShape,
    required this.bubbleOpacity,
    this.customNotificationSound,
    required this.isEncrypted,
    required this.pinProtected,
  });

  factory ConversationSettingsModel.fromJson(Map<String, dynamic> json) {
    return ConversationSettingsModel(
      conversationId: json['conversation_id'] as String,
      customWallpaperUrl: json['custom_wallpaper_url'] as String?,
      bubbleColor: json['bubble_color'] as String?,
      bubbleShape: json['bubble_shape'] as String? ?? 'rounded',
      bubbleOpacity: (json['bubble_opacity'] as num?)?.toDouble() ?? 1.0,
      customNotificationSound: json['custom_notification_sound'] as String?,
      isEncrypted: json['is_encrypted'] as bool? ?? false,
      pinProtected: json['pin_protected'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'custom_wallpaper_url': customWallpaperUrl,
    'bubble_color': bubbleColor,
    'bubble_shape': bubbleShape,
    'bubble_opacity': bubbleOpacity,
    'custom_notification_sound': customNotificationSound,
    'is_encrypted': isEncrypted,
    'pin_protected': pinProtected,
  };
}

class ChatSettingsService {
  final SupabaseClient _client;

  ChatSettingsService(this._client);

  /// Get user's chat settings
  Future<ChatSettingsModel> getSettings() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client.from('chat_settings').select().eq('user_id', userId).maybeSingle();

      if (response == null) {
        // Create default settings
        return await _createDefaultSettings(userId);
      }

      return ChatSettingsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update chat settings
  Future<ChatSettingsModel> updateSettings({
    String? theme,
    String? notificationPriority,
    TimeOfDay? silentHoursStart,
    TimeOfDay? silentHoursEnd,
    bool? dataSaverEnabled,
    bool? wifiOnlyMedia,
    bool? autoTranslateEnabled,
    String? translateToLanguage,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (theme != null) updates['theme'] = theme;
      if (notificationPriority != null) updates['notification_priority'] = notificationPriority;
      if (silentHoursStart != null) updates['silent_hours_start'] = ChatSettingsModel._timeOfDayToString(silentHoursStart);
      if (silentHoursEnd != null) updates['silent_hours_end'] = ChatSettingsModel._timeOfDayToString(silentHoursEnd);
      if (dataSaverEnabled != null) updates['data_saver_enabled'] = dataSaverEnabled;
      if (wifiOnlyMedia != null) updates['wifi_only_media'] = wifiOnlyMedia;
      if (autoTranslateEnabled != null) updates['auto_translate_enabled'] = autoTranslateEnabled;
      if (translateToLanguage != null) updates['translate_to_language'] = translateToLanguage;

      final response = await _client
          .from('chat_settings')
          .update(updates)
          .eq('user_id', userId)
          .select()
          .single();

      return ChatSettingsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatSettingsModel> _createDefaultSettings(String userId) async {
    try {
      final response = await _client
          .from('chat_settings')
          .insert({
            'user_id': userId,
            'theme': 'system',
            'notification_priority': 'all',
            'data_saver_enabled': false,
            'wifi_only_media': false,
            'auto_translate_enabled': false,
            'translate_to_language': 'en',
          })
          .select()
          .single();

      return ChatSettingsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }
}

class ConversationSettingsService {
  final SupabaseClient _client;

  ConversationSettingsService(this._client);

  /// Get conversation settings
  Future<ConversationSettingsModel?> getSettings(String conversationId) async {
    try {
      final response = await _client
          .from('conversation_settings')
          .select()
          .eq('conversation_id', conversationId)
          .maybeSingle();

      return response != null ? ConversationSettingsModel.fromJson(response as Map<String, dynamic>) : null;
    } catch (e) {
      rethrow;
    }
  }

  /// Update conversation settings
  Future<ConversationSettingsModel> updateSettings({
    required String conversationId,
    String? customWallpaperUrl,
    String? bubbleColor,
    String? bubbleShape,
    double? bubbleOpacity,
    String? customNotificationSound,
    bool? isEncrypted,
    bool? pinProtected,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (customWallpaperUrl != null) updates['custom_wallpaper_url'] = customWallpaperUrl;
      if (bubbleColor != null) updates['bubble_color'] = bubbleColor;
      if (bubbleShape != null) updates['bubble_shape'] = bubbleShape;
      if (bubbleOpacity != null) updates['bubble_opacity'] = bubbleOpacity;
      if (customNotificationSound != null) updates['custom_notification_sound'] = customNotificationSound;
      if (isEncrypted != null) updates['is_encrypted'] = isEncrypted;
      if (pinProtected != null) updates['pin_protected'] = pinProtected;

      final response = await _client
          .from('conversation_settings')
          .upsert({
            'conversation_id': conversationId,
            ...updates,
          })
          .select()
          .single();

      return ConversationSettingsModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Toggle mute for conversation
  Future<void> toggleMute({
    required String conversationId,
    required DateTime? mutedUntil,
  }) async {
    try {
      await _client
          .from('conversation_participants')
          .update({'muted_until': mutedUntil?.toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', _client.auth.currentUser?.id);
    } catch (e) {
      rethrow;
    }
  }
}
