import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HolographicCalendarScreen extends StatefulWidget {
  final int campusID;

  const HolographicCalendarScreen({required this.campusID, Key? key}) : super(key: key);

  @override
  _HolographicCalendarScreenState createState() => _HolographicCalendarScreenState();
}

class _HolographicCalendarScreenState extends State<HolographicCalendarScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Color?> _colorAnimation;

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
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.cyanAccent.withOpacity(0.7),
      end: Colors.purpleAccent.withOpacity(0.7),
    ).animate(_animationController);

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
          backgroundColor: Colors.red,
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
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.blue.shade900.withOpacity(_fadeAnimation.value * 0.3),
                      Colors.indigo.shade900.withOpacity(_fadeAnimation.value * 0.3),
                      Colors.black,
                    ],
                    stops: [0.1, 0.5, 1.0],
                  ),
                ),
                child: CustomPaint(
                  painter: _ParticlePainter(animation: _animationController),
                ),
              );
            },
          ),
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 150,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        'PLANNER CALENDAR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: Colors.white.withOpacity(_fadeAnimation.value),
                          shadows: [
                            Shadow(
                              blurRadius: 10 * _fadeAnimation.value,
                              color: Colors.cyanAccent.withOpacity(_fadeAnimation.value),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.blue.shade900.withOpacity(0.7),
                          Colors.indigo.shade800.withOpacity(0.7),
                          Colors.purple.shade900.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return GlassCard(
                            borderColor: _colorAnimation.value,
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
                                  defaultTextStyle: TextStyle(color: Colors.white),
                                  weekendTextStyle: TextStyle(color: Colors.white),
                                  outsideTextStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                                  selectedTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                  todayTextStyle: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                                  todayDecoration: BoxDecoration(
                                    color: Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.cyanAccent, width: 2),
                                  ),
                                  selectedDecoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.cyanAccent, Colors.purpleAccent],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  markerDecoration: BoxDecoration(
                                    color: Colors.cyanAccent,
                                    shape: BoxShape.circle,
                                  ),
                                  markerSize: 6,
                                ),
                                headerStyle: HeaderStyle(
                                  formatButtonVisible: true,
                                  titleCentered: true,
                                  formatButtonShowsNext: false,
                                  formatButtonDecoration: BoxDecoration(
                                    border: Border.all(color: Colors.cyanAccent),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  formatButtonTextStyle: TextStyle(color: Colors.white),
                                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.cyanAccent),
                                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.cyanAccent),
                                  titleTextStyle: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                daysOfWeekStyle: DaysOfWeekStyle(
                                  weekdayStyle: TextStyle(color: Colors.white),
                                  weekendStyle: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 20),
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PLANNERS ON ${DateFormat('MMMM d, y').format(_selectedDay!)}',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Divider(color: Colors.white.withOpacity(0.2)),
                              _isLoading
                                  ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
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
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
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
            onTap: () {
              // You can navigate to planner details here if needed
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: EdgeInsets.only(top: 4, right: 10),
                  decoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('h:mm a').format(plannedDate),
                        style: TextStyle(
                          color: Colors.cyanAccent,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        planner.title ?? 'Untitled Planner',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (planner.subjectName != null) ...[
                        SizedBox(height: 2),
                        Text(
                          planner.subjectName!,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (planner.description != null) ...[
                        SizedBox(height: 4),
                        Text(
                          planner.description!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final double borderRadius;

  const GlassCard({
    Key? key,
    required this.child,
    this.borderColor,
    this.borderRadius = 16,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.2),
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final Animation<double> animation;

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final random = Random(42);
    final particleCount = 30;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 2;
      final opacity = 0.2 + random.nextDouble() * 0.5;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + 0.4 * animation.value),
        paint..color = Colors.cyanAccent.withOpacity(opacity * animation.value),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}