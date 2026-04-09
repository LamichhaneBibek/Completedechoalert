import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
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
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;
    return await Geolocator.getCurrentPosition();
  }


  //Algorithm started


  void _sendAlert(String type) async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Authentication session required.");

      final results = await Future.wait([
        FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        _determinePosition(),
      ]);

      final DocumentSnapshot userInfo = results[0] as DocumentSnapshot;
      final Position? position = results[1] as Position?;

      if (!userInfo.exists) throw Exception("User profile metadata not found.");

      await FirebaseFirestore.instance.collection('alerts').add({
        'senderId': user.uid,
        'type': type,                     
        'name': userInfo['name'],        
        'houseNo': userInfo['houseNo'],    
        'houseName': userInfo['houseName'],  
        'latitude': position?.latitude,  
        'longitude': position?.longitude,
        'timestamp': FieldValue.serverTimestamp(), 
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Emergency Dispatch Successful!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Dispatch Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  //Algorithm ended


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
                  "Select Emergency Type",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF830B2F),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 25,
                    mainAxisSpacing: 25,
                    children: [
                      _buildEmergencyItem("Fire Emergency", Icons.local_fire_department),
                      _buildEmergencyItem("Medical Emergency", Icons.health_and_safety),
                      _buildEmergencyItem("Theft", Icons.local_police),
                      _buildEmergencyItem("Others", Icons.add_circle_outline),
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
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildEmergencyItem(String title, IconData icon) {
    return GestureDetector(
      onTap: () => _sendAlert(title), // Triggers the Dispatch Algorithm
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF830B2F)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 46,
              color: const Color(0xFF830B2F),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}