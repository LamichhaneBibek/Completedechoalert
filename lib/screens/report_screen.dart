import 'package:echoalert/components/navbar_screen.dart';
import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Report Screen")),
      body: Center(child: Text("This screen was missing from the repository.")),
      bottomNavigationBar: NavBarScreen(currentIndex: 2),
    );
  }
}