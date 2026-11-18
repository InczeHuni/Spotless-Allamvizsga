import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoContactTab extends StatefulWidget {
  const InfoContactTab({super.key});

  @override
  State<InfoContactTab> createState() => _InfoContactTabState();
}

class _InfoContactTabState extends State<InfoContactTab> {
  // Gyergyószentmiklós, Kossuth Lajos utca 235 (Alszeg) pontos koordinátái
  static const double latitude = 46.712132;
  static const double longitude = 25.562813;
  static final LatLng carWashLocation = LatLng(latitude, longitude);

  static const String companyPhone = '0744 169 817';
  static const String companyPhoneFormatted = '+40744169817';
  static const String companyEmail = 'kontakt@spotless.ro';
  static const String companyAddress = 'Gyergyószentmiklós, Kossuth Lajos utca 235, Hargita megye';

  Position? _currentPosition;
  double? _distanceInKm;
  bool _isLoadingLocation = false;
  String? _locationStatusText;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Bekéri a GPS engedélyt és lekéri a felhasználó aktuális földrajzi helyzetét
  Future<void> _determinePosition() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatusText = 'Aktuális pozíció lekérése...';
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusText = 'A GPS helymeghatározás ki van kapcsolva a telefonon.';
          });
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() {
              _isLoadingLocation = false;
              _locationStatusText = 'Helyhozzáférési engedély megtagadva.';
            });
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _isLoadingLocation = false;
            _locationStatusText = 'A helyhozzáférés véglegesen letiltva a beállításokban.';
          });
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Ellenőrizzük, hogy a pozíció reális-e Romániában (vagy az emulátor amerikai alapértelmezett helye-e)
      // Románia határai kb: lat 43.6 - 48.3, lon 20.2 - 30.0
      bool isInsideRomania = position.latitude >= 43.5 &&
          position.latitude <= 48.5 &&
          position.longitude >= 20.0 &&
          position.longitude <= 30.5;

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;

          if (!isInsideRomania) {
            // Ha az emulátor USA-ban van (pl. Mountain View), ne mutassunk hamis 10000 km-es távolságot
            _locationStatusText = 'GPS: Emulátor / Külső helyszín észlelve (Használja a Google Maps-et)';
            _distanceInKm = null;
          } else {
            double distanceInMeters = Geolocator.distanceBetween(
              position.latitude,
              position.longitude,
              latitude,
              longitude,
            );
            // Hegyi út / kanyargós út tényező Erdélyben (~1.33x a légvonalhoz képest, így 76.7 km -> 102 km)
            _distanceInKm = (distanceInMeters / 1000.0) * 1.33;
            if (distanceInMeters < 150) {
              _locationStatusText = 'Ön jelenleg az autómosónál tartózkodik!';
            } else {
              _locationStatusText = 'Távolság Öntől (közúton): ${_distanceInKm!.toStringAsFixed(0)} km';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
          _locationStatusText = 'Navigációra kész (Gyergyószentmiklós)';
        });
      }
    }
  }

  /// Telefonszám hívása
  Future<void> _makePhoneCall(BuildContext context) async {
    final Uri url = Uri.parse('tel:$companyPhoneFormatted');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        _showSnackbar(context, 'Nem sikerült elindítani a hívást.');
      }
    }
  }

  /// E-mail küldése
  Future<void> _sendEmail(BuildContext context) async {
    final Uri url = Uri.parse('mailto:$companyEmail?subject=Érdeklődés%20-%20Spotless%20Autómosó');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        _showSnackbar(context, 'Nem sikerült megnyitni az e-mail klienst.');
      }
    }
  }

  /// Útvonaltervezés indítása (Google Maps navigáció közvetlenül a céges címre)
  Future<void> _openNavigationRoute(BuildContext context) async {
    // FONTOS: Az origin paramétert teljesen elhagyjuk, így a Google Maps app automatikusan
    // a telefon valós natív GPS-ét használja kiindulópontként, elkerülve az emulátor amerikai hibáját!
    final Uri googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude&destination_place_id=Spotless+Autómosó',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      final Uri geoUrl = Uri.parse('geo:$latitude,$longitude?q=Gyergyószentmiklós,+Kossuth+Lajos+utca+235');
      if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else {
        if (context.mounted) {
          _showSnackbar(context, 'Nem sikerült elindítani a térképes navigációt.');
        }
      }
    }
  }

  void _showSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userMarker = (_currentPosition != null && _distanceInKm != null)
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fejléc Kártya
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withAlpha(200),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                children: [
                  Icon(Icons.directions_car, size: 56, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'Spotless Autómosó & Detailing',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Ahol autód újjászületik.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Térkép & Útvonaltervezés Szekció
          Text(
            'Térkép & Útvonaltervezés',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interaktív Beágyazott OpenStreetMap Térkép
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: carWashLocation,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.example.spotless',
                          ),
                          MarkerLayer(
                            markers: [
                              // Mosó Jelölő
                              Marker(
                                point: carWashLocation,
                                width: 50,
                                height: 50,
                                child: Icon(
                                  Icons.location_on,
                                  size: 46,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              // Saját GPS pozíció Jelölő (csak ha Románián belül van)
                              if (userMarker != null)
                                Marker(
                                  point: userMarker,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.my_location,
                                    size: 32,
                                    color: Colors.green,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Aktuális Helyzet / Távolság Info Sáv
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: _distanceInKm != null && _distanceInKm! < 0.15
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _distanceInKm != null && _distanceInKm! < 0.15
                            ? Colors.green.shade300
                            : Colors.blue.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        _isLoadingLocation
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _distanceInKm != null && _distanceInKm! < 0.15
                                    ? Icons.check_circle
                                    : Icons.near_me,
                                size: 18,
                                color: _distanceInKm != null && _distanceInKm! < 0.15
                                    ? Colors.green
                                    : Colors.blue.shade800,
                              ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _locationStatusText ?? 'Helymeghatározás...',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _distanceInKm != null && _distanceInKm! < 0.15
                                  ? Colors.green.shade900
                                  : Colors.blue.shade900,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 18),
                          tooltip: 'Pozíció frissítése',
                          onPressed: _determinePosition,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Cím kijelzése
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          companyAddress,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Útvonaltervezés indítása gomb
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _openNavigationRoute(context),
                      icon: const Icon(Icons.navigation_outlined),
                      label: const Text(
                        'Útvonaltervezés indítása (Google Maps)',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Kapcsolat & Nyitvatartás Szekció
          Text(
            'Céges Kapcsolat & Nyitvatartás',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Telefonszám gomb
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: const Icon(Icons.phone, color: Colors.green),
              ),
              title: const Text('Céges Telefonszám'),
              subtitle: const Text(companyPhone, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              trailing: const Icon(IconData(0xe163, fontFamily: 'MaterialIcons'), color: Colors.green), // call_made icon fallback or direct
              onTap: () => _makePhoneCall(context),
            ),
          ),
          const SizedBox(height: 8),

          // E-mail cím gomb
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: const Icon(Icons.email, color: Colors.blue),
              ),
              title: const Text('Céges E-mail Cím'),
              subtitle: const Text(companyEmail, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              trailing: const Icon(Icons.mail_outline, color: Colors.blue),
              onTap: () => _sendEmail(context),
            ),
          ),
          const SizedBox(height: 16),

          // Nyitvatartás Kártya
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time_filled, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      const Text(
                        'Nyitvatartási Idő',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildScheduleRow('Hétfő - Péntek:', '08:00 - 17:00', Colors.black87),
                  const SizedBox(height: 8),
                  _buildScheduleRow('Szombat:', '08:00 - 14:00', Colors.black87),
                  const SizedBox(height: 8),
                  _buildScheduleRow('Vasárnap:', 'ZÁRVA', Colors.red),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(String day, String time, Color timeColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),),
        Text(
          time,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: timeColor),
        ),
      ],
    );
  }
}
