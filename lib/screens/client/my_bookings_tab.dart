import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';

class MyBookingsTab extends StatelessWidget {
  final UserModel user;
  const MyBookingsTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final bookingService = BookingService();

    return StreamBuilder<List<BookingModel>>(
      stream: bookingService.getUserBookingsStream(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Hiba a foglalások betöltésekor: ${snapshot.error}'));
        }

        final bookings = snapshot.data ?? [];

        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.calendar_today, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                const Text(
                  'Még nem volt egyetlen időpontfoglalása sem.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return _buildBookingCard(context, bookingService, booking);
          },
        );
      },
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    BookingService bookingService,
    BookingModel booking,
  ) {
    Color statusColor;
    String statusText;

    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'Megerősítve';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'Befejezve';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'Lemondva';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status;
    }

    final dateStr =
        '${booking.startTime.year}.${booking.startTime.month.toString().padLeft(2, '0')}.${booking.startTime.day.toString().padLeft(2, '0')}. ${booking.startTime.hour.toString().padLeft(2, '0')}:${booking.startTime.minute.toString().padLeft(2, '0')} - ${booking.endTime.hour.toString().padLeft(2, '0')}:${booking.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.directions_car, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  booking.carDetails,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[800], fontSize: 13),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${booking.price.toStringAsFixed(0)} LEI',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (booking.isConfirmed && booking.startTime.isAfter(DateTime.now()))
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Foglalás lemondása'),
                          content: const Text('Biztosan le szeretné mondani ezt az időpontot?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Mégse'),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Igen, lemondom'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await bookingService.cancelBooking(booking.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('A foglalás lemondásra került.')),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Lemondás'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
