import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/components/custom_appbar.dart';
import 'package:intl/intl.dart'; // Add this to your pubspec.yaml for date formatting

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  // Format timestamp into a readable string
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Unknown time";
    DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, hh:mm a').format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      backgroundColor: const Color(0xFFD9D9D9),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "Emergency History",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF830B2F),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // ===============================================================
              // ALGORITHM: Sequential Log Retrieval
              // 1. Scope: Fetches the entire 'alerts' collection.
              // 2. Ordering: Sorts by 'timestamp' DESC (Newest first).
              // 3. Mapping: Converts QuerySnapshot into a ListView of widgets.
              // ===============================================================
              stream: FirebaseFirestore.instance
                  .collection('alerts')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("No history found."),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF830B2F), width: 0.5),
                      ),
                      child: Row(
                        children: [
                          // Visual Category Icon
                          const CircleAvatar(
                            backgroundColor: Color(0xFF830B2F),
                            child: Icon(Icons.history, color: Colors.white),
                          ),
                          const SizedBox(width: 15),
                          
                          // Alert Metadata
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['type'] ?? "Emergency",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF830B2F),
                                  ),
                                ),
                                Text(
                                  "From: ${data['name'] ?? 'Unknown'}",
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  _formatTimestamp(data['timestamp'] as Timestamp?),
                                  style: TextStyle(
                                    fontSize: 12, 
                                    color: Colors.grey[600]
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status Indicator
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const NavBarScreen(currentIndex: 1), // Assuming 2 is History
    );
  }
}