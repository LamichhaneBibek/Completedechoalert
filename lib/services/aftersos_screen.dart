import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/services/nearest_contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class AftersosScreen extends StatefulWidget {
  const AftersosScreen({super.key});

  @override
  State<AftersosScreen> createState() => _AftersosScreenState();
}

class _AftersosScreenState extends State<AftersosScreen> {
  bool _isLoading = false;

  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    return await Geolocator.getCurrentPosition();
  }

  void _sendAlert(String type) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userInfo = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userInfo.exists) throw Exception('User info NOT found');

      final name = userInfo['name'];
      final houseNo = userInfo['houseNo'];
      final houseName = userInfo['houseName'];

      final position = await _determinePosition();

      await FirebaseFirestore.instance.collection('alerts').add({
        'senderId': user.uid,
        'type': type,
        'name': name,
        'houseNo': houseNo,
        'houseName': houseName,
        'latitude': position?.latitude,
        'longitude': position?.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Find nearest registered users and show them to the sender.
      if (position != null && mounted) {
        final nearbyUsers = await NearestContactsService.findNearestUsers(
          senderLat: position.latitude,
          senderLng: position.longitude,
          radiusKm: 5.0,
        );
        if (mounted) _showNearbyUsersDialog(nearbyUsers);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alert sent! (location unavailable)'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send alert: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showNearbyUsersDialog(List<Map<String, dynamic>> users) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.red),
            SizedBox(width: 8),
            Text('Alert Sent!'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your SOS has been broadcast.',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              if (users.isEmpty)
                const Text(
                  'No registered users found within 5 km of your location.',
                  style: TextStyle(color: Colors.grey),
                )
              else ...[
                Text(
                  '${users.length} registered user(s) within 5 km:',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];
                      final distKm = u['distanceKm'] as double;
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: _distanceColor(distKm),
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          u['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(u['phone'] as String),
                        trailing: Text(
                          '${distKm.toStringAsFixed(2)} km',
                          style: TextStyle(
                            color: _distanceColor(distKm),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Color _distanceColor(double km) {
    if (km <= 1.0) return Colors.red;
    if (km <= 3.0) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: const CustomAppbar(),
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text(
                  'What Happened',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 25,
                    mainAxisSpacing: 25,
                    children: [
                      _buildEmergencyItem(
                        'Fire Emergency',
                        Icons.local_fire_department,
                      ),
                      _buildEmergencyItem(
                        'Medical Emergency',
                        Icons.health_and_safety,
                      ),
                      _buildEmergencyItem('Theft', Icons.local_police),
                      _buildEmergencyItem('Others', Icons.add_circle_outline),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: const NavBarScreen(currentIndex: 0),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Sending alert & finding\nnearby users…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () => _sendAlert(title),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF830B2F)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 46, color: const Color(0xFF830B2F)),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
