import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/services/nearest_contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pulsator/pulsator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const initialCameraPosition = CameraPosition(
    target: LatLng(27.701187, 85.28318),
    zoom: 11.5,
  );

  final DateTime _appStartTime = DateTime.now();
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  double? _myLat;
  double? _myLng;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _listenForAlerts();
  }

  /// Get device location, save it to Firestore for nearest-user lookups.
  Future<void> _initLocation() async {
    final position = await _safeGetPosition();
    if (position != null) {
      _myLat = position.latitude;
      _myLng = position.longitude;
      await NearestContactsService.updateUserLocation(
        position.latitude,
        position.longitude,
      );
    }
  }

  Future<Position?> _safeGetPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      return await Geolocator.getCurrentPosition();
    } catch (_) {
      return null;
    }
  }

  void _listenForAlerts() {
    FirebaseFirestore.instance
        .collection('alerts')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(_appStartTime))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docs.isEmpty) {
            return;
          }

          final alert = snapshot.docs.first;
          final data = alert.data();
          final double? alertLat = (data['latitude'] as num?)?.toDouble();
          final double? alertLng = (data['longitude'] as num?)?.toDouble();

          // Nearest-user filter: only show popup if within 5 km of this device.
          if (_myLat != null &&
              _myLng != null &&
              alertLat != null &&
              alertLng != null) {
            final dist = NearestContactsService.haversineDistance(
              _myLat!,
              _myLng!,
              alertLat,
              alertLng,
            );
            if (dist > 5.0) return; // too far — skip popup
          }

          if (alertLat != null && alertLng != null) {
            _updateMapPosition(alertLat, alertLng, data['name'] ?? '');
          }

          _showPopupAlert(
            data['name'] ?? '',
            data['houseNo'] ?? '',
            data['houseName'] ?? '',
            data['type'] ?? '',
            alertLat,
            alertLng,
          );
        });
  }

  void _updateMapPosition(double lat, double lng, String senderName) {
    final pos = LatLng(lat, lng);
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('alert_location'),
          position: pos,
          infoWindow: InfoWindow(title: 'SOS: $senderName'),
        ),
      };
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(pos, 15));
  }

  void _showPopupAlert(
    String name,
    String houseNo,
    String houseName,
    String type,
    double? lat,
    double? lng,
  ) {
    String distanceText = '';
    if (_myLat != null && _myLng != null && lat != null && lng != null) {
      final dist = NearestContactsService.haversineDistance(
        _myLat!,
        _myLng!,
        lat,
        lng,
      );
      distanceText = '\n\nDistance from you: ${dist.toStringAsFixed(2)} km';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.emergency, size: 45, color: Colors.red),
        title: const Text('Emergency Alert'),
        content: Text(
          'From: $name\n'
          'House No: $houseNo\n'
          'House Name: $houseName\n\n'
          'Category: $type'
          '$distanceText',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Center(
            child: Column(
              children: [
                const SizedBox(height: 30),
                const Text(
                  'Emergency help needed?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Press the button',
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Help will arrive soon',
                  style: TextStyle(fontSize: 12, color: Colors.brown),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/sos');
                  },
                  child: PulseIcon(
                    icon: Icons.sos,
                    pulseColor: Colors.red,
                    iconSize: 44.0,
                    pulseSize: 232.0,
                    innerSize: 65.0,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.add_alert, size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Recent Alert Section',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey),
                        ),
                        child: GoogleMap(
                          myLocationButtonEnabled: true,
                          zoomControlsEnabled: true,
                          initialCameraPosition: initialCameraPosition,
                          markers: _markers,
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const NavBarScreen(currentIndex: 0),
    );
  }
}
