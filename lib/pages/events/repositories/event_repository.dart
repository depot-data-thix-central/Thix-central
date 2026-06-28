import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:thix_central/market/services/supabase_client_provider.dart';
import 'package:thix_central/pages/events/models/event_models.dart';

abstract class EventsRepository {
  Future<EventModuleSnapshot> loadModule({bool forceRefresh = false});

  Future<ThixEvent?> loadEvent(String eventId);

  Future<EventModuleSnapshot> toggleFavorite(String eventId);

  Future<EventModuleSnapshot> reserveTicket(
    ThixEvent event, {
    int quantity = 1,
    String? attendeeName,
    String? attendeeEmail,
  });

  Future<List<EventTicketBooking>> loadBookings();
}

class ThixEventsRepository implements EventsRepository {
  static EventModuleSnapshot? _cache;

  EventModuleSnapshot get _snapshot => _cache ??= _seedSnapshot();

  @override
  Future<EventModuleSnapshot> loadModule({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _snapshot;
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) return _snapshot;
    try {
      final eventRows = await client.from('thix_events').select('*').eq('is_published', true).order('starts_at', ascending: true);
      final events = (eventRows as List)
          .whereType<Map>()
          .map((row) => ThixEvent.fromJson(row.cast<String, dynamic>()))
          .toList();

      final userId = client.auth.currentUser?.id;
      var favoriteIds = <String>{};
      var bookings = <EventTicketBooking>[];

      if (userId != null) {
        final favoriteRows = await client.from('thix_event_favorites').select('event_id').eq('user_id', userId);
        favoriteIds = (favoriteRows as List)
            .whereType<Map>()
            .map((row) => row['event_id']?.toString())
            .whereType<String>()
            .toSet();

        final bookingRows = await client.from('thix_event_bookings').select('*').eq('user_id', userId).order('created_at', ascending: false);
        bookings = (bookingRows as List)
            .whereType<Map>()
            .map((row) => EventTicketBooking.fromJson(row.cast<String, dynamic>()))
            .toList();
      }

      _cache = EventModuleSnapshot(events: events, bookings: bookings, favoriteEventIds: favoriteIds);
      return _cache!;
    } catch (error) {
      debugPrint('events load fallback: $error');
      return _snapshot;
    }
  }

  @override
  Future<ThixEvent?> loadEvent(String eventId) async {
    for (final event in _snapshot.events) {
      if (event.id == eventId) return event;
    }
    final client = SupabaseClientProvider.clientOrNull;
    if (client == null) return null;
    try {
      final row = await client.from('thix_events').select('*').eq('id', eventId).maybeSingle();
      if (row == null) return null;
      return ThixEvent.fromJson((row as Map).cast<String, dynamic>());
    } catch (error) {
      debugPrint('events loadEvent fallback: $error');
      return null;
    }
  }

