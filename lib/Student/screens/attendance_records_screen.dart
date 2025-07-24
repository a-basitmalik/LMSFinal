import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../widgets/attendance_progress_bar.dart';
import '../models/attendance_model.dart';
import 'package:intl/intl.dart';

class AttendanceRecordsScreen extends StatefulWidget {
  final AttendanceSummary summary;

  const AttendanceRecordsScreen({super.key, required this.summary});

  @override
  State<AttendanceRecordsScreen> createState() =>
      _AttendanceRecordsScreenState();
}

class _AttendanceRecordsScreenState extends State<AttendanceRecordsScreen> {
  int _selectedTab = 0; // 0 for general, 1 for subject-wise

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance Records',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.primary),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient(AppColors.primary),
        ),
        child: Column(
          children: [
            // Tab selector
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.defaultSpacing,
                  vertical: AppTheme.defaultSpacing),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      context,
                      label: 'General',
                      isSelected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0),
                    ),
                  ),
                  const SizedBox(width: AppTheme.defaultSpacing),
                  Expanded(
                    child: _buildTabButton(
                      context,
                      label: 'Subject-wise',
                      isSelected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1),
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget _buildTabButton(
      BuildContext context, {
        required String label,
        required bool isSelected,
        required VoidCallback onTap,
      }) {
    return Material(
      color: isSelected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
            border: Border.all(
              color: isSelected ? Colors.transparent : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: isSelected ? Colors.black : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralAttendanceView(BuildContext context) {
    return SingleChildScrollView(
      padding: AppTheme.defaultPadding,
      child: Column(
        children: [
          // Overall summary card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryLight, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
              ),
              padding: AppTheme.defaultPadding,
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: AppTheme.defaultPadding,
                        decoration: BoxDecoration(
                          color: AppColors.glassEffectLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.bar_chart,
                          color: AppColors.textPrimary,
                          size: AppTheme.defaultIconSize,
                        ),
                      ),
                      const SizedBox(width: AppTheme.defaultSpacing),
                      Expanded(
                        child: Text(
                          'Overall Attendance',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${widget.summary.overallPercentage}%',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.defaultSpacing),
                  AttendanceProgressBar(
                    percentage: widget.summary.overallPercentage,
                  ),
                  const SizedBox(height: AppTheme.defaultSpacing),
                  _buildStatRow(
                    present: widget.summary.totalPresent,
                    absent: widget.summary.totalAbsent,
                    total: widget.summary.totalClasses,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppTheme.defaultSpacing * 1.5),

          // Monthly breakdown
          Text(
            'Monthly Breakdown',
            style: Theme.of(context).textTheme.sectionHeader,
          ),
          const SizedBox(height: AppTheme.defaultSpacing),
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
      padding: AppTheme.defaultPadding,
      itemCount: widget.summary.subjects.length,
      itemBuilder: (context, index) {
        final subject = widget.summary.subjects[index];
        return _buildSubjectCard(context, subject);
      },
    );
  }

  Widget _buildStatRow({
    required int present,
    required int absent,
    required int total,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem(
          value: present,
          label: 'Present',
          color: AppColors.success,
        ),
        _buildStatItem(
            value: absent, label: 'Absent', color: AppColors.error),
        _buildStatItem(
            value: total, label: 'Total', color: AppColors.primary),
      ],
    );
  }

  Widget _buildStatItem({
    required int value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textPrimary.withOpacity(0.9),
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
    final total = present + absent;
    final percentage = total == 0 ? 0 : (present / total * 100).round();

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius)),
      elevation: 0,
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  month,
                  style: Theme.of(context).textTheme.cardTitle,
                ),
                Text(
                  '$percentage%',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: _getPercentageColor(percentage),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            AttendanceProgressBar(percentage: percentage),
            const SizedBox(height: AppTheme.defaultSpacing),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Present: $present',
                  style: Theme.of(context).textTheme.accentText(AppColors.success),
                ),
                Text(
                  'Absent: $absent',
                  style: Theme.of(context).textTheme.accentText(AppColors.error),
                ),
                Text(
                  'Total: $total',
                  style: Theme.of(context).textTheme.accentText(AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectCard(BuildContext context, SubjectAttendance subject) {
    final color = _getSubjectColor(subject.name);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius)),
      elevation: 0,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(
            horizontal: AppTheme.defaultSpacing),
        childrenPadding: const EdgeInsets.only(
            left: AppTheme.defaultSpacing,
            right: AppTheme.defaultSpacing,
            bottom: AppTheme.defaultSpacing),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(_getSubjectIcon(subject.name),
              color: color, size: AppTheme.defaultIconSize),
        ),
        title: Text(
          subject.name,
          style: Theme.of(context).textTheme.cardTitle,
        ),
        trailing: Text(
          '${subject.percentage}%',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        children: [
          // Attendance progress bar
          Padding(
            padding: const EdgeInsets.only(
                top: AppTheme.defaultSpacing / 2,
                bottom: AppTheme.defaultSpacing),
            child: AttendanceProgressBar(percentage: subject.percentage),
          ),

          // Stats row
          _buildStatRow(
            present: subject.present,
            absent: subject.absent,
            total: subject.totalClasses,
          ),

          const SizedBox(height: AppTheme.defaultSpacing * 1.5),

          // Recent absences section
          if (subject.recentAbsences.isNotEmpty) ...[
            Divider(
                color: AppColors.cardBorder,
                height: 1,
                thickness: 1),
            const SizedBox(height: AppTheme.defaultSpacing),

            // Section header
            Row(
              children: [
                Icon(Icons.calendar_month,
                    color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recent Absences',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.defaultSpacing),

            // Absences list
            Column(
              children: subject.recentAbsences
                  .map(
                    (date) => Padding(
                  padding: const EdgeInsets.only(
                      bottom: AppTheme.defaultSpacing),
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
    return Container(
      padding: AppTheme.defaultPadding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius / 2),
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
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.defaultSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getDayName(date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${_getMonthName(date)} ${date.year}',
                style: Theme.of(context).textTheme.labelSmall,
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
    switch (date.weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  Color _getPercentageColor(int percentage) {
    if (percentage >= 85) return AppColors.success;
    if (percentage >= 70) return AppColors.warning;
    return AppColors.error;
  }

  Color _getSubjectColor(String subjectName) {
    final colors = {
      'Mathematics': AppColors.secondary,
      'Physics': AppColors.info,
      'Chemistry': AppColors.primaryLight,
      'English': AppColors.primary,
      'Computer Science': AppColors.warning,
    };
    return colors[subjectName] ?? AppColors.primaryDark;
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