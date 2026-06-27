import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/pages/events/models/event_models.dart';
import 'package:thix_central/pages/events/repositories/event_repository.dart';
import 'package:thix_central/pages/events/services/event_service.dart';
import 'package:thix_central/theme.dart';

class EventDetailPage extends StatefulWidget {
  const EventDetailPage({super.key, required this.eventId, this.initialEvent});

  final String eventId;
  final ThixEvent? initialEvent;

  @override
  State<EventDetailPage> createState() => _EventDetailPageState();
}

class _EventDetailPageState extends State<EventDetailPage> {
  final ThixEventsRepository _repository = ThixEventsRepository();
  final EventsService _service = const EventsService();

  ThixEvent? _event;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _event = widget.initialEvent;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final event = await _repository.loadEvent(widget.eventId);
    if (!mounted) return;
    setState(() {
      _event = event ?? _event;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final event = _event;
    return Scaffold(
      body: _isLoading && event == null
          ? const Center(child: CircularProgressIndicator())
          : event == null
              ? _EventMissingState(onBack: () => context.pop())
              : CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 280,
                      pinned: true,
                      backgroundColor: Colors.black,
                      leading: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      flexibleSpace: FlexibleSpaceBar(
                        background: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              event.coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Color(0x22000000), Color(0xD8000000)],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        IconButton(
                          onPressed: _toggleFavorite,
                          icon: Icon(Icons.favorite_rounded, color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 120),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _Pill(label: event.badgeLabel ?? event.category.label, color: event.category.color),
                                _Pill(label: _service.availabilityLabel(event), color: event.isSoldOut ? AppColors.dangerRed : AppColors.successGreen),
                                _Pill(label: '${event.rating.toStringAsFixed(1)} ★', color: AppColors.darkNavy),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(event.title, style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
                            const SizedBox(height: 8),
                            Text(event.summary, style: context.textStyles.bodyLarge?.copyWith(color: AppColors.textSecondary, height: 1.45)),
                            const SizedBox(height: AppSpacing.lg),
                            _InfoTile(icon: Icons.schedule_rounded, title: 'Date', value: _service.formatDateWindow(event.startsAt, event.endsAt)),
                            _InfoTile(icon: Icons.place_outlined, title: 'Lieu', value: '${event.venue} · ${event.city}'),
                            _InfoTile(icon: Icons.person_outline_rounded, title: 'Organisateur', value: event.organizerName),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(AppRadius.mainCard),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('À propos', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 10),
                                  Text(event.description, style: context.textStyles.bodyMedium?.copyWith(height: 1.5, color: AppColors.textSecondary)),
                                  if (event.tags.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: event.tags
                                          .map(
                                            (tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                              decoration: BoxDecoration(color: event.category.color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                                              child: Text('#$tag', style: context.textStyles.labelMedium?.copyWith(color: event.category.color, fontWeight: FontWeight.w700)),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryBlueGradient,
                                borderRadius: BorderRadius.circular(AppRadius.mainCard),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.confirmation_number_outlined, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Billets THIX', style: context.textStyles.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text('Gérez vos réservations, QR codes et confirmations en un seul endroit.', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.84))),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => context.push(AppRoutes.eventsTickets),
                                    child: const Text('Mes billets', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      bottomSheet: event == null
          ? null
          : SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: const Border(top: BorderSide(color: AppColors.cardBorder)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('À partir de', style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary)),
                          Text(_service.formatMoney(event.priceCents, currency: event.currency), style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting || event.isSoldOut ? null : _reserve,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                        ),
                        icon: _isSubmitting ? const SizedBox.square(dimension: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.shopping_bag_outlined),
                        label: Text(event.isSoldOut ? 'Complet' : 'Réserver'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _toggleFavorite() async {
    await _repository.toggleFavorite(widget.eventId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Favoris mis à jour.')));
  }

  Future<void> _reserve() async {
    final event = _event;
    if (event == null) return;
    final quantity = await _showQuantityPicker(event);
    if (quantity == null || quantity <= 0) return;
    setState(() => _isSubmitting = true);
    try {
      final updated = await _repository.reserveTicket(event, quantity: quantity);
      final refreshedEvent = updated.events.firstWhere((item) => item.id == event.id, orElse: () => event);
      if (!mounted) return;
      setState(() {
        _event = refreshedEvent;
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Réservation créée avec succès.')));
      context.push(AppRoutes.eventsTickets);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur réservation: $error')));
    }
  }

  Future<int?> _showQuantityPicker(ThixEvent event) async {
    var quantity = 1;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Choisir le nombre de billets', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(_service.availabilityLabel(event), style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      IconButton(
                        onPressed: quantity > 1 ? () => setModalState(() => quantity -= 1) : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                      Expanded(
                        child: Center(child: Text('$quantity billet${quantity > 1 ? 's' : ''}', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
                      ),
                      IconButton(
                        onPressed: event.seatsTotal > 0 && quantity >= event.seatsRemaining ? null : () => setModalState(() => quantity += 1),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(quantity),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: Text('Confirmer · ${_service.formatMoney(event.priceCents * quantity)}'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: context.textStyles.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w800)),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.title, required this.value});

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EventMissingState extends StatelessWidget {
  const _EventMissingState({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy_outlined, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text('Événement introuvable', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Le contenu demandé n’est plus disponible.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onBack, child: const Text('Retour')),
          ],
        ),
      ),
    );
  }
}
