import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:echoalert/components/drawer.dart';
import 'package:echoalert/components/navbar_screen.dart';
import 'package:echoalert/services/setting_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? get uid => user?.uid;
  String? userName;
  String? userPhone;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          userName = data?['name'];
          userPhone = data?['phoneNumber'];
          userEmail = data?['email'];
        });
      }
    }
  }

  void goToProfileTap() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[900],
        elevation: 0,
        toolbarHeight: 100,
        centerTitle: true,
        title: const CircleAvatar(
          backgroundImage: AssetImage('assets/images/logo.png'),
          radius: 25,
          backgroundColor: Colors.white,
        ),
      ),
      drawer: MyDrawer(onProfileTap: goToProfileTap),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          const SizedBox(height: 10),
          const Center(
            child: Text(
              "Profile Details",
              style: TextStyle(
                color: Color(0xFF830B2F),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: SizedBox(
              width: 250,
              child: Text(
                "Your Name, House Name, House Number will be visible when you send alert.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: const Icon(
                Icons.person_2_outlined,
                size: 60,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const _InputLabel(text: 'Name'),
          _buildInfoText(userName),
          const _InputLabel(text: 'Phone Number'),
          _buildInfoText(userPhone),
          const _InputLabel(text: 'Email'),
          _buildInfoText(userEmail),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF830B2F),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Logout",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarScreen(currentIndex: 4),
    );
  }

  Widget _buildInfoText(String? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.only(left: 30, bottom: 10, right: 50),
      constraints: const BoxConstraints(maxWidth: 220),
      decoration: BoxDecoration(
        color: const Color(0xFFD9D9D9),
        border: Border.all(color: const Color(0xFFD9D9D9)),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(data ?? 'Loading...', style: const TextStyle(fontSize: 16)),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String text;
  const _InputLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 6.0, left: 50.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
    );
  }
}
