import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/car_model.dart';
import '../../services/auth_service.dart';
import '../../services/car_service.dart';
import '../../utils/license_plate_validator.dart';

class ProfileCarsTab extends StatelessWidget {
  final UserModel user;
  const ProfileCarsTab({super.key, required this.user});

  void _showAddCarDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final licensePlateController = TextEditingController();
    final colorController = TextEditingController();
    String selectedCarType = 'sedan';

    final carTypes = [
      {'value': 'sedan', 'label': 'Sedan / Limuzin'},
      {'value': 'suv', 'label': 'SUV / Crossover / 4x4'},
      {'value': 'hatchback', 'label': 'Hatchback'},
      {'value': 'coupe', 'label': 'Kupé / Cabrio'},
      {'value': 'van', 'label': 'Egyterű / Kombi / Minivan'},
      {'value': 'other', 'label': 'Egyéb kategória'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Új autó hozzáadása'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: brandController,
                        decoration: const InputDecoration(
                          labelText: 'Márka *',
                          hintText: 'pl. Audi, BMW, Dacia, Volkswagen',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Kötelező mező' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Modell *',
                          hintText: 'pl. A4, X5, Logan, Golf',
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Kötelező mező' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: licensePlateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Rendszám *',
                          hintText: 'pl. CJ 01 ABC, B 123 ABC, ABC-123',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Kötelező mező';
                          if (!LicensePlateValidator.isValid(v)) {
                            return 'Érvénytelen rendszám formátum!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: colorController,
                        decoration: const InputDecoration(
                          labelText: 'Szín',
                          hintText: 'pl. Fekete, Ezüst, Fehér',
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCarType,
                        decoration: const InputDecoration(
                          labelText: 'Kategória / Típus',
                        ),
                        items: carTypes.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['value'],
                            child: Text(item['label']!),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() => selectedCarType = val);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Mégse'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final formattedPlate = LicensePlateValidator.format(licensePlateController.text);

                    await CarService().addCar(
                      user.uid,
                      brand: brandController.text,
                      model: modelController.text,
                      licensePlate: formattedPlate,
                      color: colorController.text.isEmpty ? 'Ismeretlen' : colorController.text,
                      carType: selectedCarType,
                    );

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Autó sikeresen hozzáadva!')),
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
    final carService = CarService();
    final authService = AuthService();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profil Kártya
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(user.email, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(user.phone, style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Autóim Fejléc + Új autó gomb
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Autóim',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddCarDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Új autó'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Autók listája StreamBuilder-rel
          StreamBuilder<List<CarModel>>(
            stream: carService.getUserCarsStream(user.uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final cars = snapshot.data ?? [];

              if (cars.isEmpty) {
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Még nem adott hozzá autót. Kattintson az "Új autó" gombra!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cars.length,
                itemBuilder: (context, index) {
                  final car = cars[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.directions_car, size: 32, color: Colors.blue),
                      title: Text(
                        '${car.brand} ${car.model}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Rendszám: ${car.licensePlate} • Szín: ${car.color}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Autó törlése'),
                              content: Text('Biztosan törölni szeretné ezt az autót (${car.displayName})?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Mégse'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Törlés'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await carService.deleteCar(user.uid, car.id);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Kijelentkezés gomb
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                await authService.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Kijelentkezés'),
            ),
          ),
        ],
      ),
    );
  }
}
