import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Import the ApiService class

Future<Map<String, String>> getUserSession() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  // Retrieve 'emp_id' and 'emp_name' from shared preferences
  String? empId = prefs.getString('emp_id');
  String? empName = prefs.getString('emp_name');

  // Return the values in a map (you can return null or empty string if no data is found)
  return {
    'emp_id': empId ?? '',  // Default to empty string if not found
    'emp_name': empName ?? '',
  };
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Dashboard',
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
      routes: {
        '/dashboard': (context) => const DashboardPage(),
        '/settings': (context) => const SettingsPage(),
      },
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  // Fetch the user name using Future
  Future<String> getUserName() async {
    Map<String, String> userData = await getUserSession();
    return userData['emp_name']!; // Ensuring that emp_name is not null
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        // Handle the loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle the error state
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        // Get the user name, or set default
        String userName = snapshot.data ?? 'Unknown User';

        // Fetch the data for dashboard after user name is fetched
        return FutureBuilder<Map<String, dynamic>>(
          future: ApiService.getAllData(),
          builder: (context, snapshot) {
            // Handle loading state for the API data
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle error state for the API data
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading data'));
            }

            // Handle case when API data is null or empty
            if (!snapshot.hasData || snapshot.data == null) {
              return const Center(child: Text('No data available'));
            }

            // At this point, we have the data available
            final allData = snapshot.data ?? {};
            final sessionData = allData['sessionData'] as Map<String, String>? ?? {};
            final attendanceData = allData['attendanceData'] as Map<String, dynamic>? ?? {};

            String empName = sessionData['emp_name'] ?? 'Unknown User';
            int workingDays = int.tryParse(attendanceData['count_working_days']?.toString() ?? '0') ?? 0;
            int onTime = int.tryParse(attendanceData['on_time']?.toString() ?? '0') ?? 0;
            int lateIn = int.tryParse(attendanceData['late_in']?.toString() ?? '0') ?? 0;
            int earlyExit = int.tryParse(attendanceData['early_exit']?.toString() ?? '0') ?? 0;
            int absent = int.tryParse(attendanceData['absent']?.toString() ?? '0') ?? 0;

            return Scaffold(
              appBar: CustomAppBar(
                title: 'Employee Attendance',
                userName: empName,
              ),
              drawer: MyDrawer(userName: empName),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Circular chart
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 200,
                            height: 200,
                            child: CircularProgressIndicator(
                              value: workingDays > 0 ? onTime / workingDays : 0,
                              strokeWidth: 16.0,
                              backgroundColor: Colors.grey.shade300,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                workingDays.toString(),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Working Days',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Jan 2025',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Status row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          StatusCard(
                            label: 'On Time',
                            value: onTime.toString(),
                            color: Colors.green,
                          ),
                          StatusCard(
                            label: 'Late In',
                            value: lateIn.toString(),
                            color: Colors.orange,
                          ),
                          StatusCard(
                            label: 'Early Exit',
                            value: earlyExit.toString(),
                            color: Colors.blue,
                          ),
                          StatusCard(
                            label: 'Absent',
                            value: absent.toString(),
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          backgroundColor: Colors.lightBlue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/attendance');
                        },
                        child: const Text(
                          'Attendance Entry',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          backgroundColor: Colors.lightBlue.shade700,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/expense');
                        },
                        child: const Text(
                          'Expense Entry',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 155),

                      // Bottom Navigation
                      const Divider(),
                      Container(
                        margin: const EdgeInsets.only(bottom: 1.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            BottomNavIcon(icon: Icons.dashboard, label: 'Dashboard'),
                            BottomNavIcon(icon: Icons.history, label: 'History'),
                            BottomNavIcon(icon: Icons.person, label: 'Profile'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
            decoration: BoxDecoration(
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
              '', // Placeholder for email
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

class StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const StatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.1),
          child: Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class BottomNavIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  const BottomNavIcon({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Settings',
        userName: 'John Doe',
      ),
      body: const Center(
        child: Text('Settings Page'),
      ),
    );
  }
}
