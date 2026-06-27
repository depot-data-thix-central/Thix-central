import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:thix_central/nav.dart';
import 'package:thix_central/pages/events/models/event_models.dart';
import 'package:thix_central/pages/events/repositories/event_repository.dart';
import 'package:thix_central/pages/events/services/event_service.dart';
import 'package:thix_central/theme.dart';
import 'package:thix_central/widgets/thix_app_bar.dart';

class EventsHomePage extends StatefulWidget {
  const EventsHomePage({super.key});

  @override
  State<EventsHomePage> createState() => _EventsHomePageState();
}

class _EventsHomePageState extends State<EventsHomePage> {
  final ThixEventsRepository _repository = ThixEventsRepository();
  final EventsService _service = const EventsService();
  final TextEditingController _searchController = TextEditingController();
  final PageController _heroController = PageController();

  EventModuleSnapshot? _snapshot;
  EventFilterState _filters = const EventFilterState();
  bool _loading = true;
  Object? _error;
  int _heroIndex = 0;

  @override
  void initState() {
    super.initState();
    _load(forceRefresh: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final snapshot = await _repository.loadModule(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _snapshot = snapshot;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final snapshot = _snapshot;
    final events = snapshot == null ? const <ThixEvent>[] : _service.applyFilters(snapshot.events, _filters, favoriteIds: snapshot.favoriteEventIds);
    final categories = snapshot == null ? const <EventCategoryChip>[] : _service.buildCategories(snapshot.events);
    final featuredEvents = events.where((event) => event.isFeatured).toList();
    final recommendedEvents = _service.recommended(events);
    final upcomingEvents = _service.upcoming(events).take(4).toList();
    final popularCategories = categories.where((chip) => chip.type != EventCategoryType.all).take(6).toList();

    return Scaffold(
      appBar: ThixTopBar(
        title: 'THIX ÉVÉNEMENT',
        subtitle: 'Découvrez, réservez, vivez l’exceptionnel.',
        onMenuTap: () => context.canPop() ? context.pop() : ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Menu THIX prêt.'))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => context.push(AppRoutes.eventsTickets),
              icon: Badge.count(
                count: snapshot?.bookings.length ?? 0,
                isLabelVisible: (snapshot?.bookings.length ?? 0) > 0,
                child: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: ThixAvatar(initials: 'TD'),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(forceRefresh: true),
        child: _loading && snapshot == null
            ? const Center(child: CircularProgressIndicator())
            : _error != null && snapshot == null
                ? _EventsErrorState(error: _error.toString(), onRetry: () => _load(forceRefresh: true))
                : ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, 8, AppSpacing.md, 110),
                    children: [
                      _EventsSearchBar(
                        controller: _searchController,
                        query: _filters.query,
                        onChanged: (value) => setState(() => _filters = _filters.copyWith(query: value)),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _filters = _filters.copyWith(query: ''));
                        },
                        onFilterTap: _openFilters,
                        activeCount: _activeFilterCount,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (featuredEvents.isNotEmpty)
                        _HeroCarousel(
                          controller: _heroController,
                          events: featuredEvents,
                          index: _heroIndex,
                          service: _service,
                          onPageChanged: (value) => setState(() => _heroIndex = value),
                          onOpen: _openEvent,
                        )
                      else
                        _EmptySectionCard(
                          title: 'Aucun événement mis en avant',
                          message: 'Essayez un autre filtre ou rechargez les contenus publiés.',
                        ),
                      const SizedBox(height: AppSpacing.md),
                      _CategoryStrip(
                        items: categories,
                        selected: _filters.selectedCategory,
                        onSelected: (type) => setState(() => _filters = _filters.copyWith(selectedCategory: type)),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _SectionHeader(title: 'Catégories populaires', action: 'Réinitialiser', onAction: _resetCategory),
                      const SizedBox(height: AppSpacing.sm),
                      _PopularCategoriesGrid(items: popularCategories, onSelected: (type) => setState(() => _filters = _filters.copyWith(selectedCategory: type))),
                      const SizedBox(height: AppSpacing.md),
                      _SectionHeader(title: 'Événements recommandés', action: 'Voir tout', onAction: () => _scrollToAll('recommandés')),
                      const SizedBox(height: AppSpacing.sm),
                      if (recommendedEvents.isEmpty)
                        const _EmptySectionCard(title: 'Aucune recommandation', message: 'Ajoutez ou publiez des événements recommandés pour alimenter ce bloc.')
                      else
                        _RecommendedGrid(
                          events: recommendedEvents,
                          service: _service,
                          favoriteIds: snapshot?.favoriteEventIds ?? const <String>{},
                          onFavoriteToggle: _toggleFavorite,
                          onReserve: _quickReserve,
                          onOpen: _openEvent,
                        ),
                      const SizedBox(height: AppSpacing.lg),
                      _NotificationBanner(onTap: () => context.push(AppRoutes.eventsTickets)),
                      const SizedBox(height: AppSpacing.lg),
                      _SectionHeader(title: 'Prochains événements', action: 'Mes billets', onAction: () => context.push(AppRoutes.eventsTickets)),
                      const SizedBox(height: AppSpacing.sm),
                      if (upcomingEvents.isEmpty)
                        const _EmptySectionCard(title: 'Aucun événement à venir', message: 'Le catalogue ne contient aucun événement correspondant pour le moment.')
                      else
                        ...upcomingEvents.map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _UpcomingTile(
                              event: event,
                              service: _service,
                              isFavorite: snapshot?.favoriteEventIds.contains(event.id) ?? false,
                              onFavoriteToggle: () => _toggleFavorite(event.id),
                              onReserve: () => _quickReserve(event),
                              onOpen: () => _openEvent(event),
                            ),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  int get _activeFilterCount =>
      (_filters.onlyFavorites ? 1 : 0) + (_filters.onlyFree ? 1 : 0) + (_filters.onlyAvailable ? 1 : 0) + (_filters.selectedCategory != EventCategoryType.all ? 1 : 0);

  void _scrollToAll(String label) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Liste complète $label déjà visible via les filtres.')));
  }

  void _resetCategory() {
    setState(() => _filters = _filters.copyWith(selectedCategory: EventCategoryType.all));
  }

  Future<void> _toggleFavorite(String eventId) async {
    final nextSnapshot = await _repository.toggleFavorite(eventId);
    if (!mounted) return;
    setState(() => _snapshot = nextSnapshot);
  }

  Future<void> _quickReserve(ThixEvent event) async {
    try {
      final nextSnapshot = await _repository.reserveTicket(event);
      if (!mounted) return;
      setState(() => _snapshot = nextSnapshot);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Billet ajouté à Mes billets.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Réservation impossible: $error')));
    }
  }

  void _openEvent(ThixEvent event) {
    context.push(AppRoutes.eventDetails(event.id), extra: event);
  }

  Future<void> _openFilters() async {
    var working = _filters;
    final updated = await showModalBottomSheet<EventFilterState>(
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
                  Text('Filtres événements', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Favoris'),
                        selected: working.onlyFavorites,
                        onSelected: (value) => setModalState(() => working = working.copyWith(onlyFavorites: value)),
                      ),
                      FilterChip(
                        label: const Text('Gratuits'),
                        selected: working.onlyFree,
                        onSelected: (value) => setModalState(() => working = working.copyWith(onlyFree: value)),
                      ),
                      FilterChip(
                        label: const Text('Disponibles'),
                        selected: working.onlyAvailable,
                        onSelected: (value) => setModalState(() => working = working.copyWith(onlyAvailable: value)),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Tri', style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: EventSortOption.values
                        .map(
                          (sort) => ChoiceChip(
                            label: Text(_sortLabel(sort)),
                            selected: working.sort == sort,
                            onSelected: (_) => setModalState(() => working = working.copyWith(sort: sort)),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(const EventFilterState()),
                          child: const Text('Réinitialiser'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(working),
                          child: const Text('Appliquer'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    if (updated == null || !mounted) return;
    setState(() => _filters = updated.copyWith(query: _filters.query, selectedCategory: _filters.selectedCategory));
  }

  String _sortLabel(EventSortOption value) {
    return switch (value) {
      EventSortOption.featured => 'Mise en avant',
      EventSortOption.newest => 'Nouveautés',
      EventSortOption.date => 'Date',
      EventSortOption.priceLowToHigh => 'Prix',
      EventSortOption.popularity => 'Popularité',
    };
  }
}

class _EventsSearchBar extends StatelessWidget {
  const _EventsSearchBar({
    required this.controller,
    required this.query,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
    required this.activeCount,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;
  final int activeCount;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.search), border: Border.all(color: AppColors.cardBorder)),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: controller,
                    onChanged: onChanged,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rechercher un événement, une ville, un lieu…'),
                  ),
                ),
                if (query.isNotEmpty)
                  IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded), splashColor: Colors.transparent, highlightColor: Colors.transparent),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        IconButton.filledTonal(
          onPressed: onFilterTap,
          icon: Badge.count(count: activeCount, isLabelVisible: activeCount > 0, child: const Icon(Icons.tune_rounded)),
        ),
      ],
    );
  }
}

class _HeroCarousel extends StatelessWidget {
  const _HeroCarousel({
    required this.controller,
    required this.events,
    required this.index,
    required this.service,
    required this.onPageChanged,
    required this.onOpen,
  });

  final PageController controller;
  final List<ThixEvent> events;
  final int index;
  final EventsService service;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<ThixEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 248,
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: events.length,
            itemBuilder: (context, pageIndex) {
              final event = events[pageIndex];
              return InkWell(
                onTap: () => onOpen(event),
                borderRadius: BorderRadius.circular(AppRadius.mainCard),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppRadius.mainCard),
                    image: DecorationImage(image: NetworkImage(event.coverImageUrl), fit: BoxFit.cover),
                    boxShadow: const [AppShadows.main],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.mainCard),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xE6210B66), Color(0xB80A042E), Color(0x66000000)],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(999)),
                            child: Text('⭐ À LA UNE', style: context.textStyles.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                          ),
                          const Spacer(),
                          Text(event.title, style: context.textStyles.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 8),
                          Text(event.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.88))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              ElevatedButton(
                                onPressed: () => onOpen(event),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: event.category.color),
                                child: const Text('Découvrir la sélection'),
                              ),
                              const Spacer(),
                              Text(service.formatMoney(event.priceCents), style: context.textStyles.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            events.length,
            (dotIndex) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: dotIndex == index ? 18 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotIndex == index ? Theme.of(context).colorScheme.primary : AppColors.cardBorder,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  const _CategoryStrip({required this.items, required this.selected, required this.onSelected});

  final List<EventCategoryChip> items;
  final EventCategoryType selected;
  final ValueChanged<EventCategoryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = item.type == selected;
          return InkWell(
            onTap: () => onSelected(item.type),
            borderRadius: BorderRadius.circular(AppRadius.serviceCard),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isSelected ? item.color.withValues(alpha: 0.12) : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.serviceCard),
                border: Border.all(color: isSelected ? item.color : AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 18, backgroundColor: item.color.withValues(alpha: 0.15), child: Icon(item.icon, color: item.color)),
                  const Spacer(),
                  Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
                  Text('${item.itemCount} live', style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PopularCategoriesGrid extends StatelessWidget {
  const _PopularCategoriesGrid({required this.items, required this.onSelected});

  final List<EventCategoryChip> items;
  final ValueChanged<EventCategoryType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items
          .map(
            (item) => InkWell(
              onTap: () => onSelected(item.type),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                width: (MediaQuery.of(context).size.width - (AppSpacing.md * 2) - 20) / 3,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.cardBorder)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: item.color),
                    const SizedBox(height: 8),
                    Text(item.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecommendedGrid extends StatelessWidget {
  const _RecommendedGrid({
    required this.events,
    required this.service,
    required this.favoriteIds,
    required this.onFavoriteToggle,
    required this.onReserve,
    required this.onOpen,
  });

  final List<ThixEvent> events;
  final EventsService service;
  final Set<String> favoriteIds;
  final ValueChanged<String> onFavoriteToggle;
  final ValueChanged<ThixEvent> onReserve;
  final ValueChanged<ThixEvent> onOpen;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: events.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.61,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemBuilder: (context, index) {
        final event = events[index];
        return _EventCard(
          event: event,
          service: service,
          isFavorite: favoriteIds.contains(event.id),
          onFavoriteToggle: () => onFavoriteToggle(event.id),
          onReserve: () => onReserve(event),
          onOpen: () => onOpen(event),
        );
      },
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.service,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onReserve,
    required this.onOpen,
  });

  final ThixEvent event;
  final EventsService service;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onReserve;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.mainCard),
      child: Container(
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.mainCard)),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(event.coverImageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.black12)),
                  ),
                ),
                Positioned(
                  left: 10,
                  top: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: event.category.color.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(999)),
                    child: Text((event.badgeLabel ?? event.category.label).toUpperCase(), style: context.textStyles.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: IconButton(
                    onPressed: onFavoriteToggle,
                    icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? AppColors.dangerRed : Colors.white),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule_rounded, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(service.formatDateTime(event.startsAt), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 15, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Expanded(child: Text(event.venue, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.copyWith(color: AppColors.textSecondary))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(service.availabilityLabel(event), style: context.textStyles.labelSmall?.copyWith(color: event.isSoldOut ? AppColors.dangerRed : AppColors.successGreen, fontWeight: FontWeight.w700)),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(child: Text(service.formatMoney(event.priceCents, currency: event.currency), style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900, color: cs.primary))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: event.isSoldOut ? onOpen : onReserve,
                        style: ElevatedButton.styleFrom(backgroundColor: event.isSoldOut ? AppColors.cardBorder : event.category.color, foregroundColor: event.isSoldOut ? AppColors.textSecondary : Colors.white),
                        child: Text(event.isSoldOut ? 'Voir le détail' : 'Réserver'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  const _NotificationBanner({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF5B2EFF), Color(0xFF8F48FF)]), borderRadius: BorderRadius.circular(AppRadius.mainCard)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.notifications_active_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ne manquez aucun événement !', style: context.textStyles.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text('Activez vos billets et notifications pour suivre les nouveautés près de vous.', style: context.textStyles.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.86))),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.accentPurple),
            child: const Text('Activer'),
          ),
        ],
      ),
    );
  }
}

