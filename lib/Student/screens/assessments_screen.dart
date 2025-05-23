import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_design_system.dart';
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
  }  void _navigateToAssessmentDetails(String assessmentType) {
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
    return Scaffold(
      appBar: AppDesignSystem.appBar(context, 'Assessments'),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
        ),
      )
          : _hasError
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Unknown error occurred',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchAssessmentTypes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade800,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Retry', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      )
          : _assessmentTypes.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No assessment types available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAssessmentTypes,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Refresh', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      )
          : ListView(
        padding: AppDesignSystem.defaultPadding,
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAssessmentColor(String assessmentType) {
    final type = assessmentType.toLowerCase();
    if (type.contains('monthly')) {
      return AppColors.accentBlue;
    } else if (type.contains('send up')) {
      return AppColors.primary;
    } else if (type.contains('half book')) {
      return AppColors.secondary;
    } else if (type.contains('test session')) {
      return AppColors.accentAmber;
    } else if (type.contains('full book')) {
      return AppColors.accentPink;
    }
    else if (type.contains('other')) {
      return AppColors.darkSurface;
    }
    else if (type.contains('mocks')) {
      return AppColors.darkSecondary;
    }
    else if (type.contains('weekly')) {
      return AppColors.darkPrimary;
    }
    return Colors.blueGrey;
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
    }
    else if (type.contains('other')) {
      return Icons.book_sharp;
    }
    else if (type.contains('mocks')) {
      return Icons.school_sharp;
    }
    else if (type.contains('weekly')) {
      return Icons.bookmark_add;
    }
    return Icons.assessment;

  }
}