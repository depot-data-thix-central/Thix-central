import 'package:flutter/foundation.dart';

/// Enum for message types
enum MessageType {
  text('text'),
  voice('voice'),
  video('video'),
  image('image'),
  document('document'),
  contact('contact');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.text,
    );
  }
}

/// Enum for message read status
enum ReadStatus {
  sent('sent'),
  delivered('delivered'),
  read('read');

  final String value;
  const ReadStatus(this.value);

  static ReadStatus fromString(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReadStatus.sent,
    );
  }
}

/// Enum for user roles in groups
enum UserRole {
  admin('admin'),
  moderator('moderator'),
  member('member');

  final String value;
  const UserRole(this.value);

  static UserRole fromString(String value) {
    return values.firstWhere(
      (e) => e.value == value,
      orElse: () => UserRole.member,
    );
  }
}

/// Conversation model
class Conversation {
  final String id;
  final String? name;
  final bool isGroup;
  final String? description;
  final String? avatarUrl;
  final String createdById;
  final DateTime createdAt;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    this.name,
    required this.isGroup,
    this.description,
    this.avatarUrl,
    required this.createdById,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      name: json['name'] as String?,
      isGroup: json['is_group'] as bool? ?? false,
      description: json['description'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdById: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_group': isGroup,
    'description': description,
    'avatar_url': avatarUrl,
    'created_by': createdById,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  Conversation copyWith({
    String? id,
    String? name,
    bool? isGroup,
    String? description,
    String? avatarUrl,
    String? createdById,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      name: name ?? this.name,
      isGroup: isGroup ?? this.isGroup,
      description: description ?? this.description,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdById: createdById ?? this.createdById,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Conversation participant model
class ConversationParticipant {
  final String id;
  final String conversationId;
  final String userId;
  final UserRole role;
  final DateTime joinedAt;
  final DateTime? archivedAt;
  final DateTime? mutedUntil;
  final String? customName;

  ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.archivedAt,
    this.mutedUntil,
    this.customName,
  });

  factory ConversationParticipant.fromJson(Map<String, dynamic> json) {
    return ConversationParticipant(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      userId: json['user_id'] as String,
      role: UserRole.fromString(json['role'] as String? ?? 'member'),
      joinedAt: DateTime.parse(json['joined_at'] as String),
      archivedAt: json['archived_at'] != null ? DateTime.parse(json['archived_at'] as String) : null,
      mutedUntil: json['muted_until'] != null ? DateTime.parse(json['muted_until'] as String) : null,
      customName: json['custom_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'user_id': userId,
    'role': role.value,
    'joined_at': joinedAt.toIso8601String(),
    'archived_at': archivedAt?.toIso8601String(),
    'muted_until': mutedUntil?.toIso8601String(),
    'custom_name': customName,
  };
}

/// Message model
class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String? content;
  final MessageType messageType;
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final bool isEdited;
  final String? replyToId;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.content,
    required this.messageType,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.isEdited = false,
    this.replyToId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      content: json['content'] as String?,
      messageType: MessageType.fromString(json['message_type'] as String? ?? 'text'),
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSize: json['file_size'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      isEdited: json['is_edited'] as bool? ?? false,
      replyToId: json['reply_to_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'sender_id': senderId,
    'content': content,
    'message_type': messageType.value,
    'file_url': fileUrl,
    'file_name': fileName,
    'file_size': fileSize,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'deleted_at': deletedAt?.toIso8601String(),
    'is_edited': isEdited,
    'reply_to_id': replyToId,
  };

  Message copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    MessageType? messageType,
    String? fileUrl,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
    bool? isEdited,
    String? replyToId,
  }) {
    return Message(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      isEdited: isEdited ?? this.isEdited,
      replyToId: replyToId ?? this.replyToId,
    );
  }
}

/// Read receipt model
class ReadReceipt {
  final String id;
  final String messageId;
  final String userId;
  final ReadStatus status;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.status,
    this.deliveredAt,
    this.readAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      status: ReadStatus.fromString(json['status'] as String? ?? 'sent'),
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at'] as String) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_id': messageId,
    'user_id': userId,
    'status': status.value,
    'delivered_at': deliveredAt?.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Message reaction model
class MessageReaction {
  final String id;
  final String messageId;
  final String userId;
  final String emoji;
  final DateTime createdAt;

  MessageReaction({
    required this.id,
    required this.messageId,
    required this.userId,
    required this.emoji,
    required this.createdAt,
  });

  factory MessageReaction.fromJson(Map<String, dynamic> json) {
    return MessageReaction(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      userId: json['user_id'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_id': messageId,
    'user_id': userId,
    'emoji': emoji,
    'created_at': createdAt.toIso8601String(),
  };
}

/// User presence model
class UserPresence {
  final String userId;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime updatedAt;

  UserPresence({
    required this.userId,
    required this.isOnline,
    this.lastSeenAt,
    required this.updatedAt,
  });

  factory UserPresence.fromJson(Map<String, dynamic> json) {
    return UserPresence(
      userId: json['user_id'] as String,
      isOnline: json['is_online'] as bool? ?? false,
      lastSeenAt: json['last_seen_at'] != null ? DateTime.parse(json['last_seen_at'] as String) : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt?.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Poll model
class Poll {
  final String id;
  final String messageId;
  final String question;
  final String createdBy;
  final bool isAnonymous;
  final bool allowMultiple;
  final DateTime createdAt;
  final DateTime? closedAt;
  final List<PollOption> options;
  final int totalVotes;

  Poll({
    required this.id,
    required this.messageId,
    required this.question,
    required this.createdBy,
    required this.isAnonymous,
    required this.allowMultiple,
    required this.createdAt,
    this.closedAt,
    required this.options,
    this.totalVotes = 0,
  });

  factory Poll.fromJson(Map<String, dynamic> json) {
    return Poll(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      question: json['question'] as String,
      createdBy: json['created_by'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      allowMultiple: json['allow_multiple'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at'] as String) : null,
      options: (json['options'] as List<dynamic>?)?.map((o) => PollOption.fromJson(o as Map<String, dynamic>)).toList() ?? [],
      totalVotes: json['total_votes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'message_id': messageId,
    'question': question,
    'created_by': createdBy,
    'is_anonymous': isAnonymous,
    'allow_multiple': allowMultiple,
    'created_at': createdAt.toIso8601String(),
    'closed_at': closedAt?.toIso8601String(),
    'options': options.map((o) => o.toJson()).toList(),
    'total_votes': totalVotes,
  };
}

/// Poll option model
class PollOption {
  final String id;
  final String pollId;
  final String optionText;
  final int position;
  final int voteCount;
  final DateTime createdAt;

  PollOption({
    required this.id,
    required this.pollId,
    required this.optionText,
    required this.position,
    this.voteCount = 0,
    required this.createdAt,
  });

  factory PollOption.fromJson(Map<String, dynamic> json) {
    return PollOption(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      optionText: json['option_text'] as String,
      position: json['position'] as int,
      voteCount: json['vote_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'poll_id': pollId,
    'option_text': optionText,
    'position': position,
    'vote_count': voteCount,
    'created_at': createdAt.toIso8601String(),
  };
}

/// Collaborative task model
class CollaborativeTask {
  final String id;
  final String conversationId;
  final String createdBy;
  final String title;
  final String? description;
  final String? assignedTo;
  final String priority; // 'low', 'medium', 'high'
  final String status; // 'pending', 'in_progress', 'completed'
  final DateTime? dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  CollaborativeTask({
    required this.id,
    required this.conversationId,
    required this.createdBy,
    required this.title,
    this.description,
    this.assignedTo,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  factory CollaborativeTask.fromJson(Map<String, dynamic> json) {
    return CollaborativeTask(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedTo: json['assigned_to'] as String?,
      priority: json['priority'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'pending',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'conversation_id': conversationId,
    'created_by': createdBy,
    'title': title,
    'description': description,
    'assigned_to': assignedTo,
    'priority': priority,
    'status': status,
    'due_date': dueDate?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
  };

  CollaborativeTask copyWith({
    String? id,
    String? conversationId,
    String? createdBy,
    String? title,
    String? description,
    String? assignedTo,
    String? priority,
    String? status,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return CollaborativeTask(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
