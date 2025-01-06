import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class Attendance extends StatefulWidget {
  const Attendance({super.key});
  @override
  _AttendanceState createState() => _AttendanceState();
}

class _AttendanceState extends State<Attendance> {
  String _locationMessage = 'Current Location: Not available';
  String _responseMessage = ''; // Message to display response
  bool _isLoading = false;

  // Function to get current location and post it to the server
  Future<void> _getCurrentLocation(String status, String empId) async {
    setState(() {
      _isLoading = true;
      _responseMessage = ''; // Reset response message
    });

    try {
      // Request location permissions
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationMessage = 'Location permission denied';
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.bestForNavigation,
      );

      // Convert the position to a full address
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String fullAddress = 'Unknown location';
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        fullAddress =
        '${place.subThoroughfare}, ${place.thoroughfare}, ${place.subLocality}, '
            '${place.locality}, ${place.administrativeArea}, ${place.postalCode}, ${place.country}';
      }

      setState(() {
        _locationMessage =
        'Lat: ${position.latitude}, Long: ${position.longitude}\n'
            'Address: $fullAddress';
      });

      // Call the API to post the data
      await _postAttendanceData(
        latitude: position.latitude.toString(),
        longitude: position.longitude.toString(),
        address: fullAddress,
        status: status,
        empId: empId, // Pass dynamic empId
      );
    } catch (e) {
      setState(() {
        _locationMessage = 'Error fetching location: $e';
      });
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state
      });
    }
  }

  // Function to post attendance data to the server
  Future<void> _postAttendanceData({
    required String latitude,
    required String longitude,
    required String address,
    required String status,
    required String empId,
  }) async {
    const String apiUrl =
        'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php';

    String deviceId = 'u011'; // Replace with actual source

    setState(() {
      _responseMessage = 'Submitting...';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'latitude': latitude,
          'longitude': longitude,
          'address': address,
          'empid': empId, // Use dynamic empId
          'deviceid': deviceId,
          'status': status,
          'acstatus': 'attendancesave',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _responseMessage = status == 'IN'
              ? 'In Entry Successful'
              : 'Out Entry Successful';
        });

        // Optional: Show success in a Snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_responseMessage)),
        );
      } else {
        setState(() {
          _responseMessage = 'Server error: HTTP ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _responseMessage = 'Error posting attendance data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: ApiService.getAllData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        if (!snapshot.hasData || snapshot.data == null) {
          return const Center(child: Text('No data available'));
        }

        final allData = snapshot.data ?? {};
        final sessionData = allData['sessionData'] as Map<String, String>? ?? {};
        final inOutData = allData['InOutdata'] as Map<String, dynamic>? ?? {};

        String empName = sessionData['emp_name'] ?? 'Unknown User';
        String empId = sessionData['emp_id'] ?? '0'; // Dynamic empId
        String intime = inOutData['intime'] ?? '';
        String outtime = inOutData['outtime'] ?? '';

        return Stack(
          children: [
            Scaffold(
              appBar: CustomAppBar(
                title: 'Employee Attendance',
                userName: empName,
              ),
              drawer: MyDrawer(userName: empName),
              body: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            backgroundColor: intime.isEmpty
                                ? Colors.green.shade700
                                : Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: intime.isEmpty
                              ? () {
                            _getCurrentLocation('IN', empId); // Pass empId
                          }
                              : null,
                          child: Text(
                            intime.isEmpty ? 'In Entry' : 'intime: $intime',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 32),
                            backgroundColor: intime.isNotEmpty &&
                                outtime.isEmpty
                                ? Colors.red.shade700
                                : Colors.grey,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: intime.isNotEmpty && outtime.isEmpty
                              ? () {
                            _getCurrentLocation('OUT', empId); // Pass empId
                          }
                              : null,
                          child: Text(
                            outtime.isEmpty ? 'Out Entry' : 'outtime: $outtime',
                            style: const TextStyle(
                                fontSize: 18, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _locationMessage,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _responseMessage,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        );
      },
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
            accountEmail: const Text(
              '', // Placeholder for email
              style: TextStyle(color: Colors.white70),
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
            leading: const Icon(Icons.home),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          const Divider(),
        ],
      ),
    );
  }
}
