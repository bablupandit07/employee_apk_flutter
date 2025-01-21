import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;
  final Widget? leading; // Custom leading widget

  const CustomAppBar({
    Key? key,
    required this.title,
    required this.userName,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF15295F),
      iconTheme: const IconThemeData(color: Colors.white), // Makes icons white
      titleTextStyle: const TextStyle(
        color: Colors.white, // Sets title text color to white
        fontSize: 20, // Optional: Adjust title text size
        fontWeight: FontWeight.bold, // Optional: Adjust font weight
      ),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
      leading: leading ??
          BackButton(
            color: Colors.white, // Ensure the back button is white
          ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
