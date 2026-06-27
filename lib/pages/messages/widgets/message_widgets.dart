import 'package:flutter/material.dart';
import '../models/chat_models.dart';

/// Message bubble widget
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isOwn;
  final bool showReactions;
  final List<MessageReaction> reactions;
  final VoidCallback? onReply;
  final VoidCallback? onReact;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isOwn,
    this.showReactions = true,
    this.reactions = const [],
    this.onReply,
    this.onReact,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        child: Column(
          crossAxisAlignment: isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Message bubble
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isOwn ? colorScheme.primary : colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle different message types
                  _buildMessageContent(context, textTheme),
                  const SizedBox(height: 4),
                  // Timestamp and read status
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.createdAt),
                        style: textTheme.labelSmall?.copyWith(
                          color: isOwn ? colorScheme.onPrimary.withOpacity(0.7) : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isOwn) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.done_all, size: 14, color: colorScheme.onPrimary.withOpacity(0.7)),
                      ]
                    ],
                  ),
                ],
              ),
            ),
            // Reactions
            if (showReactions && reactions.isNotEmpty) _buildReactionsRow(context, reactions),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context, TextTheme textTheme) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content ?? '',
          style: textTheme.bodyMedium?.copyWith(
            color: isOwn ? colorScheme.onPrimary : colorScheme.onSurface,
          ),
        );
      case MessageType.voice:
        return _buildVoiceMessage(context);
      case MessageType.video:
        return _buildVideoThumbnail(context);
      case MessageType.image:
        return _buildImageThumbnail(context);
      case MessageType.document:
        return _buildDocumentPreview(context);
      case MessageType.contact:
        return _buildContactCard(context);
    }
  }

  Widget _buildVoiceMessage(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.play_arrow, size: 24, color: Theme.of(context).colorScheme.onPrimary),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            // Waveform would go here
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '0:23',
          style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
        ),
      ],
    );
  }

  Widget _buildVideoThumbnail(BuildContext context) {
    return Container(
      width: 200,
      height: 150,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.play_arrow, size: 48, color: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 200,
        height: 150,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(Icons.image, size: 48, color: Theme.of(context).colorScheme.primary),
      ),
    );
  }

  Widget _buildDocumentPreview(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.description, color: Theme.of(context).colorScheme.onPrimary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message.fileName ?? 'Document',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            Text('${(message.fileSize ?? 0) / 1024 / 1024} MB',
                style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7))),
          ],
        ),
      ],
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.person, color: Theme.of(context).colorScheme.onPrimary),
        const SizedBox(width: 8),
        Text('Contact', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
      ],
    );
  }

  Widget _buildReactionsRow(BuildContext context, List<MessageReaction> reactions) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactions.map((r) {
          final colorScheme = Theme.of(context).colorScheme;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              r.emoji,
              style: const TextStyle(fontSize: 14),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    if (now.difference(dateTime).inMinutes < 1) {
      return 'now';
    } else if (now.difference(dateTime).inHours < 1) {
      return '${now.difference(dateTime).inMinutes}m ago';
    } else if (now.difference(dateTime).inDays < 1) {
      return '${now.difference(dateTime).inHours}h ago';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}

/// Typing indicator widget
class TypingIndicator extends StatefulWidget {
  final List<String> typingUsers;
  final Map<String, String> userNames;

  const TypingIndicator({
    Key? key,
    required this.typingUsers,
    required this.userNames,
  }) : super(key: key);

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.typingUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    final names = widget.typingUsers.map((id) => widget.userNames[id] ?? 'Someone').toList();
    final text = names.length == 1
        ? '${names[0]} is typing...'
        : '${names.take(2).join(', ')} are typing...';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(text, style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(width: 4),
          _TypingDots(animationController: _animationController),
        ],
      ),
    );
  }
}

class _TypingDots extends StatelessWidget {
  final AnimationController animationController;

  const _TypingDots({required this.animationController});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return ScaleTransition(
          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(
              parent: animationController,
              curve: Interval(index * 0.2, 0.6 + index * 0.2, curve: Curves.easeInOut),
            ),
          ),
          child: Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      }),
    );
  }
}

/// Online status indicator
class OnlineStatusIndicator extends StatelessWidget {
  final bool isOnline;
  final DateTime? lastSeenAt;

  const OnlineStatusIndicator({
    Key? key,
    required this.isOnline,
    this.lastSeenAt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: isOnline ? Colors.green : Colors.grey,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isOnline ? 'Online' : _formatLastSeen(lastSeenAt),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatLastSeen(DateTime? dateTime) {
    if (dateTime == null) return 'Offline';
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
