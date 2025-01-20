import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Entry',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ExpenseEntryPage(),
    );
  }
}

class ExpenseEntryPage extends StatefulWidget {
  @override
  _ExpenseEntryPageState createState() => _ExpenseEntryPageState();
}

class _ExpenseEntryPageState extends State<ExpenseEntryPage> {
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  XFile? _imageFile;
  TextEditingController amountController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  TextEditingController remarkController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dateController.text =
    '${DateTime.now().toLocal().toString().split(' ')[0]}';
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text('Capture Image'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Icon(Icons.photo),
                title: Text('Select from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = pickedFile;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No image selected!')),
      );
    }
  }

  Future<void> _submitData() async {
    if (amountController.text.isEmpty ||_imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill all fields and upload an image!')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String empId = prefs.getString('emp_id') ?? '0';

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php'),
    );

    request.fields['empid'] = empId;
    request.fields['amount'] = amountController.text;
    request.fields['date'] = dateController.text;
    request.fields['remark'] = remarkController.text;
    request.fields['status'] = 'expense_entry';
    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    var response = await request.send();

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense entry added successfully!')));
      setState(() {
        amountController.clear();
        remarkController.clear();
        _imageFile = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense entry.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Expense Entry')),
      body: Stack(
        children: [
          SingleChildScrollView(
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
                      dateController.text =
                      pickedDate.toLocal().toString().split(' ')[0];
                    }
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _showPicker(context),
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
                        MaterialPageRoute(
                            builder: (context) => ExpenseEntryListPage()),
                      );
                    },
                    child: Text(
                      'View Expense List ',
                      style: TextStyle(
                          color: Colors.blue,
                          decoration: TextDecoration.underline),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

class ExpenseEntryListPage extends StatefulWidget {
  @override
  _ExpenseEntryListPageState createState() => _ExpenseEntryListPageState();
}

class _ExpenseEntryListPageState extends State<ExpenseEntryListPage> {
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _expenseEntries = [];
  bool _isLoading = false;
  bool _hasMoreData = true;
  int _currentPage = 1;
  final int _itemsPerPage = 2;

  @override
  void initState() {
    super.initState();
    _fetchExpenseEntries();

    // Add a listener to detect scroll events
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent &&
          !_isLoading &&
          _hasMoreData) {
        _fetchExpenseEntries();
      }
    });
  }

  Future<void> _fetchExpenseEntries() async {
    if (!_hasMoreData) return; // Stop fetching if there's no more data

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? empId = prefs.getString('emp_id');

    if (empId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Employee ID not found')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final String apiUrl =
        'https://thakurassociates.trinitysoftwares.in/employee_app/api/api.php?status=expense&emp_id=$empId&page=$_currentPage&limit=$_itemsPerPage';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final decodedResponse = json.decode(response.body);

        if (decodedResponse.containsKey('data')) {
          final List<dynamic> newEntries = decodedResponse['data'];

          setState(() {
            // Remove duplicates based on a unique key (e.g., `expense_id`)
            for (var entry in newEntries) {
              if (!_expenseEntries.any((e) => e['expense_id'] == entry['expense_id'])) {
                _expenseEntries.add(entry);
              }
            }

            if (newEntries.length < _itemsPerPage) {
              _hasMoreData = false; // No more data to load
            } else {
              _currentPage++; // Increment page number
            }
          });
        } else {
          throw Exception('No "data" field in the response');
        }
      } else {
        throw Exception('Failed to load expense entries');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }



  Future<void> _deleteExpenseEntry(String expenseId) async {
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
        final decodedResponse = json.decode(response.body);
        if (decodedResponse['status'] == 'success') {
          setState(() {
            _expenseEntries.removeWhere(
                    (entry) => entry['expense_id'] == expenseId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Expense entry deleted successfully')),
          );
        } else {
          throw Exception('Failed to delete expense entry');
        }
      } else {
        throw Exception('API call failed with status code: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting entry: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Expense Entry List'),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16.0),
        itemCount: _expenseEntries.length + (_isLoading ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _expenseEntries.length) {
            return Center(child: CircularProgressIndicator());
          }

          final entry = _expenseEntries[index];
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FullImageViewScreen(
                                imageUrl:
                                'https://thakurassociates.trinitysoftwares.in/userpanel/uploaded/expence_img/${entry['exp_img']}',
                              ),
                            ),
                          );
                        },
                        child: Text('View Document'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final bool? confirmDelete = await showDialog<bool>(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Confirm Delete'),
                                content: Text(
                                    'Are you sure you want to delete this expense entry?'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(false);
                                    },
                                    child: Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                    child: Text('Delete'),
                                  ),
                                ],
                              );
                            },
                          );

                          if (confirmDelete == true) {
                            await _deleteExpenseEntry(entry['expense_id']);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('DELETE'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class FullImageViewScreen extends StatelessWidget {
  final String imageUrl;
  const FullImageViewScreen({Key? key, required this.imageUrl})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document View'),
      ),
      body: Center(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            }
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                    (loadingProgress.expectedTotalBytes ?? 1)
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Text('Image not available');
          },
        ),
      ),
    );
  }
}
