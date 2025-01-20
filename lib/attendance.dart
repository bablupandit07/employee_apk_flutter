import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Import geolocator
import 'package:geocoding/geocoding.dart'; // Import geocoding

class Attendance extends StatefulWidget {
  const Attendance({super.key});

  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  String _locationMessage = 'Current Location: Not available';
  bool _isLoading = false;

  // Function to get current location and convert to full address including postal code
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Check location permissions
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission denied';
          _isLoading = false;
        });
        Navigator.pop(context); // Dismiss loader
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      try {
        // Convert the position to a full address
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];

          // Construct the full address including postal code (zip code)
          String fullAddress =
              '${place.subThoroughfare}, ${place.thoroughfare}, ${place.subLocality}, '
              '${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}';

          setState(() {
            _locationMessage =
            'Lat: ${position.latitude}, Long: ${position.longitude}\n'
                'Address: $fullAddress';
          });
        } else {
          setState(() {
            _locationMessage = 'No address found for this location';
          });
        }
      } catch (e) {
        setState(() {
          _locationMessage = 'Error retrieving address: $e';
        });
      }
    } catch (e) {
      setState(() {
        _locationMessage = 'Error fetching location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context); // Dismiss loader
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Employee Attendance',
        userName: 'John Doe', // Replace with dynamic username
      ),
      drawer: const MyDrawer(
        userName: 'John Doe', // Replace with dynamic username
      ),
      body: Center( // Center aligns everything
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
              children: [
                const SizedBox(height: 50), // Adjust height for spacing

                // "In Entry" button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    backgroundColor: Colors.green.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: _getCurrentLocation, // Call method for "In" entry
                  child: const Text(
                    'In Entry',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16), // Spacing between buttons

                // "Out Entry" button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                    backgroundColor: Colors.red.shade700,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  onPressed: _getCurrentLocation, // Call method for "Out" entry
                  child: const Text(
                    'Out Entry',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),

                // Show the current location message
                Text(
                  _locationMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.black),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String userName;

  const CustomAppBar({Key? key, required this.title, required this.userName})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        IconButton(
          icon: const Icon(Icons.dashboard),
          onPressed: () {
            Navigator.pushNamed(context, '/dashboard');
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MyDrawer extends StatelessWidget {
  final String userName;

  const MyDrawer({Key? key, required this.userName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            accountName: Text(
              'Welcome, $userName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Text(
              '$userName@example.com', // Placeholder for email
              style: const TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                userName[0], // Displaying the first letter of the user's name
                style: const TextStyle(fontSize: 30, color: Colors.blue),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const Divider(),
          const SizedBox(height: 390),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/'); // Logout or redirect logic
            },
          ),
        ],
      ),
    );
  }
}
