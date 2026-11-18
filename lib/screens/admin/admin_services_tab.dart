import 'package:flutter/material.dart';
import '../../models/service_model.dart';
import '../../services/service_service.dart';

class AdminServicesTab extends StatelessWidget {
  const AdminServicesTab({super.key});

  void _showAddOrEditServiceDialog(BuildContext context, [ServiceModel? existingService]) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: existingService?.name ?? '');
    final descController = TextEditingController(text: existingService?.description ?? '');
    final priceController = TextEditingController(
      text: existingService != null ? existingService.price.toStringAsFixed(0) : '',
    );
    final durationController = TextEditingController(
      text: existingService != null ? existingService.durationMinutes.toString() : '45',
    );
    bool isActive = existingService?.isActive ?? true;

    final serviceService = ServiceService();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(existingService == null ? 'Új szolgáltatás hozzáadása' : 'Szolgáltatás szerkesztése'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Szolgáltatás neve *'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Kötelező mező' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Leírás'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Ár (LEI) *'),
                        validator: (v) => (v == null || double.tryParse(v) == null) ? 'Adjon meg érvényes árat!' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Időtartam (perc) *'),
                        validator: (v) => (v == null || int.tryParse(v) == null) ? 'Adjon meg érvényes időtartamot!' : null,
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Aktív (időpont foglalható rá)'),
                        value: isActive,
                        onChanged: (val) => setDialogState(() => isActive = val),
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

                    final price = double.parse(priceController.text);
                    final duration = int.parse(durationController.text);

                    if (existingService == null) {
                      await serviceService.addService(
                        name: nameController.text,
                        description: descController.text,
                        price: price,
                        durationMinutes: duration,
                        isActive: isActive,
                      );
                    } else {
                      final updated = ServiceModel(
                        id: existingService.id,
                        name: nameController.text.trim(),
                        description: descController.text.trim(),
                        price: price,
                        durationMinutes: duration,
                        isActive: isActive,
                      );
                      await serviceService.updateService(updated);
                    }

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Szolgáltatás elmentve!')),
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
    final serviceService = ServiceService();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mosási csomagok',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddOrEditServiceDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Új csomag'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: serviceService.getAllServicesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final services = snapshot.data ?? [];

                if (services.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Még nincs szolgáltatás hozzáadva.'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => serviceService.seedInitialServicesIfEmpty(),
                          child: const Text('Minta szolgáltatások betöltése'),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: service.isActive ? Colors.blue : Colors.grey,
                          child: const Icon(Icons.cleaning_services, color: Colors.white),
                        ),
                        title: Text(
                          service.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${service.description}\n${service.formattedPrice} • ${service.formattedDuration}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              value: service.isActive,
                              onChanged: (val) {
                                serviceService.toggleServiceStatus(service.id, val);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showAddOrEditServiceDialog(context, service),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
