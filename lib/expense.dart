import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert'; // Add this import for JSON handling

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ExpenseEntryPage extends StatefulWidget {
  @override
  _ExpenseEntryPageState createState() => _ExpenseEntryPageState();
}
class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dateController.text =
    '${DateTime.now().toLocal().toString().split(' ')[0]}'; // Set default date
  }

  Future<void> _pickImage(BuildContext context) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No image selected!'),
      ));
    }
  }

  Future<void> _submitData() async {
    if (amountController.text.isEmpty || remarkController.text.isEmpty || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields and upload an image!'),
      ));
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String empId = prefs.getString('emp_id') ?? '0'; // Default empId if not found

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php'), // Replace with your API URL
    );

    request.fields['empid'] = empId;
    request.fields['amount'] = amountController.text;
    request.fields['date'] = dateController.text;
    request.fields['remark'] = remarkController.text;
    request.fields['status'] = 'expense_entry';
    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Expense entry added successfully!'),
      ));
      setState(() {
        amountController.clear();
        remarkController.clear();
        _imageFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to add expense entry.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Entry'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: InputDecoration(labelText: 'Date'),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  dateController.text = pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _pickImage(context),
              icon: Icon(Icons.upload_file),
              label: Text('Upload Document'),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              Image.file(File(_imageFile!.path), height: 150, width: 150),
            SizedBox(height: 16),
            TextField(
              controller: remarkController,
              decoration: InputDecoration(labelText: 'Remark'),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('Add Expense'),
            ),
            SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseEntryListPage()),
                  );
                },
                child: Text(
                  'View Expense List',
                  style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: ExpenseEntryPage(),
  ));

}
class ExpenseEntryListPage extends StatelessWidget {

  Future<List<Map<String, dynamic>>> fetchExpenseEntries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empId = prefs.getString('emp_id');

    if (empId == null) {
      throw Exception('Employee ID not found');
    }

    final String apiUrl =
        'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php?status=expense&emp_id=$empId';

    try {
      final response = await http.get(Uri.parse(apiUrl));

      // print(response);
      if (response.statusCode == 200) {
        final Map<String, dynamic> decodedResponse = json.decode(response.body);
        if (decodedResponse.containsKey('data')) {
          final List<dynamic> data = decodedResponse['data'];
          return data.cast<Map<String, dynamic>>();
        } else {
          throw Exception('No "data" field in the response');
        }
      } else {
        throw Exception('Failed to load expense entries');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Entry List'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchExpenseEntries(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No expense entries found.'));
          } else {
            final expenseEntries = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(16.0),
              itemCount: expenseEntries.length,
              itemBuilder: (context, index) {
                final entry = expenseEntries[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Amount: ${entry['exp_amount']}',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Date: ${entry['expense_date']}'),
                        SizedBox(height: 8),
                        Text('Remark: ${entry['remark']}'),
                        SizedBox(height: 8),
                        Text(
                          'Status: ${entry['exp_status'] == "0" ? "Pending" : "Approved"}',
                          style: TextStyle(
                            color: entry['exp_status'] == "0"
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        SizedBox(height: 8),
                        Image.network(
                          'https://thakurassociates.trinitysoftwares.in/userpanel/uploaded/expence_img/${entry['exp_img']}',
                          height: 100,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Text('Image not available');
                          },
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // View logic here
                              },

                              child: Text('Edit'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await _showDeleteConfirmationDialog(context, entry['expense_id']);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: Text('DELETE s'),
                            ),

                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, String expenseId) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Delete'),
          content: Text('Are you sure you want to delete this expense entry?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User canceled the deletion
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirmed the deletion
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await deleteExpenseEntry(expenseId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense entry deleted successfully')),

        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting entry: $e')),
        );
      }
    }
  }

  Future<void> deleteExpenseEntry(String expenseId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empId = prefs.getString('emp_id');

    if (empId == null) {
      throw Exception('Employee ID not found in session');
    }

    final String apiUrl =
        'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {
          'emp_id': empId,
          'expense_id': expenseId,
          'status': 'delete_expense',
        },
      );

      if (response.statusCode == 200) {
        try {
          final decodedResponse = json.decode(response.body);
          if (decodedResponse['status'] == 'success') {
            print('Expense entry deleted successfully.');
          } else {
            throw Exception('Failed to delete expense entry: ${decodedResponse['message']}');
          }
        } catch (e) {
          throw Exception('Error decoding response: $e');
        }
      } else {
        throw Exception('API call failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting data: $e');
    }
  }

}
