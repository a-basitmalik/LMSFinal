import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:ui';
import 'package:intl/intl.dart';
// Import other screens
import 'SubjectAssignments.dart';
import 'SubjectQueries.dart';
import 'SubjectResults.dart';
import 'SubjectAttendance.dart';
import 'SubjectAnnouncementsScreen.dart';
import 'SubjectChat.dart';

class SubjectDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  final String teacherId;

  const SubjectDashboardScreen({
    super.key,
    required this.subject,
    required this.teacherId,
  });

  @override
  _SubjectDashboardScreenState createState() => _SubjectDashboardScreenState();
}

class _SubjectDashboardScreenState extends State<SubjectDashboardScreen> {
  int _currentIndex = 0;
  late List<Widget> _screens;
  bool _isMenuOpen = false;

  // Data variables
  Map<String, dynamic> subjectStats = {};
  List<dynamic> announcements = [];
  List<dynamic> assignments = [];
  List<dynamic> queries = [];
  List<dynamic> attendance = [];
  List<dynamic> planners = [];
  bool isLoading = true;
  String errorMessage = '';

  // API Endpoints
  final String baseUrl = 'http://193.203.162.232:5050/TeacherSubject/api';

  @override
  void initState() {
    super.initState();
    _screens = []; // Initialize empty list
    _fetchSubjectData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Now it's safe to access inherited widgets
    _screens = [
      _buildOverviewScreen(),
      SubjectAssignmentsScreen(subject: widget.subject),
      SubjectQueriesScreen(subject: widget.subject),
      SubjectResultsScreen(subject: widget.subject),
      SubjectAttendanceScreen(subject: widget.subject),
      SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
    ];
  }

