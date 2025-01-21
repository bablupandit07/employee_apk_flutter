import 'package:flutter/material.dart';

class SidebarPage extends StatelessWidget {
  final String userName;

  const SidebarPage({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft, // Ensures the sidebar opens from the left
      child: FractionallySizedBox(
        widthFactor: 1, // Adjust to 100% width of the screen
        child: Drawer(
          child: Column(
            children: [
              // Header Section with Close Button
              Container(
                color: Color(0xFF15295F), // Replace '123456' with your desired hex code
                padding: const EdgeInsets.only(top: 30, bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.23),
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Close Button
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Close the sidebar
                      },
                    ),
                  ],
                ),
              ),

              // Sidebar Menu Items
              Expanded(
                child: ListView(
                  children: [
                    _buildDrawerItem(
                      context,
                      icon: Icons.home,
                      text: 'Home',
                      onTap: () {
                        Navigator.pushNamed(context, '/dashboard');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.person,
                      text: 'My Profile',
                      onTap: () {
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.list_alt,
                      text: 'Attendance Details',
                      onTap: () {
                        Navigator.pushNamed(context, '/attendance-details');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.people,
                      text: 'Employee Attendance',
                      onTap: () {
                        Navigator.pushNamed(context, '/attendance');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.lock,
                      text: 'Change Password',
                      onTap: () {
                        Navigator.pushNamed(context, '/change-password');
                      },
                    ),
                    _buildDrawerItem(
                      context,
                      icon: Icons.logout,
                      text: 'Si gn Out',
                      onTap: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon, required String text, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.blue,
      ),
      title: Text(
        text,
        style: const TextStyle(fontSize: 16),
      ),
      onTap: onTap,
    );
  }
}
