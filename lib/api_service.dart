import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;


class ApiService {
  // Fetch session data
  static Future<Map<String, String>> getSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empId = prefs.getString('emp_id');
    String? empName = prefs.getString('emp_name');
    return {
      'emp_id': empId ?? '',
      'emp_name': empName ?? '',
    };
  }

  // Fetch attendance data
  static Future<Map<String, dynamic>> getAttendanceData(String empId,status) async {
    final response = await http.get(Uri.parse(
        'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php?status=$status&emp_id=$empId'));
    if (response.statusCode == 200) {
      return json.decode(response.body)['data'];
    } else {
      throw Exception('Failed to fetch attendance data');
    }
  }

  // Fetch all required data
  static Future<Map<String, dynamic>> getAllData() async {
    final sessionData = await getSessionData();
    final empId = sessionData['emp_id'];
    if (empId == null || empId.isEmpty) {
      throw Exception('Employee ID not found in session');
    }
    final attendanceData = await getAttendanceData(empId,"count");
    final Inoutdata = await getAttendanceData(empId,"inout");
    return {
      'sessionData': sessionData,
      'attendanceData': attendanceData,
      'InOutdata': Inoutdata,
    };
  }
}
