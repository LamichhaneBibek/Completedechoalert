import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
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
  
  @override
  void initState() {
    super.initState();

    FirebaseFirestore.instance
        .collection('alerts')
        .where('timestamp', isGreaterThan: Timestamp.fromDate(_appStartTime))
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen(
      (snapshot) {
        if (snapshot.docs.isNotEmpty) {
          final alert = snapshot.docs.first;
          final double? lat = alert.data().containsKey('latitude') ? alert['latitude'] : null;
          final double? lng = alert.data().containsKey('longitude') ? alert['longitude'] : null;

          if (lat != null && lng != null) {
            _updateMapPosition(lat, lng, alert['name']);
          }

          _showPopupAlert(
            alert['name'],
            alert['houseNo'],
            alert['houseName'],
            alert['type'],
          );
        }
      },
    );
  }

  void _updateMapPosition(double lat, double lng, String senderName) {
    final pos = LatLng(lat, lng);
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId('alert_location'),
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
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.emergency, size: 45, color: Colors.red),
        title: const Text('Emergency Alert'),
        content: Text(
          "From: $name \n House No: $houseNo \n House Name: $houseName \n\n Category: $type",
          style: TextStyle(fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Dismiss"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppbar(),
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
                  "Help will arrive soon",
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
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.white60),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.add_alert, size: 24),
                          SizedBox(width: 10),
                          const Text(
                            "Recent Alert Section",
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
      bottomNavigationBar: NavBarScreen(currentIndex: 0),
    );
  }
}
