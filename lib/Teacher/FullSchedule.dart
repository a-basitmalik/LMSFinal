import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ClassSchedule {
  final String id;
  final String subject;
  final String time;
  final String room;
  final DateTime date;
  final String classType;
  final String teacher;

  ClassSchedule({
    required this.id,
    required this.subject,
    required this.time,
    required this.room,
    required this.date,
    required this.classType,
    required this.teacher,
  });

  factory ClassSchedule.fromJson(Map<String, dynamic> json) {
    return ClassSchedule(
      id: json['id'] as String,
      subject: json['subject'] as String,
      time: json['time'] as String,
      room: json['room'] as String,
      date: DateTime.parse(json['date'] as String),
      classType: json['classType'] as String,
      teacher: json['teacher'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject': subject,
    'time': time,
    'room': room,
    'date': date.toIso8601String(),
    'classType': classType,
    'teacher': teacher,
  };
}

class FullScheduleScreen extends StatefulWidget {
  const FullScheduleScreen({
    super.key,
    required this.schedule,
    required this.teacherId, required Map<String, Object> subject,
  });

  final List<Map<String, dynamic>> schedule;
  final String teacherId;
  @override
  _FullScheduleScreenState createState() => _FullScheduleScreenState();
}

class _FullScheduleScreenState extends State<FullScheduleScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final Color _primaryColor = const Color(0xFF4361EE);
  final Color _backgroundColor = const Color(0xFFF8F9FF);
  int _currentIndex = 1;

  final List<ClassSchedule> _schedule = [
    ClassSchedule(
      id: '1',
      subject: 'Mathematics',
      time: '09:00 AM - 10:30 AM',
      room: 'Room 101',
      date: DateTime.now(),
      classType: 'Lecture',
      teacher: 'Dr. Robert Chen',
    ),
    ClassSchedule(
      id: '2',
      subject: 'Physics',
      time: '11:00 AM - 12:30 PM',
      room: 'Lab 205',
      date: DateTime.now(),
      classType: 'Lab',
      teacher: 'Dr. Robert Chen',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Calendar View'
              : DateFormat('MMMM yyyy').format(_focusedDay),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildCurrentView(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primaryColor,
        onPressed: _showAddClassDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap:
          (index) => setState(() {
            _currentIndex = index;
            if (index == 1) {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            }
          }),
      backgroundColor: Colors.white,
      selectedItemColor: _primaryColor,
      unselectedItemColor: Colors.grey,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_today),
          label: 'Calendar',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.view_week), label: 'Week'),
        BottomNavigationBarItem(icon: Icon(Icons.today), label: 'Day'),
      ],
    );
  }

  Widget _buildCurrentView() {
    switch (_currentIndex) {
      case 0:
        return _buildCalendarView();
      case 1:
        return _buildWeeklyView();
      case 2:
        return _buildDailyView();
      default:
        return _buildWeeklyView();
    }
  }

  Widget _buildCalendarView() {
    return Column(
      children: [
        // Month header and navigation buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDay),
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: _primaryColor),
                    onPressed:
                        () => setState(() {
                          _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month - 1,
                          );
                        }),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: _primaryColor),
                    onPressed:
                        () => setState(() {
                          _focusedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month + 1,
                          );
                        }),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Weekday headers
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children:
                ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w500,
                          color: day == 'S' ? Colors.red : Colors.black87,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),

        // Calendar grid - now in an Expanded widget
        Expanded(
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            calendarFormat: CalendarFormat.month,
            headerVisible: false,
            daysOfWeekVisible: false,
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              weekendTextStyle: TextStyle(color: Colors.red[400]),
              todayDecoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: _primaryColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: GoogleFonts.poppins(),
            ),
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
          ),
        ),

        // Selected day section - now in a Flexible widget with SingleChildScrollView
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildDayScheduleSection(_selectedDay),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyView() {
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children:
                weekDays.map((day) {
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDay = day;
                          _currentIndex = 2;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color:
                                  isSameDay(day, _selectedDay)
                                      ? _primaryColor
                                      : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              DateFormat('E').format(day),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color:
                                    isSameDay(day, DateTime.now())
                                        ? _primaryColor
                                        : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              day.day.toString(),
                              style: GoogleFonts.poppins(
                                color:
                                    isSameDay(day, DateTime.now())
                                        ? _primaryColor
                                        : Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (final day in weekDays) _buildDayScheduleSection(day),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyView() {
    final daySchedule =
        _schedule.where((item) => isSameDay(item.date, _selectedDay)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          if (daySchedule.isEmpty)
            _buildEmptyState()
          else
            ...daySchedule.map((item) => _buildScheduleItem(item)),
        ],
      ),
    );
  }

  Widget _buildDayScheduleSection(DateTime day) {
    final daySchedule =
        _schedule.where((item) => isSameDay(item.date, day)).toList();

    if (daySchedule.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(day),
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            _buildEmptyState(),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            DateFormat('EEEE, MMMM d').format(day),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...daySchedule.map((item) => _buildScheduleItem(item)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ClassSchedule item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  item.subject,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.classType,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: _primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  item.time,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  item.room,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  item.teacher,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddClassDialog() async {
    final formKey = GlobalKey<FormState>();
    String subject = '';
    String time = '';
    String room = '';
    DateTime selectedDate = DateTime.now();
    String classType = 'Lecture';

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Add New Class', style: GoogleFonts.poppins()),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => subject = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Time (e.g., 09:00 AM - 10:30 AM)',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => time = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Room',
                          border: OutlineInputBorder(),
                        ),
                        validator:
                            (value) =>
                                value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => room = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: classType,
                        decoration: const InputDecoration(
                          labelText: 'Class Type',
                          border: OutlineInputBorder(),
                        ),
                        items:
                            ['Lecture', 'Lab', 'Tutorial', 'Seminar']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => classType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setState(() => selectedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat.yMd().format(selectedDate)),
                              const Icon(Icons.calendar_today),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                  ),
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      formKey.currentState?.save();
                      final newClass = ClassSchedule(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        subject: subject,
                        time: time,
                        room: room,
                        date: selectedDate,
                        classType: classType,
                        teacher: 'Dr. Robert Chen',
                      );
                      setState(() {
                        _schedule.add(newClass);
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Class added successfully'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Add Class',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class TodayScheduleScreen extends StatelessWidget {
  final List<Map<String, dynamic>> schedule;
  final bool isTodayOnly;
  final DateTime? date;

  const TodayScheduleScreen({
    super.key,
    required this.schedule,
    this.isTodayOnly = false,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF4361EE);
    final backgroundColor = const Color(0xFFF8F9FF);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          isTodayOnly ? "Today's Schedule" : _formatDate(date!),
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildScheduleList(),
    );
  }

  Widget _buildScheduleList() {
    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              isTodayOnly
                  ? 'No classes scheduled for today'
                  : 'No classes scheduled for this day',
              style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: schedule.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = schedule[index];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['subject'],
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      item['time'],
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${item['class']} - ${item['room']}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
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

  String _formatDate(DateTime date) {
    return DateFormat('EEEE, MMMM d').format(date);
  }
}

// API Service class
class ScheduleApiService {
  static const String baseUrl = 'https://your-api-url.com/api/schedule';

  static Future<List<ClassSchedule>> fetchSchedule(String teacherId) async {
    final response = await http.get(Uri.parse('$baseUrl?teacherId=$teacherId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => ClassSchedule.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load schedule');
    }
  }

  static Future<void> addSchedule(ClassSchedule schedule) async {
    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(schedule.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add schedule');
    }
  }

  static Future<void> deleteSchedule(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));

    if (response.statusCode != 200) {
      throw Exception('Failed to delete schedule');
    }
  }
}