  @override
  Future<EventModuleSnapshot> toggleFavorite(String eventId) async {
    final nextFavorites = {..._snapshot.favoriteEventIds};
    final eventIndex = _snapshot.events.indexWhere((event) => event.id == eventId);
    if (eventIndex < 0) return _snapshot;
    final event = _snapshot.events[eventIndex];
    final isFavorite = nextFavorites.contains(eventId);
    final nextEvents = [..._snapshot.events];
    if (isFavorite) {
      nextFavorites.remove(eventId);
      nextEvents[eventIndex] = event.copyWith(favoritesCount: max(0, event.favoritesCount - 1));
    } else {
      nextFavorites.add(eventId);
      nextEvents[eventIndex] = event.copyWith(favoritesCount: event.favoritesCount + 1);
    }
    _cache = _snapshot.copyWith(events: nextEvents, favoriteEventIds: nextFavorites);

    final client = SupabaseClientProvider.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        if (isFavorite) {
          await client.from('thix_event_favorites').delete().eq('event_id', eventId).eq('user_id', userId);
        } else {
          await client.from('thix_event_favorites').insert({'event_id': eventId, 'user_id': userId});
        }
      } catch (error) {
        debugPrint('events favorite sync failed: $error');
      }
    }
    return _cache!;
  }

  @override
  Future<EventModuleSnapshot> reserveTicket(
    ThixEvent event, {
    int quantity = 1,
    String? attendeeName,
    String? attendeeEmail,
  }) async {
    final eventIndex = _snapshot.events.indexWhere((item) => item.id == event.id);
    if (eventIndex < 0) throw StateError('Événement introuvable.');
    final currentEvent = _snapshot.events[eventIndex];
    if (currentEvent.isSoldOut) throw StateError('Cet événement est complet.');
    final available = currentEvent.seatsTotal <= 0 ? quantity : min(quantity, currentEvent.seatsRemaining);
    if (available <= 0) throw StateError('Aucune place disponible.');

    final now = DateTime.utc(2027, 7, 1, 10);
    final booking = EventTicketBooking(
      id: 'booking-${now.microsecondsSinceEpoch}',
      eventId: currentEvent.id,
      eventTitle: currentEvent.title,
      eventDate: currentEvent.startsAt,
      eventVenue: currentEvent.venue,
      coverImageUrl: currentEvent.coverImageUrl,
      quantity: available,
      totalPriceCents: currentEvent.priceCents * available,
      currency: currentEvent.currency,
      status: SupabaseClientProvider.clientOrNull?.auth.currentUser == null ? EventTicketStatus.pendingSync : EventTicketStatus.confirmed,
      ticketCode: _ticketCode(now),
      qrPayload: 'thix-event:${currentEvent.id}:${now.microsecondsSinceEpoch}:$available',
      createdAt: now,
      attendeeName: attendeeName,
      attendeeEmail: attendeeEmail,
    );

    final nextEvent = currentEvent.copyWith(
      seatsRemaining: currentEvent.seatsTotal <= 0 ? currentEvent.seatsRemaining : max(0, currentEvent.seatsRemaining - available),
      attendeesCount: currentEvent.attendeesCount + available,
    );
    final nextEvents = [..._snapshot.events]..[eventIndex] = nextEvent;
    final nextBookings = [booking, ..._snapshot.bookings];
    _cache = _snapshot.copyWith(events: nextEvents, bookings: nextBookings);

    final client = SupabaseClientProvider.clientOrNull;
    final userId = client?.auth.currentUser?.id;
    if (client != null && userId != null) {
      try {
        final result = await client.rpc('reserve_thix_event', params: {
          'p_event_id': currentEvent.id,
          'p_quantity': available,
          'p_attendee_name': attendeeName,
          'p_attendee_email': attendeeEmail,
        });
        if (result is Map) {
          final syncedBooking = EventTicketBooking.fromJson(result.cast<String, dynamic>());
          final syncedBookings = [syncedBooking, ...nextBookings.where((item) => item.id != booking.id)];
          _cache = _cache!.copyWith(bookings: syncedBookings);
        }
      } catch (error) {
        debugPrint('events booking sync failed: $error');
      }
    }
    return _cache!;
  }

  @override
  Future<List<EventTicketBooking>> loadBookings() async {
    final snapshot = await loadModule();
    return snapshot.bookings;
  }

  static String _ticketCode(DateTime now) => 'THX-${now.year}${now.month.toString().padLeft(2, '0')}-${Random().nextInt(9000) + 1000}';

  static EventModuleSnapshot _seedSnapshot() {
    final now = DateTime.utc(2027, 7, 1, 10);
    final events = <ThixEvent>[
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a101',
        title: 'TAYC en concert',
        summary: 'Une grande scène afro-love avec show live, zone VIP et accueil premium.',
        description: 'Une expérience concert pensée pour le grand public et les partenaires: accès standard, zone VIP, accueil digitalisé, check-in rapide et notifications en temps réel.',
        category: EventCategoryType.concert,
        city: 'Dakar',
        venue: 'Palais des Congrès',
        startsAt: now.add(const Duration(days: 12, hours: 20)),
        endsAt: now.add(const Duration(days: 12, hours: 23)),
        priceCents: 1500000,
        coverImageUrl: 'https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80',
        galleryUrls: const ['https://images.unsplash.com/photo-1501386761578-eac5c94b800a?auto=format&fit=crop&w=1200&q=80'],
        tags: const ['concert', 'vip', 'afro-love'],
        badgeLabel: 'Concert',
        isFeatured: true,
        isRecommended: true,
        isTrending: true,
        seatsTotal: 4000,
        seatsRemaining: 280,
        attendeesCount: 3720,
        rating: 4.9,
        reviewCount: 124,
        favoritesCount: 821,
        createdAt: now.subtract(const Duration(days: 10)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a102',
        title: 'Africa Business Summit',
        summary: 'Conférences stratégiques, networking B2B et sessions investisseurs.',
        description: 'Un sommet orienté décideurs avec agenda multi-salles, badges scannables, contrôle d’accès et réservations corporate.',
        category: EventCategoryType.conference,
        city: 'Lomé',
        venue: 'Hôtel 2 Février',
        startsAt: now.add(const Duration(days: 18, hours: 9)),
        endsAt: now.add(const Duration(days: 18, hours: 18)),
        priceCents: 3500000,
        coverImageUrl: 'https://images.unsplash.com/photo-1511578314322-379afb476865?auto=format&fit=crop&w=1200&q=80',
        tags: const ['business', 'networking', 'investors'],
        badgeLabel: 'Conférence',
        isFeatured: true,
        isRecommended: true,
        seatsTotal: 1500,
        seatsRemaining: 124,
        attendeesCount: 1290,
        rating: 4.8,
        reviewCount: 96,
        favoritesCount: 544,
        createdAt: now.subtract(const Duration(days: 8)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a103',
        title: 'AS Douanes vs Jaraaf',
        summary: 'Match premium avec billets standard, tribune et loge entreprise.',
        description: 'Billetterie sportive optimisée avec quota de sièges, alertes de disponibilité et accès rapide au stade.',
        category: EventCategoryType.sport,
        city: 'Dakar',
        venue: 'Stade Léopold Sédar Senghor',
        startsAt: now.add(const Duration(days: 8, hours: 16)),
        endsAt: now.add(const Duration(days: 8, hours: 18)),
        priceCents: 500000,
        coverImageUrl: 'https://images.unsplash.com/photo-1547347298-4074fc3086f0?auto=format&fit=crop&w=1200&q=80',
        tags: const ['match', 'football', 'sport'],
        badgeLabel: 'Match',
        isRecommended: true,
        isTrending: true,
        seatsTotal: 22000,
        seatsRemaining: 3200,
        attendeesCount: 18800,
        rating: 4.6,
        reviewCount: 74,
        favoritesCount: 332,
        createdAt: now.subtract(const Duration(days: 6)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a104',
        title: 'Afro Vibes Festival',
        summary: 'Festival outdoor avec food court, DJ sets et pass multi-jours.',
        description: 'Gestion de festival avec plusieurs zones, capacité live, favoris et billets QR par journée.',
        category: EventCategoryType.festival,
        city: 'Abidjan',
        venue: 'Place de l’Indépendance',
        startsAt: now.add(const Duration(days: 24, hours: 18)),
        endsAt: now.add(const Duration(days: 25, hours: 2)),
        priceCents: 2000000,
        coverImageUrl: 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?auto=format&fit=crop&w=1200&q=80',
        tags: const ['festival', 'afro', 'soirée'],
        badgeLabel: 'Festival',
        isFeatured: true,
        isRecommended: true,
        seatsTotal: 8000,
        seatsRemaining: 0,
        attendeesCount: 8000,
        rating: 4.9,
        reviewCount: 188,
        favoritesCount: 1184,
        createdAt: now.subtract(const Duration(days: 14)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a105',
        title: 'Le Rire du Continent',
        summary: 'Stand-up panafricain avec placement numéroté et zone photo.',
        description: 'Spectacle premium pensé pour une expérience fluide: réservations instantanées, ticket QR et assistance sur site.',
        category: EventCategoryType.spectacle,
        city: 'Dakar',
        venue: 'Institut Français',
        startsAt: now.add(const Duration(days: 5, hours: 20)),
        endsAt: now.add(const Duration(days: 5, hours: 22)),
        priceCents: 1000000,
        coverImageUrl: 'https://images.unsplash.com/photo-1527224538127-2104bb71c51b?auto=format&fit=crop&w=1200&q=80',
        tags: const ['humour', 'spectacle', 'culture'],
        badgeLabel: 'Spectacle',
        isRecommended: false,
        isTrending: true,
        seatsTotal: 950,
        seatsRemaining: 84,
        attendeesCount: 866,
        rating: 4.7,
        reviewCount: 45,
        favoritesCount: 167,
        createdAt: now.subtract(const Duration(days: 4)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a106',
        title: 'Salon International de l’Auto',
        summary: 'Exposition, essais sur place et networking constructeurs.',
        description: 'Un salon B2C/B2B prêt pour la production avec réservations multi-pass, sessions partenaires et suivi visiteurs.',
        category: EventCategoryType.culture,
        city: 'Abidjan',
        venue: 'Parc des Expositions',
        startsAt: now.add(const Duration(days: 37, hours: 10)),
        endsAt: now.add(const Duration(days: 37, hours: 19)),
        priceCents: 750000,
        coverImageUrl: 'https://images.unsplash.com/photo-1503376780353-7e6692767b70?auto=format&fit=crop&w=1200&q=80',
        tags: const ['expo', 'auto', 'innovation'],
        badgeLabel: 'Exposition',
        isRecommended: false,
        seatsTotal: 5000,
        seatsRemaining: 640,
        attendeesCount: 4360,
        rating: 4.5,
        reviewCount: 39,
        favoritesCount: 120,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      ThixEvent(
        id: '77b0c4f1-7baf-4c19-a55b-6b3260f4a107',
        title: 'THIX Builders Meetup',
        summary: 'Rencontre gratuite produit/tech avec panel founders et démos live.',
        description: 'Format networking agile avec inscription gratuite, jauge limitée et liste d’attente automatisable côté backend.',
        category: EventCategoryType.networking,
        city: 'Abidjan',
        venue: 'Plateau Hub',
        startsAt: now.add(const Duration(days: 3, hours: 18)),
        endsAt: now.add(const Duration(days: 3, hours: 21)),
        priceCents: 0,
        coverImageUrl: 'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1200&q=80',
        tags: const ['meetup', 'startup', 'networking'],
        badgeLabel: 'Meetup',
        isRecommended: true,
        seatsTotal: 280,
        seatsRemaining: 36,
        attendeesCount: 244,
        rating: 4.8,
        reviewCount: 18,
        favoritesCount: 76,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    final bookings = <EventTicketBooking>[
      EventTicketBooking(
        id: 'booking-seed-1',
        eventId: '77b0c4f1-7baf-4c19-a55b-6b3260f4a107',
        eventTitle: 'THIX Builders Meetup',
        eventDate: now.add(const Duration(days: 3, hours: 18)),
        eventVenue: 'Plateau Hub',
        coverImageUrl: 'https://images.unsplash.com/photo-1515169067868-5387ec356754?auto=format&fit=crop&w=1200&q=80',
        quantity: 1,
        totalPriceCents: 0,
        currency: 'XOF',
        status: EventTicketStatus.confirmed,
        ticketCode: 'THX-202707-1201',
        qrPayload: 'thix-event:77b0c4f1-7baf-4c19-a55b-6b3260f4a107:seed',
        createdAt: now.subtract(const Duration(hours: 5)),
        attendeeName: 'Vous',
      ),
    ];

    return EventModuleSnapshot(
      events: events,
      bookings: bookings,
      favoriteEventIds: {'77b0c4f1-7baf-4c19-a55b-6b3260f4a101', '77b0c4f1-7baf-4c19-a55b-6b3260f4a107'},
    );
  }
}
