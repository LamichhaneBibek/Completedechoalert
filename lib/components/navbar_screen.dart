import 'package:flutter/material.dart';

class NavBarScreen extends StatelessWidget {
  final int currentIndex;
  const NavBarScreen({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
        // BottomNavigationBarItem(
        //   icon: Icon(Icons.report_problem),
        //   label: 'Report',
        // ),
        BottomNavigationBarItem(icon: Icon(Icons.contacts), label: 'Contact'),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
      backgroundColor: Colors.red[900],
      selectedItemColor: Colors.white,
      unselectedItemColor: Colors.white70,
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;

        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/history');
            break;
          // case 2:
          //   Navigator.pushReplacementNamed(context, '/report');
          //   break;
          case 2:
            Navigator.pushReplacementNamed(context, '/contact');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
    );
  }
}