class _UpcomingTile extends StatelessWidget {
  const _UpcomingTile({
    required this.event,
    required this.service,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onReserve,
    required this.onOpen,
  });

  final ThixEvent event;
  final EventsService service;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onReserve;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.serviceCard),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(color: cs.surface, borderRadius: BorderRadius.circular(AppRadius.serviceCard), border: Border.all(color: AppColors.cardBorder)),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(event.coverImageUrl, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 72, height: 72, color: Colors.black12)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(event.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900))),
                      IconButton(onPressed: onFavoriteToggle, icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? AppColors.dangerRed : AppColors.textSecondary)),
                    ],
                  ),
                  Text(_eventTypeLabel(event), style: context.textStyles.labelSmall?.copyWith(color: event.category.color, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  Text(service.formatDateTime(event.startsAt), style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  Text(event.venue, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(service.formatMoney(event.priceCents, currency: event.currency), style: context.textStyles.titleSmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: event.isSoldOut ? onOpen : onReserve, child: Text(event.isSoldOut ? 'Détail' : 'Réserver')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _eventTypeLabel(ThixEvent event) => event.badgeLabel?.toUpperCase() ?? event.category.label.toUpperCase();
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: Text(title, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900))),
        if (action != null)
          TextButton(onPressed: onAction, child: Text(action!, style: context.textStyles.labelLarge?.copyWith(color: cs.primary, fontWeight: FontWeight.w800))),
      ],
    );
  }
}

class _EmptySectionCard extends StatelessWidget {
  const _EmptySectionCard({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(AppRadius.mainCard), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(message, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _EventsErrorState extends StatelessWidget {
  const _EventsErrorState({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const Icon(Icons.wifi_off_rounded, size: 54, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text('Impossible de charger les événements', textAlign: TextAlign.center, style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: onRetry, child: const Text('Réessayer')),
      ],
    );
  }
}
