import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/components/custom_appbar.dart';

class EmergencyReceiverScreen extends StatefulWidget {
  const EmergencyReceiverScreen({super.key});

  @override
  State<EmergencyReceiverScreen> createState() => _EmergencyReceiverScreenState();
}

class _EmergencyReceiverScreenState extends State<EmergencyReceiverScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      backgroundColor: const Color(0xFFD9D9D9),
      body: StreamBuilder<QuerySnapshot>(


        //Algorithm started


        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots(),
        builder: (context, snapshot) {
          // Logic: Handling the loading state of the stream
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "System Active: Monitoring for Alerts...",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }
          var alertDoc = snapshot.data!.docs.first;
          var data = alertDoc.data() as Map<String, dynamic>;


          //Algorithm Ended


          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Main Alert Card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 40),
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        size: 80,
                        color: Color(0xFF830B2F),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "EMERGENCY!",
                        style: TextStyle(
                          color: Color(0xFF830B2F),
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Divider(height: 40),
                      Text(
                        "Resident: ${data['name'] ?? 'Unknown'}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "House No: ${data['houseNo'] ?? 'N/A'}",
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),                      
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF830B2F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (data['type'] ?? 'GENERAL').toString().toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 55,
                  top: 15,
                  child: GestureDetector(
                    onTap: () {
                      // Logic: UI pop to dismiss the current view
                      Navigator.of(context).pop();
                    },
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: const NavBarScreen(currentIndex: 1),
    );
  }
}