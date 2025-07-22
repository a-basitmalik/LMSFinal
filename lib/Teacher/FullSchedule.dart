import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
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
    required this.teacherId,
    required Map<String, Object> subject,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          _currentIndex == 0
              ? 'Calendar View'
              : DateFormat('MMMM yyyy').format(_focusedDay),
          style: TeacherTextStyles.sectionHeader.copyWith(
            fontSize: 20,
            color: TeacherColors.primaryText,
          ),
        ),
        backgroundColor: TeacherColors.secondaryBackground,
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
        backgroundColor: TeacherColors.scheduleColor,
        onPressed: _showAddClassDialog,
        child: Icon(Icons.add, color: TeacherColors.primaryText),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }


  BottomNavigationBar _buildBottomNavigationBar() {
    final colors = context.teacherColors;

    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() {
        _currentIndex = index;
        if (index == 1) {
          _focusedDay = DateTime.now();
          _selectedDay = DateTime.now();
        }
      }),
      backgroundColor: TeacherColors.secondaryBackground,
      selectedItemColor: TeacherColors.scheduleColor,
      unselectedItemColor: TeacherColors.secondaryText,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

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
                style: TeacherTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: TeacherColors.scheduleColor),
                    onPressed: () => setState(() {
                      _focusedDay = DateTime(
                        _focusedDay.year,
                        _focusedDay.month - 1,
                      );
                    }),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: TeacherColors.scheduleColor),
                    onPressed: () => setState(() {
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
            border: Border(bottom: BorderSide(color: TeacherColors.cardBorder)),
          ),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      fontWeight: FontWeight.w500,
                      color: day == 'S' ? TeacherColors.dangerAccent : TeacherColors.primaryText,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Calendar grid
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
              weekendTextStyle: TextStyle(color: TeacherColors.dangerAccent),
              todayDecoration: BoxDecoration(
                color: TeacherColors.scheduleColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: TeacherColors.scheduleColor,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TeacherTextStyles.listItemTitle,
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

        // Selected day section
        Flexible(
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: TeacherColors.cardBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('EEEE, MMMM d').format(_selectedDay),
                    style: TeacherTextStyles.sectionHeader.copyWith(
                      color: TeacherColors.scheduleColor,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final weekStart = _focusedDay.subtract(Duration(days: _focusedDay.weekday));
    final weekDays = List.generate(7, (i) => weekStart.add(Duration(days: i)));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: TeacherColors.glassDecoration(),
          child: Row(
            children: weekDays.map((day) {
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
                          color: isSameDay(day, _selectedDay)
                              ? TeacherColors.scheduleColor
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          DateFormat('E').format(day),
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSameDay(day, DateTime.now())
                                ? TeacherColors.scheduleColor
                                : TeacherColors.primaryText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: TeacherTextStyles.cardSubtitle.copyWith(
                            color: isSameDay(day, DateTime.now())
                                ? TeacherColors.scheduleColor
                                : TeacherColors.secondaryText,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final daySchedule =
    _schedule.where((item) => isSameDay(item.date, _selectedDay)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay),
            style: TeacherTextStyles.sectionHeader.copyWith(
              fontSize: 20,
              color: TeacherColors.scheduleColor,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final daySchedule =
    _schedule.where((item) => isSameDay(item.date, day)).toList();

    if (daySchedule.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(day),
              style: TeacherTextStyles.cardSubtitle,
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
            style: TeacherTextStyles.cardSubtitle,
          ),
        ),
        ...daySchedule.map((item) => _buildScheduleItem(item)),
      ],
    );
  }

  Widget _buildEmptyState() {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: TeacherColors.glassDecoration(),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_available, size: 60, color: TeacherColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              'No classes scheduled',
              style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(ClassSchedule item) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: TeacherColors.glassDecoration(),
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
                  style: TeacherTextStyles.assignmentTitle,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherColors.scheduleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.classType,
                    style: TeacherTextStyles.secondaryButton.copyWith(
                      color: TeacherColors.scheduleColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: TeacherColors.secondaryText),
                const SizedBox(width: 8),
                Text(
                  item.time,
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: TeacherColors.secondaryText),
                const SizedBox(width: 8),
                Text(
                  item.room,
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: TeacherColors.secondaryText),
                const SizedBox(width: 8),
                Text(
                  item.teacher,
                  style: TeacherTextStyles.listItemSubtitle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddClassDialog() async {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

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
              title: Text('Add New Class', style: TeacherTextStyles.sectionHeader),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                          labelStyle: TeacherTextStyles.cardSubtitle,
                        ),
                        style: TeacherTextStyles.listItemTitle,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => subject = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Time (e.g., 09:00 AM - 10:30 AM)',
                          border: OutlineInputBorder(),
                          labelStyle: TeacherTextStyles.cardSubtitle,
                        ),
                        style: TeacherTextStyles.listItemTitle,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => time = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Room',
                          border: OutlineInputBorder(),
                          labelStyle: TeacherTextStyles.cardSubtitle,
                        ),
                        style: TeacherTextStyles.listItemTitle,
                        validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                        onSaved: (value) => room = value ?? '',
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: classType,
                        decoration: InputDecoration(
                          labelText: 'Class Type',
                          border: OutlineInputBorder(),
                          labelStyle: TeacherTextStyles.cardSubtitle,
                        ),
                        style: TeacherTextStyles.listItemTitle,
                        items: ['Lecture', 'Lab', 'Tutorial', 'Seminar']
                            .map(
                              (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: TeacherTextStyles.listItemTitle),
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
                          decoration: InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            labelStyle: TeacherTextStyles.cardSubtitle,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat.yMd().format(selectedDate),
                                style: TeacherTextStyles.listItemTitle,
                              ),
                              Icon(Icons.calendar_today, color: TeacherColors.primaryText),
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
                  child: Text('Cancel', style: TeacherTextStyles.secondaryButton),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherColors.scheduleColor,
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
                        SnackBar(
                          content: Text(
                            'Class added successfully',
                            style: TeacherTextStyles.cardSubtitle,
                          ),
                          backgroundColor: TeacherColors.successAccent,
                        ),
                      );
                    }
                  },
                  child: Text(
                    'Add Class',
                    style: TeacherTextStyles.primaryButton,
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
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          isTodayOnly ? "Today's Schedule" : _formatDate(date!),
          style: TeacherTextStyles.sectionHeader.copyWith(
            fontSize: 20,
            color: TeacherColors.primaryText,
          ),
        ),
        backgroundColor: TeacherColors.secondaryBackground,
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
    final colors = TeacherColors;
    final textStyles = TeacherTextStyles;

    if (schedule.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 60, color: TeacherColors.secondaryText),
            const SizedBox(height: 16),
            Text(
              isTodayOnly
                  ? 'No classes scheduled for today'
                  : 'No classes scheduled for this day',
              style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 16),

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
          decoration: TeacherColors.glassDecoration(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['subject'],
                  style: TeacherTextStyles.assignmentTitle,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: TeacherColors.secondaryText),
                    const SizedBox(width: 8),
                    Text(
                      item['time'],
                      style: TeacherTextStyles.listItemSubtitle,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.class_, size: 16, color: TeacherColors.secondaryText),
                    const SizedBox(width: 8),
                    Text(
                      '${item['class']} - ${item['room']}',
                      style: TeacherTextStyles.listItemSubtitle,
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