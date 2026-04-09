import 'package:echoalert/components/custom_appbar.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

void _callEmergency(String number) async {
  await FlutterPhoneDirectCaller.callNumber(number);
}

class _ContactScreenState extends State<ContactScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppbar(),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Emergency Contact Number",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              const SizedBox(height: 20),
              _buildContactItem(
                label: "Nepal Police - 100",
                number: "100",
                imageAsset: "assets/images/police.png",
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: "Fire Brigade - 101",
                number: "101",
                imageAsset: "assets/images/fire_brigade.png",
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: "Ambulance - 102",
                number: "102",
                imageAsset: "assets/images/ambulance.png",
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: "Child Helpline - 104",
                number: "104",
                imageAsset: "assets/images/childern.png",
              ),
              const SizedBox(height: 25),
              _buildContactItem(
                label: "Women Helpline - 1145",
                number: "1145",
                imageAsset: "assets/images/women.png",
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const NavBarScreen(currentIndex: 2),
    );
  }

  Widget _buildContactItem({
    required String label,
    required String number,
    required String imageAsset,
  }) {
    return GestureDetector(
      onTap: () => _callEmergency(number),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Image.asset(
              imageAsset,
              width: 50,
              height: 50,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.phone, size: 50),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.call, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
