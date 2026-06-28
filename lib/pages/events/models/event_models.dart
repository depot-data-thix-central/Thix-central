import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

const _eventCategoryMetadata = <EventCategoryType, ({String key, String label, IconData icon, Color color})>{
  EventCategoryType.all: (key: 'all', label: 'Tous', icon: Icons.apps_rounded, color: Color(0xFF6D5CFF)),
  EventCategoryType.concert: (key: 'concert', label: 'Concerts', icon: Icons.music_note_rounded, color: Color(0xFF8B5CF6)),
  EventCategoryType.spectacle: (key: 'spectacle', label: 'Spectacles', icon: Icons.theater_comedy_rounded, color: Color(0xFFF59E0B)),
  EventCategoryType.conference: (key: 'conference', label: 'Conférences', icon: Icons.mic_external_on_rounded, color: Color(0xFF3B82F6)),
  EventCategoryType.sport: (key: 'sport', label: 'Sport', icon: Icons.emoji_events_rounded, color: Color(0xFF22C55E)),
  EventCategoryType.festival: (key: 'festival', label: 'Festivals', icon: Icons.local_activity_rounded, color: Color(0xFFEC4899)),
  EventCategoryType.culture: (key: 'culture', label: 'Culture & Art', icon: Icons.account_balance_rounded, color: Color(0xFFF97316)),
  EventCategoryType.networking: (key: 'networking', label: 'Business', icon: Icons.groups_rounded, color: Color(0xFF14B8A6)),
};

enum EventCategoryType { all, concert, spectacle, conference, sport, festival, culture, networking }

extension EventCategoryTypeX on EventCategoryType {
  String get key => _eventCategoryMetadata[this]!.key;
  String get label => _eventCategoryMetadata[this]!.label;
  IconData get icon => _eventCategoryMetadata[this]!.icon;
  Color get color => _eventCategoryMetadata[this]!.color;

  static EventCategoryType fromKey(String? raw) {
    final normalized = (raw ?? '').trim().toLowerCase();
    return EventCategoryType.values.firstWhere(
      (value) => value.key == normalized,
      orElse: () => EventCategoryType.concert,
    );
  }
}

enum EventSortOption { featured, newest, date, priceLowToHigh, popularity }

enum EventTicketStatus { confirmed, pendingSync, cancelled }

extension EventTicketStatusX on EventTicketStatus {
  String get key => switch (this) {
        EventTicketStatus.confirmed => 'confirmed',
        EventTicketStatus.pendingSync => 'pending_sync',
        EventTicketStatus.cancelled => 'cancelled',
      };

  String get label => switch (this) {
        EventTicketStatus.confirmed => 'Confirmé',
        EventTicketStatus.pendingSync => 'En attente sync',
        EventTicketStatus.cancelled => 'Annulé',
      };

  static EventTicketStatus fromKey(String? raw) {
    return EventTicketStatus.values.firstWhere(
      (value) => value.key == (raw ?? '').trim().toLowerCase(),
      orElse: () => EventTicketStatus.confirmed,
    );
  }
}

@immutable
class EventCategoryChip {
  const EventCategoryChip({required this.type, required this.itemCount});

  final EventCategoryType type;
  final int itemCount;

  String get key => type.key;
  String get label => type.label;
  IconData get icon => type.icon;
  Color get color => type.color;
}

