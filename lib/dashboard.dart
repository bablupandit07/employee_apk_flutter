import 'package:flutter/material.dart';
import 'appbar.dart'; // Importing the custom AppBar
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart'; // Import the ApiService class
import 'sidebar_page.dart'; // Importing SidebarPage

Future<Map<String, String>> getUserSession() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? empId = prefs.getString('emp_id');
  String? empName = prefs.getString('emp_name');
  return {
    'emp_id': empId ?? '',
    'emp_name': empName ?? '',
  };
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  Future<String> getUserName() async {
    Map<String, String> userData = await getUserSession();
    return userData['emp_name']!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('Error loading data'));
        }

        String userName = snapshot.data ?? 'Unknown User';

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
                leading: IconButton(
                  icon: const Icon(Icons.menu,color: Colors.white,),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SidebarPage(userName: empName)),
                    );
                  },
                ),
              ),
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                          backgroundColor: const Color(0xFF15295F),                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                          backgroundColor: const Color(0xFF15295F),                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
