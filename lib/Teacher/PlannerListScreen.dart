import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';
import 'AddPlannerScreen.dart';
import 'PlannerDetailScreen.dart';

class PlannerListScreen extends StatefulWidget {
  final int subjectID;

  const PlannerListScreen({required this.subjectID, Key? key}) : super(key: key);

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
        Uri.parse('http://193.203.162.232:5050/Planner/subject/planners?subject_id=${widget.subjectID}'),
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
          backgroundColor: AdminColors.dangerAccent,
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
              primary: AdminColors.primaryAccent,
              onPrimary: AdminColors.primaryBackground,
              surface: AdminColors.secondaryBackground,
              onSurface: AdminColors.primaryText,
            ),
            dialogBackgroundColor: AdminColors.primaryBackground,
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
        builder: (context) => AddPlannerScreen(subjectId: widget.subjectID),
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
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'LESSON PLANNER',
          style: AdminTextStyles.sectionHeader.copyWith(
            color: AdminColors.plannerColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: AdminColors.primaryText),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AdminColors.primaryText),
            onPressed: _refreshPlanners,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPlanners,
        color: AdminColors.primaryAccent,
        backgroundColor: AdminColors.primaryBackground,
        child: _isLoading
            ? Center(
          child: CircularProgressIndicator(
            color: AdminColors.plannerColor,
          ),
        )
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDate),
                    style: AdminTextStyles.sectionHeader,
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AdminColors.plannerColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AdminColors.plannerColor, width: 1),
                    ),
                    child: Text(
                      '${filteredPlanners.length} PLANS',
                      style: AdminTextStyles.cardSubtitle.copyWith(
                        color: AdminColors.plannerColor,
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
                        size: 60, color: AdminColors.disabledText),
                    SizedBox(height: 16),
                    Text(
                      'NO PLANS FOR SELECTED DATE',
                      style: AdminTextStyles.cardSubtitle,
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
          decoration: AdminColors.plannerColor.toCircleDecoration(),
          child: Icon(Icons.add, color: AdminColors.primaryText),
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

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: AdminColors.glassDecoration(
        borderColor: AdminColors.plannerColor,
        borderRadius: 12,
      ),
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
                    style: AdminTextStyles.cardSubtitle.copyWith(
                      color: AdminColors.plannerColor,
                    ),
                  ),
                  Text(
                    DateFormat('h:mm a').format(plannedDate),
                    style: AdminTextStyles.cardSubtitle,
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                planner.title ?? 'Untitled Plan',
                style: AdminTextStyles.cardTitle.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                planner.description ?? 'No description provided',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AdminTextStyles.cardSubtitle.copyWith(
                  fontSize: 14,
                ),
              ),
              if (planner.teacherName != null) ...[
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.person_outline,
                        size: 16, color: AdminColors.secondaryText),
                    SizedBox(width: 4),
                    Text(
                      planner.teacherName!,
                      style: AdminTextStyles.cardSubtitle,
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
  late final String? title;
  late final String? description;
  late final String plannedDate;
  final int? subjectId;
  final String? subjectName;
  final int? teacherId;
  final String? teacherName;
  final String? createdAt;
  late final String? points;
  late final String? homework;

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
    this.points,
    this.homework,
  });

  factory Planner.fromJson(Map<String, dynamic> json) {
    String parseToIso(String? rawDate) {
      if (rawDate == null) return DateTime.now().toIso8601String();
      try {
        return DateTime.parse(rawDate).toIso8601String();
      } catch (_) {
        try {
          final formatter = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'", 'en_US');
          return formatter.parseUtc(rawDate).toIso8601String();
        } catch (e) {
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
      points: json['points'],
      homework: json['homework'],
    );
  }

  List<String> get pointsList {
    if (points == null || points!.isEmpty) return [];
    return points!.split('|||').map((point) => point.trim()).toList();
  }

  bool get hasHomework => homework != null && homework!.isNotEmpty;
  bool get hasPoints => points != null && points!.isNotEmpty;
}