import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class ServicesPage extends StatelessWidget {
  const ServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: ThixTopBar(
        title: 'Services',
        subtitle: 'Tout l’écosystème THIX',
        onMenuTap: () {},
        trailing: IconButton(
          onPressed: () {},
          icon: Icon(Icons.search, color: cs.onSurface),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Cette section est prête à être reliée à tes modules (Media, Money, Chat, etc.).', style: context.textStyles.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 14),
          _PlaceholderTile(
            icon: Icons.shopping_bag,
            title: 'THIX MARKET',
            subtitle: 'Acheter, vendre, commander (Supabase)',
            onTap: () => context.push('/market'),
          ),
          _PlaceholderTile(icon: Icons.ondemand_video, title: 'THIX MEDIA', subtitle: 'Vidéos, musique, podcasts'),
          _PlaceholderTile(icon: Icons.chat_bubble_outline, title: 'THIX CHAT', subtitle: 'Messages & groupes'),
          _PlaceholderTile(icon: Icons.account_balance_wallet_outlined, title: 'THIX MONEY', subtitle: 'Paiements & portefeuille'),
          _PlaceholderTile(icon: Icons.event_available, title: 'THIX ÉVÈNEMENT', subtitle: 'Réserver et vivre des moments'),
        ],
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile({required this.icon, required this.title, required this.subtitle, this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: cs.onPrimaryContainer, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: context.textStyles.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
