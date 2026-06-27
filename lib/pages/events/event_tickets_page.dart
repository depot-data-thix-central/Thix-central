import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:thix_central/pages/events/models/event_models.dart';
import 'package:thix_central/pages/events/repositories/event_repository.dart';
import 'package:thix_central/pages/events/services/event_service.dart';
import 'package:thix_central/theme.dart';

class EventTicketsPage extends StatefulWidget {
  const EventTicketsPage({super.key});

  @override
  State<EventTicketsPage> createState() => _EventTicketsPageState();
}

class _EventTicketsPageState extends State<EventTicketsPage> {
  final ThixEventsRepository _repository = ThixEventsRepository();
  final EventsService _service = const EventsService();
  bool _loading = true;
  List<EventTicketBooking> _bookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookings = await _repository.loadBookings();
    if (!mounted) return;
    setState(() {
      _bookings = bookings;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes billets THIX'),
        leading: IconButton(onPressed: () => context.pop(), icon: const Icon(Icons.arrow_back_ios_new_rounded)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 52, color: AppColors.textSecondary),
                        const SizedBox(height: 12),
                        Text('Aucun billet pour le moment', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 8),
                        Text('Réservez un événement pour générer vos billets et QR codes.', style: context.textStyles.bodyMedium?.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: _bookings.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final booking = _bookings[index];
                    final statusColor = switch (booking.status) {
                      EventTicketStatus.confirmed => AppColors.successGreen,
                      EventTicketStatus.pendingSync => AppColors.accentOrange,
                      EventTicketStatus.cancelled => AppColors.dangerRed,
                    };
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.mainCard),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    booking.coverImageUrl,
                                    width: 84,
                                    height: 84,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 84, height: 84, color: Colors.black12),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(999)),
                                        child: Text(booking.status.label, style: context.textStyles.labelMedium?.copyWith(color: statusColor, fontWeight: FontWeight.w800)),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(booking.eventTitle, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 6),
                                      Text(_service.formatDateTime(booking.eventDate), style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                      Text(booking.eventVenue, style: context.textStyles.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Code billet', style: context.textStyles.labelMedium?.copyWith(color: AppColors.textSecondary)),
                                      const SizedBox(height: 4),
                                      Text(booking.ticketCode, style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 12),
                                      Text('Quantité · ${booking.quantity}', style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                                      Text(_service.formatMoney(booking.totalPriceCents, currency: booking.currency), style: context.textStyles.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.cardBorder)),
                                  child: QrImageView(data: booking.qrPayload, size: 88, foregroundColor: AppColors.darkNavy),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
