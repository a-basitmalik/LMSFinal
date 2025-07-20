import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'dart:convert';
import 'AcademicCalendar.dart';
import 'singleResult.dart';


class AssessmentTypeScreen extends StatefulWidget {
  final String studentId;

  const AssessmentTypeScreen({Key? key, required this.studentId}) : super(key: key);

  @override
  _AssessmentTypeScreenState createState() => _AssessmentTypeScreenState();
}

class _AssessmentTypeScreenState extends State<AssessmentTypeScreen> {
  List<String> _assessmentTypes = [];
  bool _isLoading = true;
  final Set<String> _uniqueTypes = {};

  @override
  void initState() {
    super.initState();
    _fetchAssessmentTypes();
  }

  Future<void> _fetchAssessmentTypes() async {
    setState(() => _isLoading = true);
    const url = 'http://193.203.162.232:5050/result/get_assessment_types';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final types = (data['assessment_types'] as List)
            .map((type) => type.toString())
            .where((type) => type.isNotEmpty)
            .toList();

        setState(() {
          _uniqueTypes.addAll(types);
          _assessmentTypes = _uniqueTypes.toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load assessment types');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.dangerAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _navigateToSingleResult(String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SingleResultScreen(
          studentId: widget.studentId,
          assessmentType: type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'ASSESSMENT TYPES',
                style: AdminTextStyles.sectionHeader.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      blurRadius: 10,
                      color: AdminColors.primaryAccent,
                    ),
                  ],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AdminColors.secondaryAccent,
                      AdminColors.infoAccent,
                      AdminColors.curriculumColor,
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: Opacity(
                    opacity: 0.2,
                    child: Icon(
                      Icons.assessment,
                      size: 120,
                      color: AdminColors.primaryText,
                    ),
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
              ),
            ),
          )
              : _assessmentTypes.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 60, color: AdminColors.disabledText),
                  const SizedBox(height: 16),
                  Text(
                    'No assessment types found',
                    style: AdminTextStyles.cardSubtitle,
                  ),
                  TextButton(
                    onPressed: _fetchAssessmentTypes,
                    child: Text(
                      'Retry',
                      style: AdminTextStyles.accentText(AdminColors.primaryAccent),
                    ),
                  ),
                ],
              ),
            ),
          )
              : SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                final type = _assessmentTypes[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: GlassCard(
                    borderRadius: 12,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _navigateToSingleResult(type),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(Icons.assignment, color: AdminColors.primaryAccent),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                type,
                                style: AdminTextStyles.cardTitle.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AdminColors.disabledText),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: _assessmentTypes.length,
            ),
          ),
        ],
      ),
    );
  }
}