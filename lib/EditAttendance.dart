import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  runApp(AttendanceApp());
}

class AttendanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Attendance Editor',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Color(0xFFBB86FC),
        colorScheme: ColorScheme.dark(
          secondary: Color(0xFF03DAC6),
          surface: Color(0xFF1E1E1E),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[700]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Color(0xFFBB86FC)),
          ),
          filled: true,
          fillColor: Color(0xFF1E1E1E),
        ),
      ),
      home: EditAttendanceScreen(campusID: 1, userType: "Admin"),
    );
  }
}

class AttendanceRecord {
  final int id;
  final String name;
  final String rollNumber;
  final String profilePic;
  String status;
  final String originalStatus;
  bool statusChanged;

  AttendanceRecord({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.profilePic,
    required this.status,
  })  : originalStatus = status,
        statusChanged = false;

  void setStatus(String newStatus) {
    status = newStatus;
    statusChanged = status != originalStatus;
  }

  void resetStatusChanged() {
    statusChanged = false;
  }
}

class EditAttendanceScreen extends StatefulWidget {
  final int campusID;
  final String userType;

  const EditAttendanceScreen({
    Key? key,
    required this.campusID,
    required this.userType,
  }) : super(key: key);

  @override
  _EditAttendanceScreenState createState() => _EditAttendanceScreenState();
}

class _EditAttendanceScreenState extends State<EditAttendanceScreen> {
  late DateTime selectedDate;
  late String selectedClass;
  List<AttendanceRecord> attendanceRecords = [];
  bool isLoading = true;
  bool isSaving = false;
  final List<String> classOptions = ["All Years", "First Year", "Second Year"];
  final List<String> classValues = ["0", "1", "2"];

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    selectedClass = "0";
    fetchAttendanceRecords();
  }

  Future<void> fetchAttendanceRecords() async {
    setState(() {
      isLoading = true;
    });

    try {
      final url =
          "http://193.203.162.232:5050/attendance/get_attendance_edit?campus_id=${widget.campusID}&date=${DateFormat('yyyy-MM-dd').format(selectedDate)}&year=$selectedClass";

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<AttendanceRecord> records = [];
          final attendanceData = data['attendance_data'] as List;

          for (var record in attendanceData) {
            records.add(AttendanceRecord(
              id: record['id'],
              name: record['name'],
              rollNumber: record['roll_number'],
              profilePic: record['profile_pic'] ?? '',
              status: record['status'],
            ));
          }

          setState(() {
            attendanceRecords = records;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching attendance records: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to fetch attendance records'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color(0xFFBB86FC),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1E1E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF1E1E1E),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchAttendanceRecords();
    }
  }

  Future<void> saveAttendanceChanges() async {
    setState(() {
      isSaving = true;
    });

    // Filter only changed records
    final changedRecords = attendanceRecords.where((r) => r.statusChanged).toList();

    if (changedRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes to save')),
      );
      setState(() {
        isSaving = false;
      });
      return;
    }

    // Prepare data for API
    final List<Map<String, dynamic>> updateData = changedRecords
        .map((r) => {
      'id': r.id,
      'status': r.status,
    })
        .toList();

    try {
      // Replace with your actual API endpoint
      final url = "http://193.203.162.232:5050/attendance/update_attendance";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'campus_id': widget.campusID,
          'date': DateFormat('yyyy-MM-dd').format(selectedDate),
          'updates': updateData,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          // Reset changed flags
          for (var record in changedRecords) {
            record.resetStatusChanged();
          }
        }
      }
    } catch (e) {
      print('Error saving attendance: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save attendance'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      setState(() {
        isSaving = false;
      });
    }
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[800]!,
      highlightColor: Colors.grey[700]!,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          child: Container(
            height: 80,
            margin: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentCard(AttendanceRecord record) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Roll #: ${record.rollNumber}',
                      style: TextStyle(
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: record.status == 'Present'
                        ? Colors.green.withOpacity(0.2)
                        : record.status == 'Absent'
                        ? Colors.red.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: record.status == 'Present'
                          ? Colors.green
                          : record.status == 'Absent'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                  child: Text(
                    record.status,
                    style: TextStyle(
                      color: record.status == 'Present'
                          ? Colors.green
                          : record.status == 'Absent'
                          ? Colors.red
                          : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Change Status:',
              style: TextStyle(
                color: Colors.grey[400],
              ),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusButton('Present', record),
                _buildStatusButton('Absent', record),
                _buildStatusButton('Late', record),
              ],
            ),
            if (record.statusChanged)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Status changed',
                  style: TextStyle(
                    color: Color(0xFFBB86FC),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String status, AttendanceRecord record) {
    final isSelected = record.status == status;
    return OutlinedButton(
      onPressed: () {
        setState(() {
          record.setStatus(status);
        });
      },
      style: OutlinedButton.styleFrom(
        disabledBackgroundColor: isSelected ? Colors.white : null,
        backgroundColor: isSelected
            ? status == 'Present'
            ? Colors.green.withOpacity(0.3)
            : status == 'Absent'
            ? Colors.red.withOpacity(0.3)
            : Colors.orange.withOpacity(0.3)
            : null,
        side: BorderSide(
          color: status == 'Present'
              ? Colors.green
              : status == 'Absent'
              ? Colors.red
              : Colors.orange,
        ),
      ),
      child: Text(status),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Edit Attendance'),
        centerTitle: true,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF121212),
                Color(0xFF1E1E1E),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: TextStyle(fontSize: 16),
                              ),
                              Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedClass,
                        decoration: InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        items: classValues.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(classOptions[index]),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedClass = value!;
                          });
                          fetchAttendanceRecords();
                        },
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Edit attendance records for the selected date and class.',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildShimmerLoading()
                : attendanceRecords.isEmpty
                ? Center(
              child: Text(
                'No attendance records found',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: attendanceRecords.length,
              itemBuilder: (context, index) =>
                  _buildStudentCard(attendanceRecords[index]),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Color(0xFFBB86FC)),
                    ),
                    child: Text('Cancel'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveAttendanceChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFBB86FC),
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSaving
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                        : Text('Update'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}