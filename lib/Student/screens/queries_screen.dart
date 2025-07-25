import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../models/query_model.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';
import '../utils/theme.dart';

class QueriesScreen extends StatefulWidget {
  final String studentRfid;

  const QueriesScreen({
    super.key,
    required this.studentRfid,
  });

  @override
  State<QueriesScreen> createState() => _QueriesScreenState();
}

class _QueriesScreenState extends State<QueriesScreen> {
  late ApiService _apiService;
  late Future<List<Query>> _queriesFuture;
  late Future<List<Subject>> _subjectsFuture;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _subjectsFuture = _apiService.getSubjectsByStudentRfid(widget.studentRfid);
      _queriesFuture = _apiService.getQueries(widget.studentRfid);
      await Future.wait([_subjectsFuture, _queriesFuture]);
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load data. Please try again.';
        _isLoading = false;
      });
    }
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
          'MY QUERIES',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TeacherTextStyles.cardSubtitle,
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadData,
        child: FutureBuilder<List<Query>>(
          future: _queriesFuture,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final queries = snapshot.data!;
              if (queries.isEmpty) {
                return Center(
                  child: Text(
                    'No queries yet. Ask your first question!',
                    style: TeacherTextStyles.cardSubtitle,
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: queries.length,
                itemBuilder: (context, index) {
                  final query = queries[index];
                  return _buildQueryCard(context, query);
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewQueryDialog(context),
        backgroundColor: TeacherColors.primaryAccent,
        child: Icon(
          Icons.add,
          color: TeacherColors.primaryText,
        ),
      ),
    );
  }

  Widget _buildQueryCard(BuildContext context, Query query) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final subjectColor = _getSubjectColor(query.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: subjectColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  query.subject,
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: subjectColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Question
              Text(
                query.question,
                style: TeacherTextStyles.cardTitle,
              ),
              const SizedBox(height: 12),

              // Answer or Pending
              if (query.answer != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeacherColors.successAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TeacherColors.successAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: TeacherColors.successAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Teacher\'s Response',
                            style: TeacherTextStyles.cardSubtitle.copyWith(
                              color: TeacherColors.successAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        query.answer!,
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeacherColors.warningAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: TeacherColors.warningAccent.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: TeacherColors.warningAccent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for teacher\'s response',
                        style: TeacherTextStyles.cardSubtitle.copyWith(
                          color: TeacherColors.warningAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),

              // Time ago
              Text(
                query.timeAgo,
                style: TeacherTextStyles.cardSubtitle.copyWith(
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject) {
    final colors = {
      'Mathematics': TeacherColors.primaryAccent,
      'Physics': TeacherColors.secondaryAccent,
      'Chemistry': TeacherColors.infoAccent,
      'Biology': TeacherColors.successAccent,
      'English': TeacherColors.warningAccent,
      'History': TeacherColors.dangerAccent,
    };
    return colors[subject] ?? TeacherColors.primaryAccent;
  }

  Future<void> _showNewQueryDialog(BuildContext context) async {
    String? selectedSubjectId;
    final TextEditingController questionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final subjects = await _subjectsFuture;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(
                  color: TeacherColors.cardBorder,
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    TeacherColors.glassEffectLight,
                    TeacherColors.glassEffectDark,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),

              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'ASK A QUESTION',
                      style: TeacherTextStyles.sectionHeader,
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedSubjectId,
                            decoration: InputDecoration(
                              labelText: 'Select Subject',
                              labelStyle: TeacherTextStyles.cardSubtitle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                            ),
                            items: subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject.id,
                                child: Text(
                                  subject.name,
                                  style: TeacherTextStyles.cardTitle,
                                ),
                              );
                            }).toList(),
                            validator: (value) =>
                            value == null ? 'Please select a subject' : null,
                            onChanged: (value) {
                              setState(() {
                                selectedSubjectId = value;
                              });
                            },
                            style: TeacherTextStyles.cardTitle,
                            dropdownColor: TeacherColors.cardBackground,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: questionController,
                            maxLines: 4,
                            style: TeacherTextStyles.cardTitle,
                            decoration: InputDecoration(
                              hintText: 'Type your question here...',
                              hintStyle: TeacherTextStyles.cardSubtitle,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: TeacherColors.cardBorder,
                                ),
                              ),
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty ? 'Please enter your question' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: TeacherColors.cardBorder,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TeacherTextStyles.cardSubtitle,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                try {
                                  await _apiService.submitQuery(
                                    subjectId: selectedSubjectId!,
                                    question: questionController.text,
                                    studentRfid: widget.studentRfid,
                                  );
                                  Navigator.pop(context);
                                  _loadData();
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to submit query: $e',
                                        style: TeacherTextStyles.cardSubtitle,
                                      ),
                                      backgroundColor: TeacherColors.dangerAccent,
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: TeacherColors.primaryAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Submit Question',
                              style: TeacherTextStyles.primaryButton,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}