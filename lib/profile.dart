import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoading = true;
  Map<String, dynamic> _profileData = {
    'emp_name': '',
    'emp_password': '',
    'phone_no': '',
    'address': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  // Fetch user profile data from SharedPreferences
  Future<void> _fetchProfileData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    setState(() {
      _profileData['emp_name'] = prefs.getString('emp_name') ?? '';
      _profileData['emp_password'] = prefs.getString('emp_password') ?? '';
      _profileData['phone_no'] = prefs.getString('phone_no') ?? '';
      _profileData['address'] = prefs.getString('address') ?? '';
      _isLoading = false;
    });
  }

  // UI for read-only text fields
  Widget _buildTextField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        initialValue: value,
        enabled: false, // Make the field read-only
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
          border: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        style: TextStyle(color: Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Attendance', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF15295F),
        iconTheme: const IconThemeData(color: Colors.white), // Make icons white

      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'MY PROFILE',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildTextField('Full Name', _profileData['emp_name']),
            _buildTextField('Password', _profileData['emp_password']),
            _buildTextField('Phone Number', _profileData['phone_no']),
            _buildTextField('Address', _profileData['address']),
          ],
        ),
      ),
    );
  }
}
