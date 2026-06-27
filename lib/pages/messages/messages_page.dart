import 'package:flutter/material.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';
import 'package:thix_central/widgets/thix_sections.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Messages',
        subtitle: 'Chats, groupes, fichiers',
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
            const Padding(padding: EdgeInsets.only(right: 8), child: ThixAvatar(initials: 'N')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 0,
        label: Text('Nouveau', style: context.textStyles.labelLarge?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800)),
        icon: Icon(Icons.add, color: cs.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 110),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher un chat, contact, groupe…',
              prefixIcon: Icon(Icons.search, color: cs.primary),
              suffixIcon: Icon(Icons.filter_list, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: ThixPillChip(label: 'En ligne', icon: Icons.circle, onTap: () {}, badgeCount: 142)),
              const SizedBox(width: 10),
              Expanded(child: ThixPillChip(label: 'Nouveaux', icon: Icons.mark_chat_unread_outlined, onTap: () {}, badgeCount: 38)),
              const SizedBox(width: 10),
              Expanded(child: ThixPillChip(label: 'Réunions', icon: Icons.videocam_outlined, onTap: () {}, badgeCount: 12)),
            ],
          ),
          const SizedBox(height: 14),
          const ThixSectionHeader(title: 'Conversations récentes', actionLabel: 'Filtres'),
          const SizedBox(height: 6),
          const _ChatRow(title: 'Aminata Diallo', message: 'Peux-tu me partager le document du projet ?', time: '09:31', unread: 2),
          const _ChatRow(title: 'Équipe Marketing', message: 'David: voici les visuels pour la campagne', time: '09:12', unread: 5),
          const _ChatRow(title: 'Koffi Mensah', message: 'On avance bien', time: 'Hier', unread: 1),
          const _ChatRow(title: 'Projets Innovants', message: 'N’oubliez pas la réunion', time: 'Lun', unread: 0),
        ],
      ),
    );
  }
}

class _ChatRow extends StatelessWidget {
  const _ChatRow({required this.title, required this.message, required this.time, required this.unread});
  final String title;
  final String message;
  final String time;
  final int unread;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppRadius.serviceCard),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              const ThixAvatar(initials: 'T'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis)),
                        Text(time, style: context.textStyles.labelMedium?.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(message, style: context.textStyles.bodySmall?.copyWith(color: cs.onSurfaceVariant), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (unread > 0)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(color: cs.primary, borderRadius: BorderRadius.circular(999)),
                  alignment: Alignment.center,
                  child: Text(unread > 9 ? '9+' : unread.toString(), style: context.textStyles.labelSmall?.copyWith(color: cs.onPrimary, fontWeight: FontWeight.w800, height: 1.1)),
                )
              else
                Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
