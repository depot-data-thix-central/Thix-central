import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_models.dart';

class TaskService {
  final SupabaseClient _client;

  TaskService(this._client);

  /// Create a collaborative task
  Future<CollaborativeTask> createTask({
    required String conversationId,
    required String title,
    String? description,
    String? assignedTo,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _client
          .from('collaborative_tasks')
          .insert({
            'conversation_id': conversationId,
            'created_by': userId,
            'title': title,
            'description': description,
            'assigned_to': assignedTo,
            'priority': priority,
            'due_date': dueDate?.toIso8601String(),
            'status': 'pending',
          })
          .select()
          .single();

      return CollaborativeTask.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Update task
  Future<CollaborativeTask> updateTask({
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    String? status,
    DateTime? dueDate,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (title != null) updates['title'] = title;
      if (description != null) updates['description'] = description;
      if (assignedTo != null) updates['assigned_to'] = assignedTo;
      if (priority != null) updates['priority'] = priority;
      if (status != null) updates['status'] = status;
      if (dueDate != null) updates['due_date'] = dueDate.toIso8601String();
      if (status == 'completed') updates['completed_at'] = DateTime.now().toIso8601String();

      final response = await _client
          .from('collaborative_tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      return CollaborativeTask.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Get tasks for conversation
  Future<List<CollaborativeTask>> getTasks(String conversationId) async {
    try {
      final response = await _client
          .from('collaborative_tasks')
          .select()
          .eq('conversation_id', conversationId)
          .order('due_date', ascending: true);

      return (response as List).map((t) => CollaborativeTask.fromJson(t as Map<String, dynamic>)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Delete task
  Future<void> deleteTask(String taskId) async {
    try {
      await _client.from('collaborative_tasks').delete().eq('id', taskId);
    } catch (e) {
      rethrow;
    }
  }
}
