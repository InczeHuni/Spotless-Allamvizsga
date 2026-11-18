import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../models/car_model.dart';
import '../../models/service_model.dart';
import '../../models/booking_model.dart';
import '../../models/closed_day_model.dart';
import '../../services/car_service.dart';
import '../../services/service_service.dart';
import '../../services/booking_service.dart';
import '../../services/closed_day_service.dart';
import '../../utils/license_plate_validator.dart';

class NewBookingTab extends StatefulWidget {
  final UserModel user;
  const NewBookingTab({super.key, required this.user});

  @override
  State<NewBookingTab> createState() => _NewBookingTabState();
}

class _NewBookingTabState extends State<NewBookingTab> {
  final _carService = CarService();
  final _serviceService = ServiceService();
  final _bookingService = BookingService();
  final _closedDayService = ClosedDayService();

  // Autóválasztási állapotok
  bool _useCasualCar = false;
  String? _selectedSavedCarId;

  // Alkalmi autó mezők
  final _casualBrandModelController = TextEditingController();
  final _casualLicensePlateController = TextEditingController();
  bool _saveCasualCarToProfile = true;

  // Szolgáltatás & Dátum/Időállapotok
  ServiceModel? _selectedService;
  DateTime _selectedDate = _getInitialValidDay();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);

  bool _isSubmitting = false;

  static DateTime _getInitialValidDay() {
    DateTime dt = DateTime.now().add(const Duration(days: 1));
    while (dt.weekday == DateTime.sunday) {
      dt = dt.add(const Duration(days: 1));
    }
    return DateTime(dt.year, dt.month, dt.day);
  }

  @override
  void initState() {
    super.initState();
    _serviceService.seedInitialServicesIfEmpty();
  }

  @override
  void dispose() {
    _casualBrandModelController.dispose();
    _casualLicensePlateController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateBooking(List<ClosedDayModel> closedDays, List<CarModel> savedCars) async {
    // 1. Vasárnapi tiltás
    if (_selectedDate.weekday == DateTime.sunday) {
      _showError('A mosó vasárnap zárva tart!');
      return;
    }

    final dateKey = ClosedDayModel.formatDateKey(_selectedDate);
    final isClosedDay = closedDays.any((cd) => cd.date == dateKey);
    if (isClosedDay) {
      final cd = closedDays.firstWhere((element) => element.date == dateKey);
      _showError('A műhely ezen a napon zárva tart! (Indok: ${cd.reason})');
      return;
    }

    // 2. Szolgáltatás Validáció
    if (_selectedService == null) {
      _showError('Kérjük, válasszon egy mosási szolgáltatást!');
      return;
    }

    // 3. Autó Validáció & Adat-előkészítés
    String carId = 'casual';
    String carDetails = '';

    if (_useCasualCar) {
      final brandModel = _casualBrandModelController.text.trim();
      final licensePlate = _casualLicensePlateController.text.trim().toUpperCase();

      if (brandModel.isEmpty || licensePlate.isEmpty) {
        _showError('Kérjük, adja meg az autó márkáját/típusát és rendszámát!');
        return;
      }

      if (!LicensePlateValidator.isValid(licensePlate)) {
        _showError('Érvénytelen rendszám formátum! Kérjük, adjon meg érvényes romániai (pl. CJ 01 ABC, B 123 ABC) vagy magyarországi (pl. ABC-123, AA-AA-123) rendszámot.');
        return;
      }

      final formattedPlate = LicensePlateValidator.format(licensePlate);
      carDetails = '$brandModel - $formattedPlate';

      if (_saveCasualCarToProfile) {
        try {
          await _carService.addCar(
            widget.user.uid,
            brand: brandModel.contains(' ') ? brandModel.split(' ').first : brandModel,
            model: brandModel.contains(' ') ? brandModel.split(' ').sublist(1).join(' ') : 'Típus',
            licensePlate: formattedPlate,
            color: 'Ismeretlen',
            carType: 'sedan',
          );
        } catch (_) {
          // Folytatódhat a foglalás ha a profil mentés nem sikerül
        }
      }
    } else {
      if (_selectedSavedCarId == null || !savedCars.any((c) => c.id == _selectedSavedCarId)) {
        _showError('Kérjük, válasszon egy autót a mentettek közül, vagy adja meg az alkalmi autó adatait!');
        return;
      }
      final car = savedCars.firstWhere((c) => c.id == _selectedSavedCarId);
      carId = car.id;
      carDetails = car.displayName;
    }

    final startTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    if (startTime.isBefore(DateTime.now())) {
      _showError('Kérjük, jövőbeli időpontot válasszon!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _bookingService.createBookingWithTransaction(
        userId: widget.user.uid,
        userName: widget.user.name,
        userPhone: widget.user.phone,
        carId: carId,
        carDetails: carDetails,
        serviceId: _selectedService!.id,
        serviceName: _selectedService!.name,
        price: _selectedService!.price,
        startTime: startTime,
        durationMinutes: _selectedService!.durationMinutes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sikeres időpontfoglalás! ($carDetails - ${_selectedService!.name})'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showError(e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = ClosedDayModel.formatDateKey(_selectedDate);

    return StreamBuilder<List<ClosedDayModel>>(
      stream: _closedDayService.getClosedDaysStream(),
      builder: (context, closedDaysSnapshot) {
        final closedDays = closedDaysSnapshot.data ?? [];
        final isClosedDay = closedDays.any((cd) => cd.date == dateKey);
        final closedReason = isClosedDay
            ? closedDays.firstWhere((cd) => cd.date == dateKey).reason
            : null;

        return StreamBuilder<List<CarModel>>(
          stream: _carService.getUserCarsStream(widget.user.uid),
          builder: (context, carSnapshot) {
            final savedCars = carSnapshot.data ?? [];

            // Ha nincsenek mentett autók, átváltunk alkalmi autóra
            if (savedCars.isEmpty && !_useCasualCar) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_useCasualCar) {
                  setState(() => _useCasualCar = true);
                }
              });
            }

            // Ha van mentett autó és nincs még kiválasztva ID, beállítjuk az elsőt
            if (savedCars.isNotEmpty &&
                (_selectedSavedCarId == null || !savedCars.any((c) => c.id == _selectedSavedCarId))) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedSavedCarId = savedCars.first.id);
                }
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. LÉPÉS: AUTÓ KIVÁLASZTÁSA (MENTETT VAGY ALKAMAI)
                  Text(
                    '1. Autó kiválasztása',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  if (savedCars.isNotEmpty) ...[
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Profilomban mentett autó'),
                          selected: !_useCasualCar,
                          onSelected: (val) {
                            if (val) setState(() => _useCasualCar = false);
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Új / Alkalmi autó'),
                          selected: _useCasualCar,
                          onSelected: (val) {
                            if (val) setState(() => _useCasualCar = true);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (!_useCasualCar && savedCars.isNotEmpty) ...[
                    DropdownButtonFormField<String>(
                      initialValue: savedCars.any((c) => c.id == _selectedSavedCarId)
                          ? _selectedSavedCarId
                          : savedCars.first.id,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.directions_car),
                        border: OutlineInputBorder(),
                        labelText: 'Válasszon mentett autót',
                      ),
                      items: savedCars.map((car) {
                        return DropdownMenuItem<String>(
                          value: car.id,
                          child: Text(car.displayName),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedSavedCarId = val);
                        }
                      },
                    ),
                  ] else ...[
                    // Alkalmi autó megadása
                    TextFormField(
                      controller: _casualBrandModelController,
                      decoration: const InputDecoration(
                        labelText: 'Autó Márka és Típus *',
                        prefixIcon: Icon(Icons.directions_car_outlined),
                        hintText: 'pl. Ford Focus, BMW X5, Dacia Logan',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _casualLicensePlateController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Rendszám *',
                        prefixIcon: Icon(Icons.badge_outlined),
                        hintText: 'pl. ABC-123 vagy CJ 01 ABC',
                      ),
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Autó mentése a profilomba a jövőbeli foglalásokhoz',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _saveCasualCarToProfile,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _saveCasualCarToProfile = val);
                        }
                      },
                    ),
                  ],
                  const SizedBox(height: 24),

                  // 2. LÉPÉS: MOSÁSI SZOLGÁLTATÁS KIVÁLASZTÁSA
                  Text(
                    '2. Válasszon mosási szolgáltatást',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  StreamBuilder<List<ServiceModel>>(
                    stream: _serviceService.getActiveServicesStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final services = snapshot.data ?? [];

                      if (services.isEmpty) {
                        return const Text('Jelenleg nincs elérhető aktív szolgáltatás.');
                      }

                      return Column(
                        children: services.map((service) {
                          final isSelected = _selectedService?.id == service.id;
                          return Card(
                            elevation: isSelected ? 3 : 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              onTap: () => setState(() => _selectedService = service),
                              leading: Icon(
                                Icons.cleaning_services,
                                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey,
                              ),
                              title: Text(
                                service.name,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('${service.description}\nIdőtartam: ${service.formattedDuration}'),
                              trailing: Text(
                                service.formattedPrice,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 3. LÉPÉS: DÁTUM ÉS IDŐPONT VÁLASZTÓ
                  Text(
                    '3. Dátum és kezdeti időpont',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_month),
                          label: Text(
                            '${_selectedDate.year}.${_selectedDate.month.toString().padLeft(2, '0')}.${_selectedDate.day.toString().padLeft(2, '0')}.',
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 90)),
                              selectableDayPredicate: (day) {
                                if (day.weekday == DateTime.sunday) {
                                  return false;
                                }
                                final key = ClosedDayModel.formatDateKey(day);
                                if (closedDays.any((cd) => cd.date == key)) {
                                  return false;
                                }
                                return true;
                              },
                            );
                            if (picked != null) {
                              setState(() => _selectedDate = picked);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (picked != null) {
                              setState(() => _selectedTime = picked);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nyitvatartási & Időtartam info
                  if (_selectedService != null) ...[
                    Builder(builder: (context) {
                      final isSaturday = _selectedDate.weekday == DateTime.saturday;
                      final closeHour = isSaturday ? 14 : 17;

                      final start = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _selectedTime.hour,
                        _selectedTime.minute,
                      );
                      final end = start.add(Duration(minutes: _selectedService!.durationMinutes));
                      final isExceedingClose = end.hour > closeHour || (end.hour == closeHour && end.minute > 0);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isExceedingClose ? Colors.red.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isExceedingClose ? Colors.red.shade300 : Colors.blue.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isExceedingClose ? Icons.warning_amber : Icons.info_outline,
                              color: isExceedingClose ? Colors.red : Colors.blue.shade800,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                isExceedingClose
                                    ? 'Figyelem! ${isSaturday ? "Szombaton" : "Hétköznap"} a mosás befejezése (${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}) túlnyúlik a $closeHour:00 órás zárórán!'
                                    : 'Mosás ideje: ${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')} (${_selectedService!.durationMinutes} perc)\n${isSaturday ? "Szombati" : "Hétköznapi"} nyitvatartás: 08:00 - $closeHour:00',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isExceedingClose ? Colors.red.shade900 : Colors.blue.shade900,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Zárvatartási figyelmeztetés
                  if (isClosedDay) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block, color: Colors.red),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A MŰHELY EZEN A NAPON ZÁRVA TART!\nIndoklás: $closedReason',
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // 4. LÉPÉS: ANONIM FOGLALT IDŐSÁVOK LISTÁJA (SZIGORÚ ADATVÉDELEMMEL)
                  Text(
                    'Foglalt idősávok ezen a napon:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                  ),
                  const SizedBox(height: 6),

                  StreamBuilder<List<BookingModel>>(
                    stream: _bookingService.getConfirmedBookingsForDayStream(_selectedDate),
                    builder: (context, bookingSnapshot) {
                      if (bookingSnapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        );
                      }

                      final confirmedBookings = bookingSnapshot.data ?? [];

                      if (confirmedBookings.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Még nincs egyetlen foglalás sem ezen a napon. A nap teljesen szabad!',
                                  style: TextStyle(fontSize: 12, color: Colors.green),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: confirmedBookings.map((b) {
                            final startStr =
                                '${b.startTime.hour.toString().padLeft(2, '0')}:${b.startTime.minute.toString().padLeft(2, '0')}';
                            final endStr =
                                '${b.endTime.hour.toString().padLeft(2, '0')}:${b.endTime.minute.toString().padLeft(2, '0')}';
                            return Chip(
                              avatar: const Icon(Icons.lock_clock, size: 16, color: Colors.red),
                              label: Text(
                                '$startStr - $endStr (Foglalt)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              backgroundColor: Colors.red.shade50,
                              side: BorderSide(color: Colors.red.shade200),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // FOGLALÁS MEGERŐSÍTÉSE GOMB
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: (_isSubmitting || isClosedDay)
                          ? null
                          : () => _handleCreateBooking(closedDays, savedCars),
                      icon: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline),
                      label: Text(
                        _isSubmitting ? 'Foglalás ellenőrzése...' : 'Időpontfoglalás megerősítése',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
