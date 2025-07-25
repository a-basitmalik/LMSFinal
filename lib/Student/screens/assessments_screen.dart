import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import 'SingleResult.dart';

class AssessmentsScreen extends StatefulWidget {
  final String rfid;

  const AssessmentsScreen({
    super.key,
    required this.rfid,
  });

  @override
  State<AssessmentsScreen> createState() => _AssessmentsScreenState();
}

class _AssessmentsScreenState extends State<AssessmentsScreen> {
  List<String> _assessmentTypes = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchAssessmentTypes();
  }

  Future<void> _fetchAssessmentTypes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/result/get_assessment_types'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['assessment_types'] != null && data['assessment_types'] is List) {
          setState(() {
            _assessmentTypes = List<String>.from(data['assessment_types'].where((type) => type != null));
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid data format from API: Missing assessment_types');
        }
      } else {
        throw Exception('Failed to load assessment types: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Error loading assessments: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}';
      });
    }
  }

  void _navigateToAssessmentDetails(String assessmentType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleResultScreen(
          studentId: widget.rfid,
          assessmentType: assessmentType,
        ),
      ),
    );
  }

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
          'ASSESSMENTS',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: _buildBody(context, colors, textStyles),
    );
  }

  Widget _buildBody(BuildContext context, TeacherColors colors, TeacherTextStyles textStyles) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(textStyles);
    }

    if (_assessmentTypes.isEmpty) {
      return _buildEmptyState(textStyles);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: _assessmentTypes.map((type) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildAssessmentCard(
            title: type,
            icon: _getAssessmentIcon(type),
            color: _getAssessmentColor(type),
            context: context,
            onTap: () => _navigateToAssessmentDetails(type),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorState(TeacherTextStyles textStyles) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: TeacherColors.dangerAccent,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: TeacherTextStyles.cardSubtitle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchAssessmentTypes,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent.withOpacity(0.1),
                foregroundColor: TeacherColors.primaryAccent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: TeacherColors.primaryAccent.withOpacity(0.3),
                  ),
                ),
              ),
              child: Text(
                'Retry',
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TeacherTextStyles textStyles) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 48,
            color: TeacherColors.secondaryText,
          ),
          const SizedBox(height: 16),
          Text(
            'No assessment types available',
            style: TeacherTextStyles.cardSubtitle.copyWith(
              color: TeacherColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchAssessmentTypes,
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherColors.primaryAccent.withOpacity(0.1),
              foregroundColor: TeacherColors.primaryAccent,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: TeacherColors.primaryAccent.withOpacity(0.3),
                ),
              ),
            ),
            child: Text(
              'Refresh',
              style: TeacherTextStyles.cardSubtitle.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssessmentCard({
    required String title,
    required IconData icon,
    required Color color,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    final textStyles = context.teacherTextStyles;

    return Container(
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TeacherColors.primaryBackground.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: TeacherColors.primaryText,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TeacherTextStyles.cardTitle,
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: TeacherColors.primaryText.withOpacity(0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAssessmentColor(String assessmentType) {
    final type = assessmentType.toLowerCase();
    if (type.contains('monthly')) {
      return TeacherColors.primaryAccent;
    } else if (type.contains('send up')) {
      return TeacherColors.secondaryAccent;
    } else if (type.contains('half book')) {
      return TeacherColors.infoAccent;
    } else if (type.contains('test session')) {
      return TeacherColors.warningAccent;
    } else if (type.contains('full book')) {
      return TeacherColors.successAccent;
    } else if (type.contains('other')) {
      return TeacherColors.cardBackground;
    } else if (type.contains('mocks')) {
      return TeacherColors.dangerAccent;
    } else if (type.contains('weekly')) {
      return TeacherColors.primaryAccent.withOpacity(0.8);
    }
    return TeacherColors.primaryAccent;
  }

  IconData _getAssessmentIcon(String assessmentType) {
    final type = assessmentType.toLowerCase();
    if (type.contains('monthly')) {
      return Icons.assignment;
    } else if (type.contains('send up')) {
      return Icons.school;
    } else if (type.contains('half book')) {
      return Icons.book;
    } else if (type.contains('test session')) {
      return Icons.quiz;
    } else if (type.contains('full book')) {
      return Icons.library_books;
    } else if (type.contains('other')) {
      return Icons.book_sharp;
    } else if (type.contains('mocks')) {
      return Icons.school_sharp;
    } else if (type.contains('weekly')) {
      return Icons.bookmark_add;
    }
    return Icons.assessment;
  }
}