import 'package:flutter_test/flutter_test.dart';
import 'package:thix_central/pages/events/models/event_models.dart';
import 'package:thix_central/pages/events/services/event_service.dart';

void main() {
  const service = EventsService();
  final baseDate = DateTime(2026, 7, 1, 20);

  ThixEvent buildEvent({
    required String id,
    required String title,
    required EventCategoryType category,
    required int priceCents,
    int seatsTotal = 100,
    int seatsRemaining = 20,
    int attendeesCount = 10,
    int favoritesCount = 5,
    bool isFeatured = false,
    bool isRecommended = false,
    bool isTrending = false,
    List<String> tags = const [],
    DateTime? startsAt,
  }) {
    return ThixEvent(
      id: id,
      title: title,
      summary: 'Résumé $title',
      description: 'Description $title',
      category: category,
      city: 'Dakar',
      venue: 'Salle A',
      startsAt: startsAt ?? baseDate,
      priceCents: priceCents,
      coverImageUrl: 'https://example.com/$id.jpg',
      tags: tags,
      isFeatured: isFeatured,
      isRecommended: isRecommended,
      isTrending: isTrending,
      seatsTotal: seatsTotal,
      seatsRemaining: seatsRemaining,
      attendeesCount: attendeesCount,
      favoritesCount: favoritesCount,
      createdAt: baseDate.subtract(const Duration(days: 2)),
    );
  }

  test('applyFilters keeps favorites and available events only', () {
    final events = [
      buildEvent(id: 'fav', title: 'Festival THIX', category: EventCategoryType.festival, priceCents: 2000000, isRecommended: true),
      buildEvent(id: 'soldout', title: 'Concert complet', category: EventCategoryType.concert, priceCents: 1500000, seatsRemaining: 0),
      buildEvent(id: 'free', title: 'Meetup gratuit', category: EventCategoryType.networking, priceCents: 0),
    ];

    final filtered = service.applyFilters(
      events,
      const EventFilterState(onlyFavorites: true, onlyAvailable: true),
      favoriteIds: {'fav', 'soldout'},
    );

    expect(filtered.map((event) => event.id), ['fav']);
  });

  test('applyFilters sorts featured content before the rest', () {
    final events = [
      buildEvent(id: 'regular', title: 'Regular', category: EventCategoryType.conference, priceCents: 1000000, attendeesCount: 20),
      buildEvent(
        id: 'featured',
        title: 'Featured',
        category: EventCategoryType.concert,
        priceCents: 1000000,
        attendeesCount: 5,
        isFeatured: true,
        isRecommended: true,
      ),
    ];

    final filtered = service.applyFilters(events, const EventFilterState(sort: EventSortOption.featured));

    expect(filtered.first.id, 'featured');
  });

  test('buildCategories includes all bucket and per-type counts', () {
    final events = [
      buildEvent(id: 'one', title: 'Concert', category: EventCategoryType.concert, priceCents: 1000000),
      buildEvent(id: 'two', title: 'Another concert', category: EventCategoryType.concert, priceCents: 1000000),
      buildEvent(id: 'three', title: 'Festival', category: EventCategoryType.festival, priceCents: 1000000),
    ];

    final categories = service.buildCategories(events);

    expect(categories.first.type, EventCategoryType.all);
    expect(categories.first.itemCount, 3);
    expect(categories.where((chip) => chip.type == EventCategoryType.concert).single.itemCount, 2);
    expect(categories.where((chip) => chip.type == EventCategoryType.festival).single.itemCount, 1);
  });

  test('formatMoney outputs grouped FC values', () {
    expect(service.formatMoney(1500000), '15.000 FC');
    expect(service.formatMoney(500000), '5.000 FC');
  });
}
