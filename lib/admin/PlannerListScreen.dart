import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'AddPlannerScreen.dart';
import 'PlannerDetailScreen.dart';

class PlannerListScreen extends StatefulWidget {
  final int campusID;

  const PlannerListScreen({required this.campusID, Key? key}) : super(key: key);

  @override
  _PlannerListScreenState createState() => _PlannerListScreenState();
}

class _PlannerListScreenState extends State<PlannerListScreen> {
  List<Planner> _planners = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchPlanners();
  }

  Future<void> _fetchPlanners() async {
    try {
      setState(() => _isLoading = true);

      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/Planner/planners?campus_id=${widget.campusID}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _planners = List<Planner>.from(
              data['planners'].map((planner) => Planner.fromJson(planner))
          );
        });
      } else {
        throw Exception('Failed to load planners: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPlanners() async {
    try {
      setState(() => _isRefreshing = true);
      await _fetchPlanners();
    } finally {
      setState(() => _isRefreshing = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Colors.cyanAccent,
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A2E),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Color(0xFF0A0A1A),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _navigateToAddPlanner() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPlannerScreen(campusID: widget.campusID),
      ),
    );

    if (result == true) {
      _refreshPlanners();
    }
  }

  void _viewPlannerDetails(Planner planner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannerDetailScreen(planner: planner),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlanners = _planners.where((planner) {
      final plannedDate = DateTime.parse(planner.plannedDate);
      return plannedDate.year == _selectedDate.year &&
          plannedDate.month == _selectedDate.month &&
          plannedDate.day == _selectedDate.day;
    }).toList();

    return Scaffold(
      backgroundColor: Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text('LESSON PLANNER'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshPlanners,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlanners,
        color: Colors.cyanAccent,
        backgroundColor: Color(0xFF0A0A1A),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.cyanAccent, width: 1),
                    ),
                    child: Text(
                      '${filteredPlanners.length} PLANS',
                      style: TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredPlanners.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_note,
                        size: 60, color: Colors.white54),
                    SizedBox(height: 16),
                    Text(
                      'NO PLANS FOR SELECTED DATE',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.only(bottom: 80),
                itemCount: filteredPlanners.length,
                itemBuilder: (context, index) {
                  final planner = filteredPlanners[index];
                  return PlannerCard(
                    planner: planner,
                    onTap: () => _viewPlannerDetails(planner),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlanner,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.cyanAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class PlannerCard extends StatelessWidget {
  final Planner planner;
  final VoidCallback onTap;

  const PlannerCard({required this.planner, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final plannedDate = DateTime.parse(planner.plannedDate);


    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.cyanAccent.withOpacity(0.2),
          width: 1,
        ),
      ),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    planner.subjectName ?? 'No Subject',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(plannedDate),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                planner.title ?? 'Untitled Plan',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                planner.description ?? 'No description provided',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              if (planner.teacherName != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: Colors.white70),
                    SizedBox(width: 4),
                    Text(
                      planner.teacherName!,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class Planner {
  final int plannerId;
  final String? title;
  final String? description;
  final String plannedDate;
  final int? subjectId;
  final String? subjectName;
  final int? teacherId;
  final String? teacherName;
  final String? createdAt;

  Planner({
    required this.plannerId,
    this.title,
    this.description,
    required this.plannedDate,
    this.subjectId,
    this.subjectName,
    this.teacherId,
    this.teacherName,
    this.createdAt,
  });

  factory Planner.fromJson(Map<String, dynamic> json) {
    String parseToIso(String? rawDate) {
      if (rawDate == null) return DateTime.now().toIso8601String();
      try {
        // Try ISO 8601 first
        return DateTime.parse(rawDate).toIso8601String();
      } catch (_) {
        try {
          // Try custom format like "Wed, 16 Jul 2025 00:00:00 GMT"
          final formatter = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
          return formatter.parseUtc(rawDate).toIso8601String();
        } catch (e) {
          print('❌ Failed to parse date: $rawDate');
          return DateTime.now().toIso8601String();
        }
      }
    }

    return Planner(
      plannerId: json['planner_id'],
      title: json['title'],
      description: json['description'],
      plannedDate: parseToIso(json['planned_date']),
      subjectId: json['subject_id'],
      subjectName: json['subject_name'],
      teacherId: json['teacher_id'],
      teacherName: json['teacher_name'],
      createdAt: parseToIso(json['created_at']),
    );
  }
}