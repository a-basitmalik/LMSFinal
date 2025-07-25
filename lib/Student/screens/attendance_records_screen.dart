import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../widgets/attendance_progress_bar.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  final AttendanceSummary summary;

  const AttendanceRecordsScreen({super.key, required this.summary});

  @override
  State<AttendanceRecordsScreen> createState() => _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  int _selectedTab = 0; // 0 for general, 1 for subject-wise

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'ATTENDANCE RECORDS',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: Column(
        children: [
          // Tab selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: TeacherColors.glassDecoration(),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      context,
                      label: 'GENERAL',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTabButton(
                      context,
                      label: 'SUBJECT-WISE',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content based on selected tab
          Expanded(
            child: _selectedTab == 0
                ? _buildGeneralAttendanceView(context)
                : _buildSubjectWiseView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(
      BuildContext context, {
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    final colors = context.teacherColors;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? LinearGradient(
            colors: [
              TeacherColors.primaryAccent.withOpacity(0.8),
              TeacherColors.primaryAccent.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          border: Border.all(
            color: isSelected ? Colors.transparent : TeacherColors.cardBorder,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TeacherTextStyles.cardSubtitle.copyWith(
              color: isSelected ? TeacherColors.primaryText : TeacherColors.secondaryText,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralAttendanceView(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Overall summary card
          Container(
            decoration: TeacherColors.glassDecoration(
              borderColor: TeacherColors.primaryAccent.withOpacity(0.3),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              TeacherColors.primaryAccent.withOpacity(0.3),
                              TeacherColors.primaryAccent.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          color: TeacherColors.primaryAccent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Overall Attendance',
                          style: TeacherTextStyles.cardTitle,
                        ),
                      ),
                      Text(
                        '${widget.summary.overallPercentage}%',
                        style: TeacherTextStyles.statValue.copyWith(
                          color: TeacherColors.primaryAccent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AttendanceProgressBar(
                    percentage: widget.summary.overallPercentage,
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    present: widget.summary.totalPresent,
                    absent: widget.summary.totalAbsent,
                    total: widget.summary.totalClasses,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Monthly breakdown
          Text(
            'MONTHLY BREAKDOWN',
            style: TeacherTextStyles.sectionHeader,
          ),
          const SizedBox(height: 16),
          ...widget.summary.monthlyData.map(
                (monthData) => _buildMonthCard(
              context,
              month: monthData.month,
              present: monthData.present,
              absent: monthData.absent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectWiseView(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: widget.summary.subjects.length,
      itemBuilder: (context, index) {
        final subject = widget.summary.subjects[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildSubjectCard(context, subject),
        );
      },
    );
  }

  Widget _buildStatRow({
    required int present,
    required int absent,
    required int total,
  }) {
    final colors = context.teacherColors;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          value: present,
          label: 'Present',
          color: TeacherColors.successAccent,
        ),
        _buildStatItem(
          value: absent,
          label: 'Absent',
          color: TeacherColors.dangerAccent,
        ),
        _buildStatItem(
          value: total,
          label: 'Total',
          color: TeacherColors.primaryAccent,
        ),
      ],
    );
  }

  Widget _buildStatItem({
    required int value,
    required String label,
    required Color color,
  }) {
    final textStyles = context.teacherTextStyles;

    return Column(
      children: [
        Text(
          value.toString(),
          style: TeacherTextStyles.cardTitle.copyWith(
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: color.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthCard(
      BuildContext context, {
        required String month,
        required int present,
        required int absent,
      }) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final total = present + absent;
    final percentage = total == 0 ? 0 : (present / total * 100).round();
    final percentageColor = _getPercentageColor(percentage);

    return Container(
      decoration: TeacherColors.glassDecoration(),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  month.toUpperCase(),
                  style: TeacherTextStyles.cardTitle,
                ),
                Text(
                  '$percentage%',
                  style: TeacherTextStyles.statValue.copyWith(
                    color: percentageColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AttendanceProgressBar(percentage: percentage),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Present: $present',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.successAccent,
                  ),
                ),
                Text(
                  'Absent: $absent',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.dangerAccent,
                  ),
                ),
                Text(
                  'Total: $total',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.primaryAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectAttendance subject) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final color = _getSubjectColor(subject.name);

    return Container(
      decoration: TeacherColors.glassDecoration(),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.3),
                color.withOpacity(0.1),
              ],
            ),
          ),
          child: Icon(
            _getSubjectIcon(subject.name),
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          subject.name,
          style: TeacherTextStyles.cardTitle,
        ),
        trailing: Text(
          '${subject.percentage}%',
          style: TeacherTextStyles.statValue.copyWith(
            color: color,
          ),
        ),
        children: [
          // Attendance progress bar
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: AttendanceProgressBar(percentage: subject.percentage),
          ),

          // Stats row
          _buildStatRow(
            present: subject.present,
            absent: subject.absent,
            total: subject.totalClasses,
          ),

          const SizedBox(height: 16),

          // Recent absences section
          if (subject.recentAbsences.isNotEmpty) ...[
            Divider(
              color: TeacherColors.cardBorder.withOpacity(0.3),
              height: 1,
              thickness: 1,
            ),
            const SizedBox(height: 16),

            // Section header
            Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: TeacherColors.dangerAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'RECENT ABSENCES',
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.dangerAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Absences list
            Column(
              children: subject.recentAbsences
                  .map(
                    (date) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildAbsenceItem(date, color),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAbsenceItem(DateTime date, Color color) {
    final textStyles = context.teacherTextStyles;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              date.day.toString(),
              style: TeacherTextStyles.cardTitle.copyWith(
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDayName(date),
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getMonthName(date)} ${date.year}',
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getMonthName(DateTime date) {
    return DateFormat('MMMM').format(date);
  }

  String _getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  Color _getPercentageColor(int percentage) {
    final colors = context.teacherColors;
    if (percentage >= 85) return TeacherColors.successAccent;
    if (percentage >= 70) return TeacherColors.warningAccent;
    return TeacherColors.dangerAccent;
  }

  Color _getSubjectColor(String subjectName) {
    final colors = {
      'Mathematics': TeacherColors.primaryAccent,
      'Physics': TeacherColors.secondaryAccent,
      'Chemistry': TeacherColors.infoAccent,
      'English': TeacherColors.warningAccent,
      'Computer Science': TeacherColors.successAccent,
    };
    return colors[subjectName] ?? TeacherColors.primaryAccent;
  }

  IconData _getSubjectIcon(String subjectName) {
    final icons = {
      'Mathematics': Icons.calculate,
      'Physics': Icons.science,
      'Chemistry': Icons.emoji_objects,
      'English': Icons.menu_book,
      'Computer Science': Icons.computer,
    };
    return icons[subjectName] ?? Icons.subject;
  }
}