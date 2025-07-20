import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class HolographicCalendarScreen extends StatefulWidget {
  final int campusID;

  const HolographicCalendarScreen({required this.campusID, Key? key})
      : super(key: key);

  @override
  _HolographicCalendarScreenState createState() =>
      _HolographicCalendarScreenState();
}

class _HolographicCalendarScreenState extends State<HolographicCalendarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Planner>> _plannersMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fetchPlanners();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
        final planners = List<Planner>.from(
            data['planners'].map((planner) => Planner.fromJson(planner))
        );

        setState(() {
          _plannersMap = {};
          for (var planner in planners) {
            final plannedDate = DateTime.parse(planner.plannedDate);
            final dateKey = DateTime(plannedDate.year, plannedDate.month, plannedDate.day);

            if (_plannersMap[dateKey] == null) {
              _plannersMap[dateKey] = [planner];
            } else {
              _plannersMap[dateKey]!.add(planner);
            }
          }
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

  List<Planner> _getPlannersForDay(DateTime day) {
    return _plannersMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
  }

  void _onFormatChanged(CalendarFormat format) {
    setState(() => _calendarFormat = format);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AdminColors.secondaryBackground,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'PLANNER CALENDAR',
                style: AdminTextStyles.portalTitle.copyWith(
                  color: AdminColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AdminColors.secondaryBackground,
                      AdminColors.primaryBackground,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  Container(
                    decoration: AdminColors.glassDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TableCalendar(
                        firstDay: DateTime.utc(2020, 1, 1),
                        lastDay: DateTime.utc(2030, 12, 31),
                        focusedDay: _focusedDay,
                        calendarFormat: _calendarFormat,
                        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                        onDaySelected: _onDaySelected,
                        onFormatChanged: _onFormatChanged,
                        onPageChanged: _onPageChanged,
                        eventLoader: _getPlannersForDay,
                        calendarStyle: CalendarStyle(
                          defaultTextStyle: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText,
                          ),
                          weekendTextStyle: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText,
                          ),
                          outsideTextStyle: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.disabledText,
                          ),
                          selectedTextStyle: AdminTextStyles.cardTitle.copyWith(
                            color: AdminColors.primaryBackground,
                            fontWeight: FontWeight.bold,
                          ),
                          todayTextStyle: AdminTextStyles.cardTitle.copyWith(
                            color: AdminColors.primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AdminColors.secondaryBackground,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AdminColors.primaryAccent,
                              width: 1.5,
                            ),
                          ),
                          selectedDecoration: BoxDecoration(
                            color: AdminColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          markerDecoration: BoxDecoration(
                            color: AdminColors.primaryAccent,
                            shape: BoxShape.circle,
                          ),
                          markerSize: 6,
                          cellPadding: const EdgeInsets.all(4),
                        ),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: true,
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          formatButtonDecoration: BoxDecoration(
                            border: Border.all(color: AdminColors.primaryAccent),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          formatButtonTextStyle: AdminTextStyles.secondaryButton.copyWith(
                            color: AdminColors.primaryText,
                          ),
                          leftChevronIcon: Icon(
                            Icons.chevron_left,
                            color: AdminColors.primaryAccent,
                          ),
                          rightChevronIcon: Icon(
                            Icons.chevron_right,
                            color: AdminColors.primaryAccent,
                          ),
                          titleTextStyle: AdminTextStyles.sectionHeader,
                        ),
                        daysOfWeekStyle: DaysOfWeekStyle(
                          weekdayStyle: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText,
                          ),
                          weekendStyle: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryText,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: AdminColors.glassDecoration(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLANNERS ON ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                            style: AdminTextStyles.sectionHeader,
                          ),
                          Divider(color: AdminColors.cardBorder),
                          _isLoading
                              ? Center(
                            child: CircularProgressIndicator(
                              color: AdminColors.primaryAccent,
                            ),
                          )
                              : _buildPlannersList(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlannersList() {
    final planners = _getPlannersForDay(_selectedDay!);

    if (planners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Center(
          child: Text(
            'No planners scheduled',
            style: AdminTextStyles.cardSubtitle.copyWith(
              color: AdminColors.disabledText,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: planners.map((planner) {
        final plannedDate = DateTime.parse(planner.plannedDate);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () {
              // You can navigate to planner details here if needed
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AdminColors.cardBackground,
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4, right: 12),
                    decoration: BoxDecoration(
                      color: AdminColors.primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(plannedDate),
                          style: AdminTextStyles.cardSubtitle.copyWith(
                            color: AdminColors.primaryAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          planner.title ?? 'Untitled Planner',
                          style: AdminTextStyles.cardTitle.copyWith(
                            color: AdminColors.primaryText,
                          ),
                        ),
                        if (planner.subjectName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            planner.subjectName!,
                            style: AdminTextStyles.cardSubtitle,
                          ),
                        ],
                        if (planner.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            planner.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AdminTextStyles.cardSubtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
    );
  }
}