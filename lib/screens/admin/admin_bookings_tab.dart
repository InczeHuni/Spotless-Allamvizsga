import 'package:flutter/material.dart';
import '../../models/booking_model.dart';
import '../../services/booking_service.dart';
import '../../services/notification_service.dart';

class AdminBookingsTab extends StatefulWidget {
  const AdminBookingsTab({super.key});

  @override
  State<AdminBookingsTab> createState() => _AdminBookingsTabState();
}

class _AdminBookingsTabState extends State<AdminBookingsTab> {
  final _bookingService = BookingService();
  DateTime _filterDate = DateTime.now();
  bool _filterByDate = false;

  void _showManualBlockSlotDialog(BuildContext context) {
    final clientNameController = TextEditingController(text: 'Manuális zárolás');
    final clientPhoneController = TextEditingController(text: '+40 700 000 000');
    final carDetailsController = TextEditingController(text: 'Mosó karbantartás / Zárva');
    final serviceNameController = TextEditingController(text: 'Sáv lezárása');
    final priceController = TextEditingController(text: '0');
    final durationController = TextEditingController(text: '60');

    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Idősáv manuális zárolása'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: clientNameController,
                      decoration: const InputDecoration(labelText: 'Megnevezés / Ügyfél'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: carDetailsController,
                      decoration: const InputDecoration(labelText: 'Részletek / Autó'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            child: Text('${selectedDate.year}.${selectedDate.month}.${selectedDate.day}'),
                            onPressed: () async {
                              final d = await showDatePicker(
                                context: context,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (d != null) setDialogState(() => selectedDate = d);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            child: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                            onPressed: () async {
                              final t = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                                builder: (context, child) {
                                  return MediaQuery(
                                    data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                    child: child!,
                                  );
                                },
                              );
                              if (t != null) setDialogState(() => selectedTime = t);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Időtartam (perc)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mégse'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final start = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );
                    final duration = int.tryParse(durationController.text) ?? 60;

                    try {
                      await _bookingService.createBookingWithTransaction(
                        userId: 'admin_block',
                        userName: clientNameController.text,
                        userPhone: clientPhoneController.text,
                        carId: 'manual',
                        carDetails: carDetailsController.text,
                        serviceId: 'manual',
                        serviceName: serviceNameController.text,
                        price: double.tryParse(priceController.text) ?? 0.0,
                        startTime: start,
                        durationMinutes: duration,
                      );

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Idősáv sikeresen lezárva!')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Zárolás mentése'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Dátum szűrő és sáv zároló sáv
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              FilterChip(
                selected: _filterByDate,
                label: Text(
                  _filterByDate
                      ? 'Szűrés: ${_filterDate.year}.${_filterDate.month}.${_filterDate.day}'
                      : 'Összes foglalás',
                ),
                onSelected: (val) async {
                  if (val) {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _filterDate,
                      firstDate: DateTime(2025),
                      lastDate: DateTime(2027),
                    );
                    if (picked != null) {
                      setState(() {
                        _filterDate = picked;
                        _filterByDate = true;
                      });
                    }
                  } else {
                    setState(() => _filterByDate = false);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showManualBlockSlotDialog(context),
                icon: const Icon(Icons.block, size: 16),
                label: const Text('Sáv zárolása'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800),
              ),
            ],
          ),
        ),

        // Foglalások listája StreamBuilder-rel
        Expanded(
          child: StreamBuilder<List<BookingModel>>(
            stream: _bookingService.getAllBookingsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              var bookings = snapshot.data ?? [];

              if (_filterByDate) {
                bookings = bookings.where((b) {
                  return b.startTime.year == _filterDate.year &&
                      b.startTime.month == _filterDate.month &&
                      b.startTime.day == _filterDate.day;
                }).toList();
              }

              if (bookings.isEmpty) {
                return const Center(
                  child: Text('Nincs megjeleníthető foglalás ezen a napon.'),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  return _buildAdminBookingCard(context, booking);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAdminBookingCard(BuildContext context, BookingModel booking) {
    Color statusColor;
    String statusText;
    switch (booking.status) {
      case 'confirmed':
        statusColor = Colors.green;
        statusText = 'MEGERŐSÍTVE';
        break;
      case 'completed':
        statusColor = Colors.blue;
        statusText = 'BEFEJEZVE';
        break;
      case 'cancelled':
        statusColor = Colors.red;
        statusText = 'LEMONDVA';
        break;
      default:
        statusColor = Colors.grey;
        statusText = booking.status.toUpperCase();
    }

    final dateStr =
        '${booking.startTime.month.toString().padLeft(2, '0')}.${booking.startTime.day.toString().padLeft(2, '0')}. ${booking.startTime.hour.toString().padLeft(2, '0')}:${booking.startTime.minute.toString().padLeft(2, '0')} - ${booking.endTime.hour.toString().padLeft(2, '0')}:${booking.endTime.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor,
          child: const Icon(Icons.cleaning_services, color: Colors.white, size: 20),
        ),
        title: Text(
          '${booking.userName} (${booking.carDetails})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text('$dateStr • ${booking.serviceName} (${booking.price.toStringAsFixed(0)} LEI)'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(40),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            statusText,
            style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ügyfél telefon: ${booking.userPhone}'),
                Text('Szolgáltatás: ${booking.serviceName}'),
                Text('Ár: ${booking.price.toStringAsFixed(0)} LEI'),
                const SizedBox(height: 12),
                const Text('Státusz módosítása:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        ),
                        onPressed: booking.isCompleted
                            ? null
                            : () async {
                                await _bookingService.updateBookingStatus(booking.id, 'completed');
                                await NotificationService().showNotification(
                                  id: booking.id.hashCode,
                                  title: 'Spotless - Elkészült az autód! ✨',
                                  body: 'Kedves ${booking.userName}, a(z) ${booking.carDetails} autó mosása befejeződött és átvehető a gyergyószentmiklósi mosóban!',
                                );
                              },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Befejezve', maxLines: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        ),
                        onPressed: booking.isConfirmed
                            ? null
                            : () async {
                                await _bookingService.updateBookingStatus(booking.id, 'confirmed');
                              },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Megerősítve', maxLines: 1),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                        ),
                        onPressed: booking.isCancelled
                            ? null
                            : () async {
                                await _bookingService.updateBookingStatus(booking.id, 'cancelled');
                                await NotificationService().cancelReminder(booking.startTime.millisecondsSinceEpoch ~/ 1000);
                                await NotificationService().showNotification(
                                  id: booking.id.hashCode,
                                  title: 'Spotless - Foglalás Törölve ❌',
                                  body: 'A(z) ${booking.carDetails} autóra szóló foglalásod lemondásra került.',
                                );
                              },
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text('Lemondás', maxLines: 1),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
