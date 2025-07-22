import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import 'dart:convert';
import 'SubjectDetails.dart';
import 'dart:math';

class SubjectsScreen extends StatefulWidget {
  final String teacherId;

  const SubjectsScreen({super.key, required this.teacherId});

  @override
  _SubjectsScreenState createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> subjects = [];
  bool isLoading = false;
  String errorMessage = '';
  late AnimationController _controller;
  late Animation<double> _animation;

  final String baseUrl = 'http://193.203.162.232:5050/Teacher/api';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _fetchSubjects();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/teacher/${widget.teacherId}/subjects'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          subjects = data.map((item) {
            return {
              'subject_id': item['subject_id'] ?? 'NA',
              'name': item['subject_name'] ?? 'NA',
              'code': item['subject_code'] ?? 'NA',
              'color': _getColorForSubject(item['subject_id'] ?? 0),
              'icon': _getIconForSubject(item['subject_name'] ?? ''),
              'students': item['student_count'] ?? 0,
              'classes': _parseClasses(item['classes'] ?? ''),
              'schedule': _parseSchedule(item['schedule'] ?? []),
              'year': item['year'] ?? 'NA',
              'room': item['room'] ?? 'NA',
            };
          }).toList();
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load subjects (${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Connection error: ${e.toString()}';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color _getColorForSubject(int subjectId) {
    final colors = [
      TeacherColors.studentColor,
      TeacherColors.classColor,
      TeacherColors.attendanceColor,
      TeacherColors.assignmentColor,
      TeacherColors.gradeColor,
      TeacherColors.primaryAccent,
      TeacherColors.secondaryAccent,
    ];
    return colors[subjectId % colors.length];
  }

  IconData _getIconForSubject(String subjectName) {
    final name = subjectName.toLowerCase();
    if (name.contains('math')) return Icons.calculate;
    if (name.contains('physics')) return Icons.science;
    if (name.contains('computer')) return Icons.computer;
    if (name.contains('chemistry')) return Icons.science_outlined;
    if (name.contains('biology')) return Icons.eco;
    if (name.contains('english')) return Icons.menu_book;
    if (name.contains('art')) return Icons.palette;
    return Icons.school;
  }

  List<String> _parseClasses(dynamic classesData) {
    if (classesData is String) return [classesData];
    if (classesData is List) return List<String>.from(classesData);
    return ['NA'];
  }

  String _parseSchedule(dynamic scheduleData) {
    if (scheduleData is String) return scheduleData;
    if (scheduleData is List && scheduleData.isNotEmpty) return scheduleData.join(', ');
    return 'Schedule not available';
  }

  void _navigateToSubjectDetail(Map<String, dynamic> subject) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDashboardScreen(
          subject: subject,
          teacherId: widget.teacherId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      body: Stack(
        children: [
          CustomPaint(
            painter: _ParticlePainter(animation: _animation),
            size: Size.infinite,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: TeacherColors.primaryAccent,
                      strokeWidth: 2,
                    ),
                  )
                      : errorMessage.isNotEmpty
                      ? _buildErrorState()
                      : subjects.isEmpty
                      ? _buildEmptyState()
                      : _buildContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: TeacherColors.primaryText),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'My Subjects',
              style: TeacherTextStyles.headerTitle.copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: TeacherColors.primaryText),
            onPressed: _fetchSubjects,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Icon(Icons.error_outline, size: 48, color: TeacherColors.dangerAccent),
      const SizedBox(height: 16),
      Text(
        errorMessage,
        style: TeacherTextStyles.listItemSubtitle.copyWith(color: TeacherColors.dangerAccent),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _fetchSubjects,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 4,
              ),
              child: Text(
                'Retry',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school_outlined, size: 64, color: TeacherColors.secondaryText.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            'No subjects assigned',
            style: TeacherTextStyles.cardSubtitle.copyWith(fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildSummaryCard(),
          const SizedBox(height: 24),
          _buildSubjectsGrid(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final totalSubjects = subjects.length;
    final totalStudents = subjects.fold<int>(0, (sum, subject) => sum + (subject['students'] as int));
    final totalClasses = subjects.fold<int>(0, (sum, subject) => sum + (subject['classes'] as List).length);

    return GlassCard(
      borderRadius: 20,
      borderColor: TeacherColors.primaryAccent.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Teaching Summary',
              style: TeacherTextStyles.sectionHeader.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryStat('Subjects', totalSubjects.toString(), Icons.school),
                _buildSummaryStat('Students', totalStudents.toString(), Icons.people),
                _buildSummaryStat('Classes', totalClasses.toString(), Icons.class_),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                TeacherColors.primaryAccent.withOpacity(0.7),
                TeacherColors.secondaryAccent.withOpacity(0.7),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(icon, color: Colors.white, size: 24),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TeacherTextStyles.statValue.copyWith(color: Colors.white),
        ),
        Text(
          label,
          style: TeacherTextStyles.statLabel.copyWith(color: Colors.white.withOpacity(0.9)),
        ),
      ],
    );
  }

  Widget _buildSubjectsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return _buildSubjectCard(subjects[index]);
      },
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    return GlassCard(
      borderRadius: 16,
      borderColor: subject['color'].withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToSubjectDetail(subject),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: subject['color'].withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(subject['icon'], color: subject['color']),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      subject['code'],
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: subject['color'],
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                subject['name'],
                style: TeacherTextStyles.cardTitle.copyWith(fontSize: 18),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: subject['color']),
                  const SizedBox(width: 8),
                  Text(
                    '${subject['students']} students',
                    style: TeacherTextStyles.cardSubtitle.copyWith(color: subject['color']),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: subject['color']),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subject['schedule'],
                      style: TeacherTextStyles.cardSubtitle.copyWith(color: subject['color']),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              LinearProgressIndicator(
                value: 0.7, // Replace with actual progress
                backgroundColor: subject['color'].withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation<Color>(subject['color']),
                borderRadius: BorderRadius.circular(10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget? child;
  final Color? borderColor;
  final double borderRadius;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    this.child,
    this.borderColor,
    this.borderRadius = 16,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: TeacherColors.glassDecoration(
        borderColor: borderColor,
        borderRadius: borderRadius,
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
  final Random random = Random(42);

  _ParticlePainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    const particleCount = 50;

    for (int i = 0; i < particleCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 1 + random.nextDouble() * 3;
      final hue = 180 + random.nextDouble() * 60;
      final opacity = 0.1 + random.nextDouble() * 0.2;

      canvas.drawCircle(
        Offset(x, y),
        radius * (0.8 + 0.4 * animation.value),
        paint..color = HSVColor.fromAHSV(opacity * animation.value, hue, 0.8, 1).toColor(),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}