  Future<void> _fetchSubjectData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Fetch all data in parallel
      final responses = await Future.wait([
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/stats')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/announcements')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/assignments')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/queries')),
        http.get(Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/attendance')),
        http.get(Uri.parse('$baseUrl/SubjectPlanner/subject/${widget.subject['subject_id']}/planners')),
      ], eagerError: true);

      // Parse responses
      setState(() {
        subjectStats = _parseResponse(responses[0]);
        announcements = _parseResponse(responses[1]) ?? [];
        assignments = _parseResponse(responses[2]) ?? [];
        queries = _parseResponse(responses[3]) ?? [];
        attendance = _parseResponse(responses[4]) ?? [];
        planners = _parseResponse(responses[5]) ?? [];
        isLoading = false;
      });

      // Initialize screens after data is loaded
      _screens = [
        _buildOverviewScreen(),
        SubjectAssignmentsScreen(subject: widget.subject),
        SubjectQueriesScreen(subject: widget.subject),
        SubjectResultsScreen(subject: widget.subject),
        SubjectAttendanceScreen(subject: widget.subject),
        SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
      ];
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading data: ${e.toString()}';
        isLoading = false;

        // Initialize with empty data to prevent UI from getting stuck
        subjectStats = {};
        announcements = [];
        assignments = [];
        queries = [];
        attendance = [];
        planners = [];

        _screens = [
          _buildOverviewScreen(),
          SubjectAssignmentsScreen(subject: widget.subject),
          SubjectQueriesScreen(subject: widget.subject),
          SubjectResultsScreen(subject: widget.subject),
          SubjectAttendanceScreen(subject: widget.subject),
          SubjectChatScreen(subject: widget.subject, teacherId: widget.teacherId),
        ];
      });
    }
  }

  dynamic _parseResponse(http.Response response) {
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 404) {
      return null; // or empty list/map depending on expected type
    } else {
      throw Exception('Failed to load data: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: _currentIndex == 0
          ? AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: animation,
                child: child,
              ),
            );
          },
          child: Text(
            widget.subject['name'],
            key: ValueKey(widget.subject['name']),
            style: TeacherTextStyles.className.copyWith(
                shadows: [
            Shadow(
            color: TeacherColors.primaryAccent.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
            )
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: TeacherColors.glassDecoration(
          borderColor: TeacherColors.cardBorder.withOpacity(0.3),
          borderRadius: 0, // Match appbar shape
        ).copyWith(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              TeacherColors.primaryBackground.withOpacity(0.85),
              TeacherColors.secondaryBackground.withOpacity(0.9),
            ],
            stops: const [0.5, 1.0],
          ),
        ),
      ),
      centerTitle: true,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
      iconTheme: IconThemeData(
        color: TeacherColors.primaryText,
      ),
    )
        : null,
    body: Stack(
    children: [
    // Main screen content with enhanced transition
    AnimatedSwitcher(
    duration: const Duration(milliseconds: 450),
    switchInCurve: Curves.easeInOutQuart,
    switchOutCurve: Curves.easeInOutQuart,
    transitionBuilder: (Widget child, Animation<double> animation) {
    return FadeTransition(
    opacity: animation,
    child: SlideTransition(
    position: Tween<Offset>(
    begin: const Offset(0.2, 0),
    end: Offset.zero,
    ).animate(animation),
    child: child,
    ),
    );
    },
    child: _screens.isNotEmpty
    ? _screens[_currentIndex]
        : Center(
    child: SizedBox(
    width: 40,
    height: 40,
    child: CircularProgressIndicator(
    strokeWidth: 2.5,
    valueColor: AlwaysStoppedAnimation(
    TeacherColors.primaryAccent,
    ),
    ),
    ),
    ),
    ),

    // Enhanced glass morphic overlay for menu
    if (_isMenuOpen) ...[
    AnimatedOpacity(
    opacity: _isMenuOpen ? 1.0 : 0.0,
    duration: const Duration(milliseconds: 350),
    child: BackdropFilter(
    filter: ImageFilter.blur(
    sigmaX: 10.0,
    sigmaY: 10.0,
    tileMode: TileMode.decal,
    ),
    child: Container(
    decoration: BoxDecoration(
    gradient: RadialGradient(
    center: Alignment.topRight,
    radius: 1.5,
    colors: [
    TeacherColors.primaryBackground.withOpacity(0.4),
    TeacherColors.primaryBackground.withOpacity(0.8),
    ],
    stops: const [0.1, 0.9],
    ),
    ),
    ),
    ),
    ),
    AnimatedPositioned(
    duration: const Duration(milliseconds: 400),
    curve: Curves.fastEaseInToSlowEaseOut,
    bottom: _isMenuOpen ? 0 : -20,
    child: ScaleTransition(
    scale: _isMenuOpen
    ? AlwaysStoppedAnimation(1.0)
        : Tween<double>(begin: 0.9, end: 1.0).animate(
    CurvedAnimation(
    parent: ModalRoute.of(context)!.animation!,
    curve: Curves.elasticOut,
    ),
    ),
    child: _buildInfographicMenu(),
    ),
    ),
    ],
    ],
    ),
    floatingActionButton: _buildMainFAB(),
    );
  }


  Widget _buildOverviewScreen() {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation(TeacherColors.primaryAccent),
            backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(errorMessage),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: TeacherColors.glassDecoration(
                  borderRadius: 12,
                  borderColor: TeacherColors.dangerAccent.withOpacity(0.3),
                ),
                child: Text(
                  errorMessage,
                  style: TextStyle(
                    color: TeacherColors.dangerAccent,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _fetchSubjectData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.dangerAccent.withOpacity(0.9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  elevation: 2,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Retry',
                    key: const ValueKey('retry'),
                    style: TeacherTextStyles.primaryButton.copyWith(
                      shadows: [
                        Shadow(
                          color: TeacherColors.dangerAccent.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: SingleChildScrollView(
        key: const ValueKey('overview-content'),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildGlassCard(child: _buildQuickStatsPanel()),
            const SizedBox(height: 24),
            _buildGlassCard(child: _buildTodaysPlannerSection()),
            const SizedBox(height: 24),
            _buildSectionPreview(
              title: 'Recent Announcements',
              icon: Icons.announcement,
              onViewAll: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      SubjectAnnouncementScreen(subject: widget.subject),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              ),
              child: _buildAnnouncementsPreview(),
            ),
            _buildSectionPreview(
              title: 'Upcoming Assignments',
              icon: Icons.assignment,
              onViewAll: () => _navigateToScreen(1),
              child: _buildAssignmentsPreview(),
            ),
            _buildSectionPreview(
              title: 'Pending Queries',
              icon: Icons.question_answer,
              onViewAll: () => _navigateToScreen(2),
              child: _buildQueriesPreview(),
            ),
            _buildSectionPreview(
              title: 'Attendance Summary',
              icon: Icons.people,
              onViewAll: () => _navigateToScreen(4),
              child: _buildAttendancePreview(),
            ),
            _buildSectionPreview(
              title: 'Recent Messages',
              icon: Icons.chat,
              onViewAll: () => _navigateToScreen(5),
              child: _buildChatPreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: TeacherColors.glassDecoration(
        borderRadius: 16,
        borderColor: TeacherColors.cardBorder.withOpacity(0.4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: child,
      ),
    );
  }

  Widget _buildTodaysPlannerSection() {
    final today = DateTime.now();
    final todayPlanners = planners.where((planner) {
      final plannerDate = DateTime.parse(planner['planned_date']);
      return plannerDate.year == today.year &&
          plannerDate.month == today.month &&
          plannerDate.day == today.day;
    }).toList();

    if (todayPlanners.isEmpty) {
      return _buildSectionPreview(
        title: "Today's Planner",
        icon: Icons.calendar_today,
        onViewAll: () => _showAllPlanners(),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '                                                No plans for today                                            ',
            style: TeacherTextStyles.cardSubtitle,
          ),
        ),
      );
    }

    return _buildSectionPreview(
      title: "Today's Planner",
      icon: Icons.calendar_today,
      onViewAll: () => _showAllPlanners(),
      child: Column(
        children: todayPlanners.take(2).map((planner) {
          return AnimatedPadding(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showPlannerDetails(planner),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: TeacherColors.glassDecoration(
                  borderRadius: 16,
                  borderColor: TeacherColors.classColor.withOpacity(0.3),
                ).copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: TeacherColors.classColor.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Glowing background effect
                    Positioned.fill(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 1500),
                        curve: Curves.easeInOutSine,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: RadialGradient(
                            center: Alignment.topLeft,
                            radius: 1.5,
                            colors: [
                              TeacherColors.classColor.withOpacity(0.05),
                              TeacherColors.classColor.withOpacity(0.01),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Animated glowing icon
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: TeacherColors.classColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              backgroundColor: TeacherColors.classColor.withOpacity(0.15),
                              child: Icon(
                                Icons.event_available,
                                color: TeacherColors.classColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  planner['title'] ?? 'No title',
                                  style: TeacherTextStyles.cardTitle.copyWith(
                                    shadows: [
                                      Shadow(
                                        color: TeacherColors.primaryText.withOpacity(0.1),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  planner['description'] != null &&
                                      planner['description'].isNotEmpty
                                      ? planner['description'].length > 50
                                      ? '${planner['description'].substring(0, 50)}...'
                                      : planner['description']
                                      : 'No description',
                                  style: TeacherTextStyles.cardSubtitle.copyWith(
                                    color: TeacherColors.secondaryText.withOpacity(0.8),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          // Animated forward arrow
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              key: ValueKey(planner['id']),
                              size: 16,
                              color: TeacherColors.classColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showAllPlanners() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              Text(
                'All Planners',
                style: TeacherTextStyles.sectionHeader,
              ),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: planners.length,
                  itemBuilder: (context, index) {
                    final planner = planners[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: TeacherColors.classColor.withOpacity(0.2),
                          child: Icon(Icons.calendar_today, color: TeacherColors.classColor),
                        ),
                        title: Text(
                          planner['title'] ?? 'No title',
                          style: TeacherTextStyles.cardTitle,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('MMM dd, yyyy').format(
                                  DateTime.parse(planner['planned_date'])),
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                            SizedBox(height: 4),
                            Text(
                              planner['description'] != null &&
                                  planner['description'].isNotEmpty
                                  ? planner['description'].length > 50
                                  ? '${planner['description'].substring(0, 50)}...'
                                  : planner['description']
                                  : 'No description',
                              style: TeacherTextStyles.cardSubtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.arrow_forward),
                          onPressed: () => _showPlannerDetails(planner),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPlannerDetails(Map<String, dynamic> planner) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlannerDetailsScreen(
          planner: planner,
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    setState(() {
      _currentIndex = index;
      _isMenuOpen = false;
    });
  }

  Widget _buildInfographicMenu() {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'Overview',
        'icon': Icons.lightbulb_outline,
        'index': 0,
        'color': TeacherColors.dangerAccent,
      },
      {
        'title': 'Assignments',
        'icon': Icons.assignment_outlined,
        'index': 1,
        'color': TeacherColors.assignmentColor,
      },
      {
        'title': 'Queries',
        'icon': Icons.question_answer_outlined,
        'index': 2,
        'color': TeacherColors.infoAccent,
      },
      {
        'title': 'Results',
        'icon': Icons.assessment_outlined,
        'index': 3,
        'color': TeacherColors.successAccent,
      },
      {
        'title': 'Attendance',
        'icon': Icons.calendar_today_outlined,
        'index': 4,
        'color': TeacherColors.attendanceColor,
      },
      {
        'title': 'Chat',
        'icon': Icons.chat_bubble_outline,
        'index': 5,
        'color': TeacherColors.primaryAccent,
      },
    ];

    return Positioned(
      top: 120,
      right: 20,
      child: AnimatedOpacity(
        opacity: _isMenuOpen ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: menuItems.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;

            return AnimatedContainer(
              duration: Duration(milliseconds: 200 + (index * 100)),
              curve: Curves.easeOutBack,
              transform: Matrix4.identity()..scale(_isMenuOpen ? 1.0 : 0.5),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() => _isMenuOpen = false);
                  _navigateToScreen(item['index']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: TeacherColors.glassDecoration(
                    borderRadius: 24,
                    borderColor: item['color'].withOpacity(0.4),
                  ).copyWith(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item['color'].withOpacity(0.12),
                        item['color'].withOpacity(0.06),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: item['color'].withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Pulsing glowing icon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: item['color'].withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: item['color'].withOpacity(0.2),
                          radius: 24,
                          child: Icon(
                            item['icon'],
                            color: Colors.white.withOpacity(0.9),
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _isMenuOpen
                            ? Text(
                          item['title'],
                          key: ValueKey(item['title']),
                          style: TeacherTextStyles.listItemTitle.copyWith(
                            shadows: [
                              Shadow(
                                color: item['color'].withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        )
                            : const SizedBox(width: 0),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMainFAB() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: TeacherColors.primaryAccent.withOpacity(_isMenuOpen ? 0.6 : 0.4),
            blurRadius: _isMenuOpen ? 20 : 10,
            spreadRadius: _isMenuOpen ? 2 : 1,
          ),
        ],
      ),
      child: FloatingActionButton(
        shape: const CircleBorder(),
        backgroundColor: TeacherColors.primaryAccent.withOpacity(0.9),
        elevation: 0,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return ScaleTransition(
              scale: animation,
              child: RotationTransition(
                turns: Tween(begin: 0.5, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: Icon(
            _isMenuOpen ? Icons.close : Icons.apps_rounded,
            key: ValueKey(_isMenuOpen ? 'close' : 'menu'),
            size: 28,
            color: Colors.white,
          ),
        ),
        onPressed: () {
          setState(() {
            _isMenuOpen = !_isMenuOpen;
          });
        },
      ),
    );
  }

  Widget _buildQuickStatsPanel() {
    // Safely parse attendance rate (unchanged functionality)
    double attendanceRate = 0.0;
    if (subjectStats['attendance_rate'] != null) {
      if (subjectStats['attendance_rate'] is String) {
        attendanceRate = double.tryParse(subjectStats['attendance_rate']) ?? 0.0;
      } else if (subjectStats['attendance_rate'] is num) {
        attendanceRate = subjectStats['attendance_rate'].toDouble();
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
      padding: const EdgeInsets.all(16),
      decoration: TeacherColors.glassDecoration(
        borderRadius: 16,
        borderColor: TeacherColors.primaryAccent.withOpacity(0.4),
      ).copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            TeacherColors.primaryAccent.withOpacity(0.3),
            TeacherColors.secondaryAccent.withOpacity(0.2),
          ],
        ),
        boxShadow: [
          BoxShadow(
              color: TeacherColors.primaryAccent.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 2,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                subjectStats['student_count']?.toString() ?? '0',
                'Students',
                Icons.people_outline,
                TeacherColors.studentColor,
              ),
              _buildStatItem(
                subjectStats['assignment_count']?.toString() ?? '0',
                'Assignments',
                Icons.assignment_outlined,
                TeacherColors.assignmentColor,
              ),
              _buildStatItem(
                '${attendanceRate.toStringAsFixed(0)}%',
                'Attendance',
                Icons.calendar_today_outlined,
                TeacherColors.attendanceColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Column(
        key: ValueKey('$value-$label'),
        children: [
          // Pulsing icon container
          AnimatedContainer(
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  color.withOpacity(0.4),
                  color.withOpacity(0.1),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow effect
                AnimatedContainer(
                  duration: const Duration(milliseconds: 1500),
                  curve: Curves.easeInOut,
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.1),
                  ),
                ),
                Icon(
                  icon,
                  color: Colors.white.withOpacity(0.9),
                  size: 22,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Value with subtle animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: Text(
              value,
              key: ValueKey(value),
              style: TeacherTextStyles.statValue.copyWith(
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Label with fade animation
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              label,
              key: ValueKey(label),
              style: TeacherTextStyles.statLabel.copyWith(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsPreview() {
    if (announcements.isEmpty) {
      return Padding(
            child: Text(
              '                                              No announcement for today                                          ',
              style: TeacherTextStyles.cardSubtitle,
            ),
        padding: EdgeInsets.all(16),
      );
    }

    return Column(
      children: announcements.take(2).map((announcement) {
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: TeacherColors.announcementColor.withOpacity(0.2),
                child: Icon(Icons.announcement, color: TeacherColors.announcementColor),
              ),
              title: Text(
                announcement['title'] ?? 'No title',
                style: TeacherTextStyles.cardTitle,
              ),
              subtitle: Text(
                announcement['content'] ?? 'No content',
                style: TeacherTextStyles.cardSubtitle,
              ),
              trailing: Text(
                _formatTime(announcement['created_at']),
                style: TeacherTextStyles.cardSubtitle,
              ),
            ),
            if (announcement != announcements.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAssignmentsPreview() {
    if (assignments.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No upcoming assignments',
          style: TeacherTextStyles.cardSubtitle,
        ),
      );
    }

    final studentCount = subjectStats['student_count'] is String
        ? int.tryParse(subjectStats['student_count']) ?? 1
        : (subjectStats['student_count'] ?? 1);

    return Column(
      children: assignments.take(2).map((assignment) {
        final submittedCount = assignment['submitted_count'] is String
            ? int.tryParse(assignment['submitted_count']) ?? 0
            : (assignment['submitted_count'] ?? 0);

        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: TeacherColors.assignmentColor.withOpacity(0.2),
                child: Icon(Icons.assignment, color: TeacherColors.assignmentColor),
              ),
              title: Text(
                assignment['title'] ?? 'No title',
                style: TeacherTextStyles.cardTitle,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Due: ${_formatDate(assignment['due_date'])}',
                    style: TeacherTextStyles.cardSubtitle,
                  ),
                  SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: submittedCount / studentCount,
                    backgroundColor: TeacherColors.assignmentColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.assignmentColor),
                  ),
                  Text(
                    '$submittedCount/$studentCount submitted',
                    style: TeacherTextStyles.cardSubtitle,
                  ),
                ],
              ),
            ),
            if (assignment != assignments.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildQueriesPreview() {
    if (queries.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No pending queries',
          style: TeacherTextStyles.cardSubtitle,
        ),
      );
    }

    return Column(
      children: queries.take(2).map((query) {
        return Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: query['status'] == 'answered'
                    ? TeacherColors.successAccent.withOpacity(0.2)
                    : TeacherColors.dangerAccent.withOpacity(0.2),
                child: Icon(
                  Icons.question_answer,
                  color: query['status'] == 'answered'
                      ? TeacherColors.successAccent
                      : TeacherColors.dangerAccent,
                ),
              ),
              title: Text(
                query['student_name'] ?? 'Student',
                style: TeacherTextStyles.cardTitle,
              ),
              subtitle: Text(
                (query['question']?.length ?? 0) > 30
                    ? '${query['question'].substring(0, 30)}...'
                    : query['question'] ?? 'No question',
                style: TeacherTextStyles.cardSubtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Chip(
                label: Text(
                  query['status'] == 'answered' ? 'Answered' : 'Pending',
                  style: TeacherTextStyles.cardSubtitle.copyWith(color: Colors.white),
                ),
                backgroundColor: query['status'] == 'answered'
                    ? TeacherColors.successAccent
                    : TeacherColors.dangerAccent,
              ),
            ),
            if (query != queries.last) Divider(height: 1),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAttendancePreview() {
    if (attendance.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(16),
      );
    }

    double attendanceRate = 0.0;
    if (subjectStats['attendance_rate'] != null) {
      if (subjectStats['attendance_rate'] is String) {
        attendanceRate = double.tryParse(subjectStats['attendance_rate']) ?? 0.0;
      } else if (subjectStats['attendance_rate'] is num) {
        attendanceRate = subjectStats['attendance_rate'].toDouble();
      }
    }

    return Padding(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: TeacherTextStyles.cardTitle,
              ),
              Text(
                '${attendanceRate.toStringAsFixed(0)}%',
                style: TeacherTextStyles.statValue.copyWith(
                  color: TeacherColors.attendanceColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          LinearProgressIndicator(
            value: attendanceRate / 100,
            backgroundColor: TeacherColors.attendanceColor.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.attendanceColor),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: attendance.take(5).map((day) {
              double dayRate = 0.0;
              if (day['attendance_rate'] is String) {
                dayRate = double.tryParse(day['attendance_rate']) ?? 0.0;
              } else if (day['attendance_rate'] is num) {
                dayRate = day['attendance_rate'].toDouble();
              }

              return _buildMiniAttendanceStat(
                _getDayName(day['day']),
                '${dayRate.toStringAsFixed(0)}%',
                dayRate >= 90 ? Icons.check : Icons.warning,
                dayRate >= 90 ? TeacherColors.successAccent : TeacherColors.warningAccent,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'Unknown time';
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'No date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getDayName(String? day) {
    if (day == null) return 'Day';
    return day.length >= 3 ? day.substring(0, 3) : day;
  }

  Widget _buildSectionPreview({
    required String title,
    required VoidCallback onViewAll,
    required Widget child,
    IconData? icon, // Added icon parameter
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with animated icon and glass effect
        Container(
          decoration: TeacherColors.glassDecoration(
            borderRadius: 8,
            borderColor: TeacherColors.cardBorder.withOpacity(0.3),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (icon != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          icon,
                          key: ValueKey(icon),
                          color: TeacherColors.primaryAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  Text(
                    title,
                    style: TeacherTextStyles.sectionHeader.copyWith(
                      shadows: [
                        Shadow(
                          color: TeacherColors.primaryAccent.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // View All button with hover effect
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: TeacherColors.accentGradient(
                      TeacherColors.primaryAccent,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: TeacherColors.primaryAccent.withOpacity(0.3),
                        blurRadius: 6,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextButton(
                    onPressed: onViewAll,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        'View All →', // Added arrow for futurism
                        key: const ValueKey('view-all'),
                        style: TeacherTextStyles.secondaryButton.copyWith(
                          color: TeacherColors.primaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Glass card with inner content
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutQuart,
          decoration: TeacherColors.glassDecoration(
            borderRadius: 16,
            borderColor: TeacherColors.primaryAccent.withOpacity(0.2),
          ).copyWith(
            boxShadow: [
              BoxShadow(
                color: TeacherColors.primaryAccent.withOpacity(0.1),
                blurRadius: 12,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TeacherColors.glassEffectLight.withOpacity(0.4),
                    TeacherColors.glassEffectDark.withOpacity(0.2),
                  ],
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: child,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  Widget _buildMiniAttendanceStat(
      String day,
      String percent,
      IconData icon,
      Color color,
      ) {
    return Column(
      children: [
        Text(day, style: TeacherTextStyles.cardSubtitle),
        SizedBox(height: 4),
        Icon(icon, color: color, size: 16),
        Text(percent, style: TeacherTextStyles.cardSubtitle),
      ],
    );
  }

  Widget _buildChatPreview() {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: TeacherColors.studentColor.withOpacity(0.2),
            child: Icon(Icons.person, color: TeacherColors.studentColor),
          ),
          title: Text(
            'Prof. Smith',
            style: TeacherTextStyles.cardTitle,
          ),
          subtitle: Text(
            'Don\'t forget about the assignment due tomorrow',
            style: TeacherTextStyles.cardSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '10m ago',
            style: TeacherTextStyles.cardSubtitle,
          ),
        ),
        Divider(height: 1),
        ListTile(
          leading: CircleAvatar(
            backgroundColor: TeacherColors.successAccent.withOpacity(0.2),
            child: Icon(Icons.person, color: TeacherColors.successAccent),
          ),
          title: Text(
            'You',
            style: TeacherTextStyles.cardTitle,
          ),
          subtitle: Text(
            'I submitted the assignment last night',
            style: TeacherTextStyles.cardSubtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            '5m ago',
            style: TeacherTextStyles.cardSubtitle,
          ),
        ),
      ],
    );
  }
}

class PlannerDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> planner;

  const PlannerDetailsScreen({
    Key? key,
    required this.planner,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final attachments = planner['attachments'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text('Planner Details'),
        backgroundColor: TeacherColors.primaryBackground,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              planner['title'] ?? 'No title',
              style: TeacherTextStyles.sectionHeader,
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: TeacherColors.secondaryText),
                SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(
                      DateTime.parse(planner['planned_date'])),
                  style: TeacherTextStyles.cardSubtitle,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Description',
              style: TeacherTextStyles.sectionHeader,
            ),
            SizedBox(height: 8),
            Text(
              planner['description'] ?? 'No description',
              style: TeacherTextStyles.cardSubtitle,
            ),
            SizedBox(height: 24),
            if (attachments.isNotEmpty) ...[
              Text(
                'Attachments',
                style: TeacherTextStyles.sectionHeader,
              ),
              SizedBox(height: 8),
              Column(
                children: attachments.map<Widget>((attachment) {
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        _getFileIcon(attachment['file_name']),
                        color: TeacherColors.primaryAccent,
                      ),
                      title: Text(
                        attachment['file_name'],
                        style: TeacherTextStyles.cardSubtitle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.download),
                        onPressed: () => _openAttachment(attachment, context),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName
        .split('.')
        .last
        .toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  void _openAttachment(Map<String, dynamic> attachment,
      BuildContext parentContext) async {
    final url = attachment['file_url'];
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(parentContext).showSnackBar(
        SnackBar(content: Text('Attachment URL is invalid')),
      );
      return;
    }

    showDialog(
      context: parentContext,
      builder: (dialogContext) =>
          AlertDialog(
            title: Text('Open Attachment'),
            content: Text(
                'Would you like to download or view ${attachment['file_name']}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(content: Text('Opening attachment...')),
                  );

                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    ScaffoldMessenger.of(parentContext).showSnackBar(
                      SnackBar(content: Text('Could not launch attachment')),
                    );
                  }
                },
                child: Text('Open'),
              ),
            ],
          ),
    );
  }
}