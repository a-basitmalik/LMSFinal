import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';

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
          backgroundColor: AdminColors.dangerAccent,
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
              primary: AdminColors.primaryAccent,
              onPrimary: AdminColors.primaryBackground,
              surface: AdminColors.secondaryBackground,
              onSurface: AdminColors.primaryText,
            ),
            dialogBackgroundColor: AdminColors.secondaryBackground,
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

    final changedRecords = attendanceRecords.where((r) => r.statusChanged).toList();

    if (changedRecords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No changes to save'),
          backgroundColor: AdminColors.infoAccent,
        ),
      );
      setState(() {
        isSaving = false;
      });
      return;
    }

    final List<Map<String, dynamic>> updateData = changedRecords
        .map((r) => {
      'id': r.id,
      'status': r.status,
    })
        .toList();

    try {
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
              backgroundColor: AdminColors.successAccent,
            ),
          );
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
          backgroundColor: AdminColors.dangerAccent,
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
      baseColor: AdminColors.secondaryBackground,
      highlightColor: AdminColors.cardBackground,
      child: ListView.builder(
        itemCount: 5,
        itemBuilder: (context, index) => Card(
          color: AdminColors.cardBackground,
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
      color: AdminColors.cardBackground,
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
                      style: AdminTextStyles.cardTitle.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Roll #: ${record.rollNumber}',
                      style: AdminTextStyles.cardSubtitle,
                    ),
                  ],
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: record.status == 'Present'
                        ? AdminColors.successAccent.withOpacity(0.2)
                        : record.status == 'Absent'
                        ? AdminColors.dangerAccent.withOpacity(0.2)
                        : AdminColors.warningAccent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: record.status == 'Present'
                          ? AdminColors.successAccent
                          : record.status == 'Absent'
                          ? AdminColors.dangerAccent
                          : AdminColors.warningAccent,
                    ),
                  ),
                  child: Text(
                    record.status,
                    style: AdminTextStyles.cardTitle.copyWith(
                      color: record.status == 'Present'
                          ? AdminColors.successAccent
                          : record.status == 'Absent'
                          ? AdminColors.dangerAccent
                          : AdminColors.warningAccent,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Change Status:',
              style: AdminTextStyles.cardSubtitle,
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
                  style: AdminTextStyles.cardSubtitle.copyWith(
                    color: AdminColors.primaryAccent,
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
        backgroundColor: isSelected
            ? status == 'Present'
            ? AdminColors.successAccent.withOpacity(0.3)
            : status == 'Absent'
            ? AdminColors.dangerAccent.withOpacity(0.3)
            : AdminColors.warningAccent.withOpacity(0.3)
            : null,
        side: BorderSide(
          color: status == 'Present'
              ? AdminColors.successAccent
              : status == 'Absent'
              ? AdminColors.dangerAccent
              : AdminColors.warningAccent,
        ),
      ),
      child: Text(
        status,
        style: AdminTextStyles.secondaryButton.copyWith(
          color: status == 'Present'
              ? AdminColors.successAccent
              : status == 'Absent'
              ? AdminColors.dangerAccent
              : AdminColors.warningAccent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AdminColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Edit Attendance',
          style: AdminTextStyles.sectionHeader.copyWith(fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AdminColors.secondaryBackground,
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
                            labelStyle: AdminTextStyles.cardSubtitle,
                            border: OutlineInputBorder(
                              borderSide: BorderSide(color: AdminColors.cardBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: AdminColors.cardBorder),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('yyyy-MM-dd').format(selectedDate),
                                style: AdminTextStyles.cardTitle,
                              ),
                              Icon(Icons.calendar_today,
                                  size: 20, color: AdminColors.primaryText),
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
                          labelStyle: AdminTextStyles.cardSubtitle,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: AdminColors.cardBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AdminColors.cardBorder),
                          ),
                        ),
                        dropdownColor: AdminColors.secondaryBackground,
                        style: AdminTextStyles.cardTitle,
                        items: classValues.asMap().entries.map((entry) {
                          final index = entry.key;
                          final value = entry.value;
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              classOptions[index],
                              style: AdminTextStyles.cardTitle,
                            ),
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
                  style: AdminTextStyles.cardSubtitle,
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
                style: AdminTextStyles.cardSubtitle,
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
                      side: BorderSide(color: AdminColors.primaryAccent),
                    ),
                    child: Text(
                      'Cancel',
                      style: AdminTextStyles.secondaryButton.copyWith(
                        color: AdminColors.primaryAccent,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveAttendanceChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.primaryAccent,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isSaving
                        ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AdminColors.primaryText),
                      ),
                    )
                        : Text(
                      'Update',
                      style: AdminTextStyles.primaryButton,
                    ),
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