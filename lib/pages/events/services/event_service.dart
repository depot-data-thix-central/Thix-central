import 'package:thix_central/pages/events/models/event_models.dart';

class EventFilterState {
  const EventFilterState({
    this.query = '',
    this.selectedCategory = EventCategoryType.all,
    this.onlyFavorites = false,
    this.onlyFree = false,
    this.onlyAvailable = false,
    this.sort = EventSortOption.featured,
  });

  final String query;
  final EventCategoryType selectedCategory;
  final bool onlyFavorites;
  final bool onlyFree;
  final bool onlyAvailable;
  final EventSortOption sort;

  EventFilterState copyWith({
    String? query,
    EventCategoryType? selectedCategory,
    bool? onlyFavorites,
    bool? onlyFree,
    bool? onlyAvailable,
    EventSortOption? sort,
  }) {
    return EventFilterState(
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      onlyFavorites: onlyFavorites ?? this.onlyFavorites,
      onlyFree: onlyFree ?? this.onlyFree,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
      sort: sort ?? this.sort,
    );
  }
}

class EventsService {
  const EventsService();

  List<ThixEvent> applyFilters(
    List<ThixEvent> events,
    EventFilterState filters, {
    Set<String> favoriteIds = const <String>{},
  }) {
    final query = filters.query.trim().toLowerCase();
    final filtered = events.where((event) {
      final matchesQuery = query.isEmpty ||
          event.title.toLowerCase().contains(query) ||
          event.summary.toLowerCase().contains(query) ||
          event.city.toLowerCase().contains(query) ||
          event.venue.toLowerCase().contains(query) ||
          event.tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesCategory = filters.selectedCategory == EventCategoryType.all || event.category == filters.selectedCategory;
      final matchesFavorite = !filters.onlyFavorites || favoriteIds.contains(event.id);
      final matchesFree = !filters.onlyFree || event.isFree;
      final matchesAvailable = !filters.onlyAvailable || !event.isSoldOut;
      return matchesQuery && matchesCategory && matchesFavorite && matchesFree && matchesAvailable && event.isPublished;
    }).toList();

    filtered.sort((left, right) {
      switch (filters.sort) {
        case EventSortOption.featured:
          final featuredOrder = _featuredScore(right).compareTo(_featuredScore(left));
          if (featuredOrder != 0) return featuredOrder;
          return left.startsAt.compareTo(right.startsAt);
        case EventSortOption.newest:
          final leftDate = left.createdAt ?? left.startsAt;
          final rightDate = right.createdAt ?? right.startsAt;
          return rightDate.compareTo(leftDate);
        case EventSortOption.date:
          return left.startsAt.compareTo(right.startsAt);
        case EventSortOption.priceLowToHigh:
          final priceOrder = left.priceCents.compareTo(right.priceCents);
          if (priceOrder != 0) return priceOrder;
          return left.startsAt.compareTo(right.startsAt);
        case EventSortOption.popularity:
          final popularityOrder = right.attendeesCount.compareTo(left.attendeesCount);
          if (popularityOrder != 0) return popularityOrder;
          return right.favoritesCount.compareTo(left.favoritesCount);
      }
    });
    return filtered;
  }

  List<EventCategoryChip> buildCategories(List<ThixEvent> events) {
    final published = events.where((event) => event.isPublished).toList();
    final chips = <EventCategoryChip>[
      EventCategoryChip(type: EventCategoryType.all, itemCount: published.length),
    ];
    for (final type in EventCategoryType.values.where((value) => value != EventCategoryType.all)) {
      final count = published.where((event) => event.category == type).length;
      if (count > 0) chips.add(EventCategoryChip(type: type, itemCount: count));
    }
    return chips;
  }

  List<ThixEvent> recommended(List<ThixEvent> events) => events.where((event) => event.isRecommended).toList();

  List<ThixEvent> upcoming(List<ThixEvent> events) {
    final sorted = [...events]..sort((left, right) => left.startsAt.compareTo(right.startsAt));
    return sorted;
  }

  String formatMoney(int cents, {String currency = 'XOF'}) {
    final whole = cents ~/ 100;
    final buffer = StringBuffer();
    final digits = whole.toString();
    for (var index = 0; index < digits.length; index++) {
      final reversedIndex = digits.length - index;
      buffer.write(digits[index]);
      if (reversedIndex > 1 && reversedIndex % 3 == 1) {
        buffer.write('.');
      }
    }
    return '${buffer.toString()} FC';
  }

  String formatDate(DateTime value) {
    const months = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    final month = months[value.month - 1];
    return '${value.day.toString().padLeft(2, '0')} $month ${value.year}';
  }

  String formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${formatDate(value)} · ${hour}h$minute';
  }

  String formatDateWindow(DateTime start, DateTime? end) {
    if (end == null) return formatDateTime(start);
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (!sameDay) return '${formatDateTime(start)} → ${formatDateTime(end)}';
    final endHour = end.hour.toString().padLeft(2, '0');
    final endMinute = end.minute.toString().padLeft(2, '0');
    return '${formatDateTime(start)} → ${endHour}h$endMinute';
  }

  String availabilityLabel(ThixEvent event) {
    if (event.isSoldOut) return 'Complet';
    if (event.isAlmostFull) return 'Plus que ${event.seatsRemaining} places';
    if (event.seatsTotal <= 0) return 'Places disponibles';
    return '${event.seatsRemaining} places restantes';
  }

  int clampQuantity(ThixEvent event, int quantity) {
    final safeQuantity = quantity < 1 ? 1 : quantity;
    if (event.seatsTotal <= 0) return safeQuantity;
    if (event.seatsRemaining <= 0) return 0;
    return safeQuantity > event.seatsRemaining ? event.seatsRemaining : safeQuantity;
  }

  int _featuredScore(ThixEvent event) {
    var score = 0;
    if (event.isFeatured) score += 1000;
    if (event.isTrending) score += 500;
    if (event.isRecommended) score += 250;
    score += event.attendeesCount;
    score += event.favoritesCount;
    return score;
  }
}