@immutable
class ThixEvent {
  const ThixEvent({
    required this.id,
    required this.title,
    required this.summary,
    required this.description,
    required this.category,
    required this.city,
    required this.venue,
    required this.startsAt,
    this.endsAt,
    required this.priceCents,
    this.currency = 'XOF',
    required this.coverImageUrl,
    this.galleryUrls = const <String>[],
    this.tags = const <String>[],
    this.badgeLabel,
    this.organizerName = 'THIX Events Studio',
    this.organizerVerified = true,
    this.isFeatured = false,
    this.isRecommended = false,
    this.isTrending = false,
    this.isPublished = true,
    this.seatsTotal = 0,
    this.seatsRemaining = 0,
    this.attendeesCount = 0,
    this.rating = 0,
    this.reviewCount = 0,
    this.favoritesCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String summary;
  final String description;
  final EventCategoryType category;
  final String city;
  final String venue;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int priceCents;
  final String currency;
  final String coverImageUrl;
  final List<String> galleryUrls;
  final List<String> tags;
  final String? badgeLabel;
  final String organizerName;
  final bool organizerVerified;
  final bool isFeatured;
  final bool isRecommended;
  final bool isTrending;
  final bool isPublished;
  final int seatsTotal;
  final int seatsRemaining;
  final int attendeesCount;
  final double rating;
  final int reviewCount;
  final int favoritesCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isFree => priceCents <= 0;
  bool get isSoldOut => seatsTotal > 0 && seatsRemaining <= 0;
  bool get isAlmostFull => !isSoldOut && seatsTotal > 0 && seatsRemaining > 0 && seatsRemaining <= 20;
  double get occupancyRate {
    if (seatsTotal <= 0) return 0;
    return ((seatsTotal - seatsRemaining) / seatsTotal).clamp(0, 1).toDouble();
  }

  ThixEvent copyWith({
    String? id,
    String? title,
    String? summary,
    String? description,
    EventCategoryType? category,
    String? city,
    String? venue,
    DateTime? startsAt,
    DateTime? endsAt,
    int? priceCents,
    String? currency,
    String? coverImageUrl,
    List<String>? galleryUrls,
    List<String>? tags,
    Object? badgeLabel = _sentinel,
    String? organizerName,
    bool? organizerVerified,
    bool? isFeatured,
    bool? isRecommended,
    bool? isTrending,
    bool? isPublished,
    int? seatsTotal,
    int? seatsRemaining,
    int? attendeesCount,
    double? rating,
    int? reviewCount,
    int? favoritesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ThixEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      description: description ?? this.description,
      category: category ?? this.category,
      city: city ?? this.city,
      venue: venue ?? this.venue,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      priceCents: priceCents ?? this.priceCents,
      currency: currency ?? this.currency,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      tags: tags ?? this.tags,
      badgeLabel: identical(badgeLabel, _sentinel) ? this.badgeLabel : badgeLabel as String?,
      organizerName: organizerName ?? this.organizerName,
      organizerVerified: organizerVerified ?? this.organizerVerified,
      isFeatured: isFeatured ?? this.isFeatured,
      isRecommended: isRecommended ?? this.isRecommended,
      isTrending: isTrending ?? this.isTrending,
      isPublished: isPublished ?? this.isPublished,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsRemaining: seatsRemaining ?? this.seatsRemaining,
      attendeesCount: attendeesCount ?? this.attendeesCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ThixEvent.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic raw) {
      if (raw is List) {
        return raw.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
      }
      return const <String>[];
    }

    return ThixEvent(
      id: (json['id'] ?? '').toString(),
      title: (json['title'] ?? '').toString(),
      summary: (json['summary'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      category: EventCategoryTypeX.fromKey(json['category']?.toString()),
      city: (json['city'] ?? '').toString(),
      venue: (json['venue'] ?? '').toString(),
      startsAt: DateTime.tryParse((json['starts_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      endsAt: json['ends_at'] == null ? null : DateTime.tryParse(json['ends_at'].toString()),
      priceCents: (json['price_cents'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'XOF').toString(),
      coverImageUrl: (json['cover_image_url'] ?? '').toString(),
      galleryUrls: parseList(json['gallery_urls']),
      tags: parseList(json['tags']),
      badgeLabel: json['badge_label']?.toString(),
      organizerName: (json['organizer_name'] ?? 'THIX Events Studio').toString(),
      organizerVerified: json['organizer_verified'] as bool? ?? true,
      isFeatured: json['is_featured'] as bool? ?? false,
      isRecommended: json['is_recommended'] as bool? ?? false,
      isTrending: json['is_trending'] as bool? ?? false,
      isPublished: json['is_published'] as bool? ?? true,
      seatsTotal: (json['seats_total'] as num?)?.toInt() ?? 0,
      seatsRemaining: (json['seats_remaining'] as num?)?.toInt() ?? 0,
      attendeesCount: (json['attendees_count'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      reviewCount: (json['review_count'] as num?)?.toInt() ?? 0,
      favoritesCount: (json['favorites_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary': summary,
        'description': description,
        'category': category.key,
        'city': city,
        'venue': venue,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt?.toIso8601String(),
        'price_cents': priceCents,
        'currency': currency,
        'cover_image_url': coverImageUrl,
        'gallery_urls': galleryUrls,
        'tags': tags,
        'badge_label': badgeLabel,
        'organizer_name': organizerName,
        'organizer_verified': organizerVerified,
        'is_featured': isFeatured,
        'is_recommended': isRecommended,
        'is_trending': isTrending,
        'is_published': isPublished,
        'seats_total': seatsTotal,
        'seats_remaining': seatsRemaining,
        'attendees_count': attendeesCount,
        'rating': rating,
        'review_count': reviewCount,
        'favorites_count': favoritesCount,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

@immutable
class EventTicketBooking {
  const EventTicketBooking({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.eventDate,
    required this.eventVenue,
    required this.coverImageUrl,
    required this.quantity,
    required this.totalPriceCents,
    required this.currency,
    required this.status,
    required this.ticketCode,
    required this.qrPayload,
    required this.createdAt,
    this.attendeeName,
    this.attendeeEmail,
  });

  final String id;
  final String eventId;
  final String eventTitle;
  final DateTime eventDate;
  final String eventVenue;
  final String coverImageUrl;
  final int quantity;
  final int totalPriceCents;
  final String currency;
  final EventTicketStatus status;
  final String ticketCode;
  final String qrPayload;
  final DateTime createdAt;
  final String? attendeeName;
  final String? attendeeEmail;

  EventTicketBooking copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    DateTime? eventDate,
    String? eventVenue,
    String? coverImageUrl,
    int? quantity,
    int? totalPriceCents,
    String? currency,
    EventTicketStatus? status,
    String? ticketCode,
    String? qrPayload,
    DateTime? createdAt,
    Object? attendeeName = _sentinel,
    Object? attendeeEmail = _sentinel,
  }) {
    return EventTicketBooking(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventDate: eventDate ?? this.eventDate,
      eventVenue: eventVenue ?? this.eventVenue,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      quantity: quantity ?? this.quantity,
      totalPriceCents: totalPriceCents ?? this.totalPriceCents,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      ticketCode: ticketCode ?? this.ticketCode,
      qrPayload: qrPayload ?? this.qrPayload,
      createdAt: createdAt ?? this.createdAt,
      attendeeName: identical(attendeeName, _sentinel) ? this.attendeeName : attendeeName as String?,
      attendeeEmail: identical(attendeeEmail, _sentinel) ? this.attendeeEmail : attendeeEmail as String?,
    );
  }

  factory EventTicketBooking.fromJson(Map<String, dynamic> json) {
    return EventTicketBooking(
      id: (json['id'] ?? '').toString(),
      eventId: (json['event_id'] ?? '').toString(),
      eventTitle: (json['event_title'] ?? '').toString(),
      eventDate: DateTime.tryParse((json['event_date'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      eventVenue: (json['event_venue'] ?? '').toString(),
      coverImageUrl: (json['cover_image_url'] ?? '').toString(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      totalPriceCents: (json['total_price_cents'] as num?)?.toInt() ?? 0,
      currency: (json['currency'] ?? 'XOF').toString(),
      status: EventTicketStatusX.fromKey(json['status']?.toString()),
      ticketCode: (json['ticket_code'] ?? '').toString(),
      qrPayload: (json['qr_payload'] ?? '').toString(),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString()) ?? DateTime.fromMillisecondsSinceEpoch(0),
      attendeeName: json['attendee_name']?.toString(),
      attendeeEmail: json['attendee_email']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'event_id': eventId,
        'event_title': eventTitle,
        'event_date': eventDate.toIso8601String(),
        'event_venue': eventVenue,
        'cover_image_url': coverImageUrl,
        'quantity': quantity,
        'total_price_cents': totalPriceCents,
        'currency': currency,
        'status': status.key,
        'ticket_code': ticketCode,
        'qr_payload': qrPayload,
        'created_at': createdAt.toIso8601String(),
        'attendee_name': attendeeName,
        'attendee_email': attendeeEmail,
      };
}

@immutable
class EventModuleSnapshot {
  const EventModuleSnapshot({
    required this.events,
    required this.bookings,
    this.favoriteEventIds = const <String>{},
  });

  final List<ThixEvent> events;
  final List<EventTicketBooking> bookings;
  final Set<String> favoriteEventIds;

  EventModuleSnapshot copyWith({
    List<ThixEvent>? events,
    List<EventTicketBooking>? bookings,
    Set<String>? favoriteEventIds,
  }) {
    return EventModuleSnapshot(
      events: events ?? this.events,
      bookings: bookings ?? this.bookings,
      favoriteEventIds: favoriteEventIds ?? this.favoriteEventIds,
    );
  }
}

const Object _sentinel = Object();
