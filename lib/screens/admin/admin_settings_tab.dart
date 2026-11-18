import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/closed_day_model.dart';
import '../../services/auth_service.dart';
import '../../services/service_service.dart';
import '../../services/closed_day_service.dart';

class AdminSettingsTab extends StatefulWidget {
  final UserModel user;
  const AdminSettingsTab({super.key, required this.user});

  @override
  State<AdminSettingsTab> createState() => _AdminSettingsTabState();
}

class _AdminSettingsTabState extends State<AdminSettingsTab> {
  final _closedDayService = ClosedDayService();
  final _serviceService = ServiceService();
  final _authService = AuthService();

  void _showAddClosedDayDialog(BuildContext context) {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Új szabadnap / Zárvatartási nap'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Válassza ki a zárva tartó napot:'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      '${selectedDate.year}.${selectedDate.month.toString().padLeft(2, '0')}.${selectedDate.day.toString().padLeft(2, '0')}.',
                    ),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (d != null) {
                        setDialogState(() => selectedDate = d);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Indoklás (opcionális)',
                      hintText: 'pl. Ünnepnap, Szabadság, Karbantartás',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mégse'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _closedDayService.addClosedDay(
                      date: selectedDate,
                      reason: reasonController.text,
                      adminUid: widget.user.uid,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Zárvatartási nap elmentve!')),
                      );
                    }
                  },
                  child: const Text('Mentés'),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Profil Kártya
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.amber.shade800,
                    child: const Icon(Icons.admin_panel_settings, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.user.name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'ADMINISZTRÁTOR',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                  color: Colors.brown,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(widget.user.email, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        Text(widget.user.phone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Zárvatartási napok kezelése
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Zárvatartási napok / Szabadnapok',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAddClosedDayDialog(context),
                icon: const Icon(Icons.add_task),
                label: const Text('Új szabadnap'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.amber.shade900),
              ),
            ],
          ),
          const SizedBox(height: 8),

          StreamBuilder<List<ClosedDayModel>>(
            stream: _closedDayService.getClosedDaysStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final closedDays = snapshot.data ?? [];

              if (closedDays.isEmpty) {
                return Card(
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Nincs felvéve egyetlen zárvatartási szabadnap sem.'),
                    ),
                  ),
                );
              }

              return Column(
                children: closedDays.map((cd) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.block, color: Colors.red),
                      title: Text(
                        'Zárva: ${cd.date}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Indoklás: ${cd.reason}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          await _closedDayService.deleteClosedDay(cd.date);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Zárvatartási nap törölve (újra nyitva)!')),
                            );
                          }
                        },
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          Text(
            'Rendszer beállítások',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: ListTile(
              leading: const Icon(Icons.dataset, color: Colors.blue),
              title: const Text('Minta mosási csomagok betöltése'),
              subtitle: const Text('Feltölti a rendszert kezdeti mosási csomagokkal, ha még üres.'),
              onTap: () async {
                await _serviceService.seedInitialServicesIfEmpty();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kezdeti szolgáltatások ellenőrizve/betöltve!')),
                  );
                }
              },
            ),
          ),
          const SizedBox(height: 32),

          // Kijelentkezés
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await _authService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Kijelentkezés az Admin felületről'),
            ),
          ),
        ],
      ),
    );
  }
}
