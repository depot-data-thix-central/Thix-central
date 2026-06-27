import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:thix_central/theme.dart';
import '../models/chat_models.dart';
import '../providers/chat_providers.dart';
import '../services/chat_service.dart';
import '../widgets/message_widgets.dart';

class ConversationDetailPage extends ConsumerStatefulWidget {
  final String conversationId;
  final String conversationName;
  final String? avatarUrl;
  final bool isGroup;

  const ConversationDetailPage({
    Key? key,
    required this.conversationId,
    required this.conversationName,
    this.avatarUrl,
    this.isGroup = false,
  }) : super(key: key);

  @override
  ConsumerState<ConversationDetailPage> createState() => _ConversationDetailPageState();
}

class _ConversationDetailPageState extends ConsumerState<ConversationDetailPage> {
  late TextEditingController _messageController;
  bool _isTyping = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _markAsTyping();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _markAsNotTyping();
    super.dispose();
  }

  void _markAsTyping() {
    if (!_isTyping) {
      _isTyping = true;
      ref.read(chatServiceProvider).setTyping(widget.conversationId, true);
    }
  }

  void _markAsNotTyping() {
    if (_isTyping) {
      _isTyping = false;
      ref.read(chatServiceProvider).setTyping(widget.conversationId, false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    _markAsNotTyping();

    try {
      await ref.read(chatServiceProvider).sendMessage(
        conversationId: widget.conversationId,
        content: content,
        messageType: MessageType.text,
      );
      // Auto-scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversationName, style: textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
            if (!widget.isGroup)
              ref.watch(userPresenceProvider(widget.conversationId)).when(
                data: (presence) => OnlineStatusIndicator(
                  isOnline: presence?.isOnline ?? false,
                  lastSeenAt: presence?.lastSeenAt,
                ),
                loading: () => Text('Loading...', style: textStyles.labelSmall),
                error: (err, st) => const SizedBox.shrink(),
              ),
          ],
        ),
        actions: [
          IconButton(icon: Icon(Icons.phone, color: colorScheme.onSurface), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam, color: colorScheme.onSurface), onPressed: () {}),
          IconButton(icon: Icon(Icons.more_vert, color: colorScheme.onSurface), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ref.watch(messagesStreamProvider(widget.conversationId)).when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Start the conversation!',
                      style: textStyles.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.senderId == ref.read(chatServiceProvider)._client.auth.currentUser?.id;

                    return ref.watch(reactionsProvider(message.id)).when(
                      data: (reactions) => MessageBubble(
                        message: message,
                        isOwn: isOwn,
                        reactions: reactions,
                        onReact: () => _showEmojiPicker(context, message.id),
                        onLongPress: () => _showMessageActions(context, message, isOwn),
                      ),
                      loading: () => MessageBubble(
                        message: message,
                        isOwn: isOwn,
                      ),
                      error: (err, st) => MessageBubble(
                        message: message,
                        isOwn: isOwn,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => Center(child: Text('Error: $err')),
            ),
          ),

          // Typing indicator
          ref.watch(typingIndicatorProvider(widget.conversationId)).when(
            data: (typingUsers) {
              if (typingUsers.isEmpty) return const SizedBox.shrink();
              return TypingIndicator(
                typingUsers: typingUsers,
                userNames: {}, // Would populate from user data
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(top: BorderSide(color: colorScheme.outline.withOpacity(0.1))),
            ),
            child: Column(
              children: [
                // Quick action buttons
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        _QuickActionButton(
                          icon: Icons.image,
                          label: 'Galerie',
                          onTap: () {},
                        ),
                        _QuickActionButton(
                          icon: Icons.description,
                          label: 'Document',
                          onTap: () {},
                        ),
                        _QuickActionButton(
                          icon: Icons.location_on,
                          label: 'Localisation',
                          onTap: () {},
                        ),
                        _QuickActionButton(
                          icon: Icons.person,
                          label: 'Contact',
                          onTap: () {},
                        ),
                        _QuickActionButton(
                          icon: Icons.payments,
                          label: 'Paiement',
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),
                ),
                // Message input row
                Row(
                  children: [
                    // Plus menu
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.add, color: colorScheme.onPrimary),
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Text input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        onChanged: (value) {
                          if (value.isNotEmpty && !_isTyping) {
                            _markAsTyping();
                          } else if (value.isEmpty && _isTyping) {
                            _markAsNotTyping();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: 'Tapez un message...',
                          prefixIcon: Icon(Icons.emoji_emotions, color: colorScheme.primary),
                          suffixIcon: Icon(Icons.attach_file, color: colorScheme.onSurfaceVariant),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Send/Record button
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _messageController.text.isEmpty ? Icons.mic : Icons.send,
                          color: colorScheme.onPrimary,
                        ),
                        onPressed: _messageController.text.isEmpty ? () {} : _sendMessage,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmojiPicker(BuildContext context, String messageId) {
    final emojis = ['👍', '❤️', '😂', '🔥', '😍', '👏', '🤔', '😮'];
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          children: emojis.map((emoji) {
            return GestureDetector(
              onTap: () {
                ref.read(chatServiceProvider).addReaction(
                  messageId: messageId,
                  emoji: emoji,
                );
                Navigator.pop(context);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showMessageActions(BuildContext context, Message message, bool isOwn) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isOwn) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _messageController.text = message.content ?? '';
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Delete'),
                onTap: () {
                  ref.read(chatServiceProvider).deleteMessage(message.id);
                  Navigator.pop(context);
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.reply),
              title: const Text('Reply'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flag),
              title: const Text('Report'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colorScheme.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: context.textStyles.labelSmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
