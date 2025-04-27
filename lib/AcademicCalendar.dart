import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academic Calendar',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00F0FF),
          brightness: Brightness.dark,
          background: const Color(0xFF0A0A1A),
        ),
        useMaterial3: true, // This should be outside ColorScheme
      ),
      home: const AcademicCalendarScreen(),
      debugShowCheckedModeBanner: false,
    );

  }
}

class AcademicCalendarScreen extends StatefulWidget {
  const AcademicCalendarScreen({super.key});

  @override
  State<AcademicCalendarScreen> createState() => _AcademicCalendarScreenState();
}

class _AcademicCalendarScreenState extends State<AcademicCalendarScreen> {
  String _selectedYear = '2023-24';
  String _selectedMonth = 'January';
  int _selectedYearIndex = 1; // 0: previous, 1: current, 2: next
  int _selectedMonthIndex = 0;

  final List<String> _years = ['2022-23', '2023-24', '2024-25'];
  final List<String> _months = [
    'January', 'February', 'March', 'April',
    'May', 'June', 'July', 'August',
    'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'ACADEMIC CALENDAR',
                style: GoogleFonts.orbitron(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.cyanAccent,
                ),
              ),
              centerTitle: true,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0066FF).withOpacity(0.7),
                      const Color(0xFF00F0FF).withOpacity(0.5),
                      Colors.transparent,
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
                  // Year Selection Card
                  GlassCard(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT ACADEMIC YEAR',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildYearButton(
                                  label: _years[0],
                                  isSelected: _selectedYearIndex == 0,
                                  onTap: () => _updateYearSelection(0),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildYearButton(
                                  label: _years[1],
                                  isSelected: _selectedYearIndex == 1,
                                  onTap: () => _updateYearSelection(1),
                                  isPrimary: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildYearButton(
                                  label: _years[2],
                                  isSelected: _selectedYearIndex == 2,
                                  onTap: () => _updateYearSelection(2),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Month Selection Card
                  GlassCard(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SELECT MONTH',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _months.length,
                              itemBuilder: (context, index) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildMonthButton(
                                    month: _months[index],
                                    isSelected: _selectedMonthIndex == index,
                                    onTap: () => _updateMonthSelection(index),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Events Card
                  GlassCard(
                    borderRadius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACADEMIC EVENTS',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildEventsList(),
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

  Widget _buildYearButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: isSelected
              ? LinearGradient(
            colors: isPrimary
                ? [
              const Color(0xFF00F0FF),
              const Color(0xFF0066FF),
            ]
                : [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          )
              : null,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.cyanAccent.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.orbitron(
              color: isSelected
                  ? isPrimary
                  ? Colors.black
                  : Colors.white
                  : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthButton({
    required String month,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: isSelected
              ? LinearGradient(
            colors: [
              Colors.cyanAccent.withOpacity(0.3),
              Colors.blueAccent.withOpacity(0.3),
            ],
          )
              : null,
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.cyanAccent.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            month.substring(0, 3).toUpperCase(),
            style: GoogleFonts.orbitron(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList() {
    // Dummy events data - replace with your actual data
    final events = [
      {
        'title': 'Semester Begins',
        'date': '${_selectedMonth} 1',
        'type': 'academic',
      },
      {
        'title': 'Mid-Term Exams',
        'date': '${_selectedMonth} 15-20',
        'type': 'exam',
      },
      {
        'title': 'Faculty Meeting',
        'date': '${_selectedMonth} 25',
        'type': 'meeting',
      },
      {
        'title': 'Holiday',
        'date': '${_selectedMonth} 30',
        'type': 'holiday',
      },
    ];

    return Column(
      children: events.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildEventCard(
            title: event['title']!,
            date: event['date']!,
            type: event['type']!,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEventCard({
    required String title,
    required String date,
    required String type,
  }) {
    Color eventColor;
    IconData eventIcon;

    switch (type) {
      case 'exam':
        eventColor = Colors.redAccent;
        eventIcon = Icons.assignment;
        break;
      case 'meeting':
        eventColor = Colors.blueAccent;
        eventIcon = Icons.people;
        break;
      case 'holiday':
        eventColor = Colors.greenAccent;
        eventIcon = Icons.beach_access;
        break;
      default:
        eventColor = Colors.cyanAccent;
        eventIcon = Icons.school;
    }

    return GlassCard(
      borderRadius: 12,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    eventColor.withOpacity(0.8),
                    eventColor.withOpacity(0.2),
                  ],
                ),
              ),
              child: Icon(
                eventIcon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: GoogleFonts.orbitron(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _updateYearSelection(int index) {
    setState(() {
      _selectedYearIndex = index;
      _selectedYear = _years[index];
      // Update events based on year selection
    });
  }

  void _updateMonthSelection(int index) {
    setState(() {
      _selectedMonthIndex = index;
      _selectedMonth = _months[index];
      // Update events based on month selection
    });
  }
}

class GlassCard extends StatelessWidget {
  final Widget? child;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsets? padding;

  const GlassCard({
    super.key,
    this.child,
    this.borderRadius = 16,
    this.borderColor,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.05),
            Colors.white.withOpacity(0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: padding != null
            ? Padding(
          padding: padding!,
          child: child,
        )
            : child,
      ),
    );
  }
}