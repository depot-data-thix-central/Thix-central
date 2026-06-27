import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';
import 'package:thix_central/widgets/thix_sections.dart';
import '../models/chat_models.dart';
import '../pages/conversation_detail_page.dart';
import '../providers/chat_providers.dart';

class EnhancedMessagesPage extends ConsumerStatefulWidget {
  const EnhancedMessagesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<EnhancedMessagesPage> createState() => _EnhancedMessagesPageState();
}

class _EnhancedMessagesPageState extends ConsumerState<EnhancedMessagesPage> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Update user presence
    ref.read(chatServiceProvider).updateUserPresence(isOnline: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    ref.read(chatServiceProvider).updateUserPresence(isOnline: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textStyles = context.textStyles;

    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX CHAT',
        subtitle: 'Connectez-vous. Échangez. Avancez.',
        onMenuTap: () {},
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () {},
              icon: Icon(Icons.search, color: cs.onSurface),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            Stack(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.notifications_none, color: cs.onSurface),
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                ),
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: ThixAvatar(initials: 'U'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewConversationDialog(context),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        label: Text(
          'Nouveau',
          style: textStyles.labelLarge?.copyWith(
            color: cs.onPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        icon: Icon(Icons.add, color: cs.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 110),
        children: [
          // Search and filter
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            decoration: InputDecoration(
              hintText: 'Rechercher un chat, contact, groupe…',
              prefixIcon: Icon(Icons.search, color: cs.primary),
              suffixIcon: Icon(Icons.filter_list, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),

          // Stats pills
          Row(
            children: [
              Expanded(
                child: _StatsPill(
                  label: 'En ligne',
                  icon: Icons.circle,
                  count: 142,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsPill(
                  label: 'Nouveaux',
                  icon: Icons.mark_chat_unread_outlined,
                  count: 38,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatsPill(
                  label: 'Réunions',
                  icon: Icons.videocam_outlined,
                  count: 12,
                  onTap: () {},
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Online users section
          const ThixSectionHeader(title: 'En ligne', actionLabel: 'Voir tout'),
          const SizedBox(height: 8),
          SizedBox(
            height: 90,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              children: List.generate(
                5,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: _OnlineUserCard(
                    name: ['Aminata', 'Nathan', 'Sarah', 'Koffi', 'David'][index],
                    initials: ['A', 'N', 'S', 'K', 'D'][index],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Navigation pills
          Row(
            children: [
              _NavPill(icon: Icons.message, label: 'Tous', isActive: true),
              const SizedBox(width: 10),
              _NavPill(icon: Icons.group, label: 'Équipes', isActive: false),
              const SizedBox(width: 10),
              _NavPill(icon: Icons.phone, label: 'Appels', isActive: false),
            ],
          ),
          const SizedBox(height: 14),

          // Recent conversations
          const ThixSectionHeader(title: 'Conversations récentes', actionLabel: 'Filtres'),
          const SizedBox(height: 6),

          // Load conversations
          ref.watch(conversationsProvider).when(
            data: (conversations) {
              if (conversations.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Aucune conversation. Démarrez une nouvelle!',
                      style: textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              return Column(
                children: conversations.map((conversation) {
                  return _ConversationTile(
                    conversation: conversation,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ConversationDetailPage(
                            conversationId: conversation.id,
                            conversationName: conversation.name ?? 'Chat',
                            avatarUrl: conversation.avatarUrl,
                            isGroup: conversation.isGroup,
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
            error: (err, st) => Padding(
              padding: const EdgeInsets.all(32),
              child: Text('Error: $err'),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Direct Message'),
              onTap: () {
                Navigator.pop(context);
                _showContactPicker(context, isGroup: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Create Group'),
              onTap: () {
                Navigator.pop(context);
                _showContactPicker(context, isGroup: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showContactPicker(BuildContext context, {required bool isGroup}) {
    // Placeholder: Would show contact/user picker
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isGroup ? 'Create group feature coming soon' : 'DM feature coming soon'),
      ),
    );
  }
}

class _StatsPill extends StatelessWidget {
  final String label;
  final IconData icon;
  final int count;
  final VoidCallback onTap;

  const _StatsPill({
    required this.label,
    required this.icon,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outline.withOpacity(0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: cs.primary, size: 24),
            const SizedBox(height: 8),
            Text(count.toString(), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(label, style: context.textStyles.labelSmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _OnlineUserCard extends StatelessWidget {
  final String name;
  final String initials;

  const _OnlineUserCard({
    required this.name,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {},
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.primary, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: TextStyle(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: context.textStyles.labelSmall,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;

  const _NavPill({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? cs.primary.withOpacity(0.1) : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: cs.primary) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isActive ? cs.primary : cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: context.textStyles.labelSmall?.copyWith(
              color: isActive ? cs.primary : cs.onSurfaceVariant,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final Conversation conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            border: Border.all(color: cs.outline.withOpacity(0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: conversation.isGroup ? BoxShape.rectangle : BoxShape.circle,
                  borderRadius: conversation.isGroup ? BorderRadius.circular(8) : null,
                ),
                alignment: Alignment.center,
                child: Icon(
                  conversation.isGroup ? Icons.group : Icons.person,
                  color: cs.onPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.name ?? 'Chat',
                            style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '09:31',
                          style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      conversation.description ?? 'Last message preview...',
                      style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
                alignment: Alignment.center,
                child: Text(
                  '2',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
