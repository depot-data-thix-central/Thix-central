import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';
import '../services/chat_service.dart';
import '../services/poll_service.dart';
import '../services/task_service.dart';

// Service providers
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final chatServiceProvider = Provider<ChatService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ChatService(client);
});

final pollServiceProvider = Provider<PollService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PollService(client);
});

final taskServiceProvider = Provider<TaskService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TaskService(client);
});

// Conversations
final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.getConversations();
});

final conversationByIdProvider = FutureProvider.autoDispose.family<Conversation?, String>((ref, conversationId) async {
  final chatService = ref.watch(chatServiceProvider);
  final conversations = await ref.watch(conversationsProvider.future);
  return conversations.firstWhere(
    (c) => c.id == conversationId,
    orElse: () => throw Exception('Conversation not found'),
  );
});

// Messages
final messagesStreamProvider = StreamProvider.autoDispose.family<List<Message>, String>(
  (ref, conversationId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.messagesStream(conversationId);
  },
);

// Read receipts
final readReceiptsProvider = FutureProvider.autoDispose.family<List<ReadReceipt>, String>(
  (ref, messageId) async {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getReadReceipts(messageId);
  },
);

// Reactions
final reactionsProvider = FutureProvider.autoDispose.family<List<MessageReaction>, String>(
  (ref, messageId) async {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getReactions(messageId);
  },
);

// Typing indicator
final typingIndicatorProvider = StreamProvider.autoDispose.family<List<String>, String>(
  (ref, conversationId) {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.typingIndicatorStream(conversationId);
  },
);

// User presence
final userPresenceProvider = FutureProvider.autoDispose.family<UserPresence?, String>(
  (ref, userId) async {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getUserPresence(userId);
  },
);

// Conversation participants
final conversationParticipantsProvider = FutureProvider.autoDispose.family<List<ConversationParticipant>, String>(
  (ref, conversationId) async {
    final chatService = ref.watch(chatServiceProvider);
    return chatService.getParticipants(conversationId);
  },
);

// Tasks
final conversationTasksProvider = FutureProvider.autoDispose.family<List<CollaborativeTask>, String>(
  (ref, conversationId) async {
    final taskService = ref.watch(taskServiceProvider);
    return taskService.getTasks(conversationId);
  },
);

// State notifiers for complex operations
final selectedConversationProvider = StateProvider<String?>((ref) => null);
final typingUsersProvider = StateProvider.family<Set<String>, String>((ref, conversationId) => {});

// Invalidate providers after mutations
final messageInvalidatorProvider = Provider((ref) {
  return (String conversationId) {
    ref.refresh(messagesStreamProvider(conversationId));
  };
});

final conversationsInvalidatorProvider = Provider((ref) {
  return () {
    ref.refresh(conversationsProvider);
  };
});
