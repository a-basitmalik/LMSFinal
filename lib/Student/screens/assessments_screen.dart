import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/theme.dart';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Assessments',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: _buildBody(context, textTheme),
    );
  }

  Widget _buildBody(BuildContext context, TextTheme textTheme) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    if (_hasError) {
      return _buildErrorState(textTheme);
    }

    if (_assessmentTypes.isEmpty) {
      return _buildEmptyState(textTheme);
    }

    return ListView(
      padding: AppTheme.defaultPadding,
      children: _assessmentTypes.map((type) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.defaultSpacing),
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

  Widget _buildErrorState(TextTheme textTheme) {
    return Center(
      child: Padding(
        padding: AppTheme.defaultPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: AppTheme.defaultSpacing),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.defaultSpacing),
            ElevatedButton(
              onPressed: _fetchAssessmentTypes,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textPrimary,
                padding: AppTheme.buttonPadding,
              ),
              child: Text('Retry', style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(TextTheme textTheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppTheme.defaultSpacing),
          Text(
            'No assessment types available',
            style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppTheme.defaultSpacing),
          ElevatedButton(
            onPressed: _fetchAssessmentTypes,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              padding: AppTheme.buttonPadding,
            ),
            child: Text('Refresh', style: textTheme.labelLarge),
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
          ),
          padding: AppTheme.defaultPadding,
          child: Row(
            children: [
              Container(
                padding: AppTheme.defaultPadding,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textPrimary),
              ),
              const SizedBox(width: AppTheme.defaultSpacing),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.textPrimary.withOpacity(0.7),
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
      return AppColors.studentColor;
    } else if (type.contains('send up')) {
      return AppColors.primary;
    } else if (type.contains('half book')) {
      return AppColors.secondary;
    } else if (type.contains('test session')) {
      return AppColors.warning;
    } else if (type.contains('full book')) {
      return AppColors.facultyColor;
    } else if (type.contains('other')) {
      return AppColors.surface;
    } else if (type.contains('mocks')) {
      return AppColors.secondaryDark;
    } else if (type.contains('weekly')) {
      return AppColors.primaryDark;
    }
    return AppColors.info;
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