import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    home: ExpenseEntryPage(),
    debugShowCheckedModeBanner: false,
  ));
}

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
    '${DateTime.now().toLocal().toString().split(' ')[0]}'; // Default date
  }

  Future<void> _pickImage(BuildContext context) async {
    PermissionStatus cameraPermission = await Permission.camera.request();
    PermissionStatus storagePermission = await Permission.storage.request();

    if (cameraPermission.isGranted && storagePermission.isGranted) {
      final pickedFile = await showModalBottomSheet<XFile?>(
        context: context,
        builder: (BuildContext context) {
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context,
                        await _picker.pickImage(source: ImageSource.camera));
                  },
                ),
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context,
                        await _picker.pickImage(source: ImageSource.gallery));
                  },
                ),
              ],
            ),
          );
        },
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = pickedFile;
        });
      }
    } else {
      print('Camera or storage permission denied');
    }
  }

  Future<void> _submitData() async {
    if (amountController.text.isEmpty ||
        remarkController.text.isEmpty ||
        _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill all fields and upload an image!'),
      ));
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String empId = prefs.getString('emp_id') ?? '0'; // Default to '0' if not found

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php'), // Replace with your API URL
    );

    request.fields['empid'] = empId;
    request.fields['amount'] = amountController.text;
    request.fields['date'] = dateController.text;
    request.fields['remark'] = remarkController.text;
    request.fields['status'] = 'expense_entry';

    request.files.add(
        await http.MultipartFile.fromPath('image', _imageFile!.path));

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
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ExpenseListPage()));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              controller: dateController,
              decoration: InputDecoration(
                labelText: 'Date',
              ),
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  lastDate: DateTime(2101),
                  firstDate: DateTime(2000),
                );
                if (pickedDate != null) {
                  dateController.text =
                  pickedDate.toLocal().toString().split(' ')[0];
                }
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                _pickImage(context);
              },
              icon: Icon(Icons.upload_file),
              label: Text('UPLOAD DOCUMENTS'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
            SizedBox(height: 16),
            if (_imageFile != null)
              Column(
                children: [
                  Image.file(File(_imageFile!.path), height: 150, width: 150),
                ],
              ),
            SizedBox(height: 16),
            TextField(
              controller: remarkController,
              decoration: InputDecoration(
                labelText: 'Remark',
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitData,
              child: Text('ADD EXPENSE'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseListPage extends StatefulWidget {
  @override
  _ExpenseListPageState createState() => _ExpenseListPageState();
}

class _ExpenseListPageState extends State<ExpenseListPage> {
  List<dynamic> expenseList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchExpenseData();
  }

  Future<void> fetchExpenseData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String empId = prefs.getString('emp_id') ?? '0'; // Default to '0' if not found
    final apiUrl = 'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php?status=expense&emp_id=$empId'; // Replace with your API URL
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          expenseList = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to fetch data'),
        ));
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense List'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : expenseList.isEmpty
          ? Center(
        child: Text('No expenses found.'),
      )
          : ListView.builder(
        itemCount: expenseList.length,
        itemBuilder: (context, index) {
          final expense = expenseList[index];
          return Card(
            margin: EdgeInsets.all(10),
            child: ListTile(
              title: Text('Amount: ${expense['exp_amount']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date: ${expense['expense_date']}'),
                  Text('Remark: ${expense['remark']}'),
                  Text('Status: ${expense['exp_status']}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
