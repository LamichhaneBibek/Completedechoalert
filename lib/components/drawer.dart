import 'dart:io';

import 'package:echoalert/components/my_list_tile.dart';
import 'package:echoalert/screens/profile_screen.dart';
import 'package:echoalert/services/setting_screen.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  final void Function()? onProfileTap;
  final void Function()? onSettingsTap;

  const MyDrawer({
    Key? key,
    this.onProfileTap,
    this.onSettingsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Color(0xFF830b2F),
      child: Column(
        children: [
          const DrawerHeader(
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 64,
            ),
          ),
          MyListTile(
            icon: Icons.person,
            text: 'P R O F I L E',
            onTap: onProfileTap,
          ),
          MyListTile(
            icon: Icons.settings,
            text: 'S E T T I N G S',
            onTap: onSettingsTap,
          ),
         
          
        ],
      ),
    );
  }
}