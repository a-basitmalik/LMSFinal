import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('My Queries', style: textTheme.titleLarge),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient(AppColors.primary),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Text(
            _errorMessage!,
            style: textTheme.bodyMedium,
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
                      style: textTheme.bodyMedium,
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewQueryDialog(context),
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add, color: theme.colorScheme.onPrimary),
      ),
    );
  }

  Widget _buildQueryCard(BuildContext context, Query query) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      color: AppColors.cardBackground,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Subject Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSubjectColor(query.subject),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  query.subject,
                  style: textTheme.labelMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Question
              Text(
                query.question,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              // Answer or Pending
              if (query.answer != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Teacher\'s Response',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        query.answer!,
                        style: textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppColors.warning,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Waiting for teacher\'s response',
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
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
                style: textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
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
      'Mathematics': AppColors.secondary,
      'Physics': AppColors.info,
      'Chemistry': AppColors.facultyColor,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      'History': AppColors.resultsColor,
    };
    return colors[subject] ?? AppColors.primary;
  }

  Future<void> _showNewQueryDialog(BuildContext context) async {
    String? selectedSubjectId;
    final TextEditingController questionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final subjects = await _subjectsFuture;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: AppColors.cardBackground,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ask a Question',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: selectedSubjectId,
                            decoration: InputDecoration(
                              labelText: 'Select Subject',
                              labelStyle: textTheme.labelMedium,
                            ),
                            items: subjects.map((subject) {
                              return DropdownMenuItem(
                                value: subject.id,
                                child: Text(
                                  subject.name,
                                  style: textTheme.bodyMedium,
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
                            style: textTheme.bodyMedium,
                            dropdownColor: AppColors.secondaryBackground,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: questionController,
                            maxLines: 4,
                            style: textTheme.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Type your question here...',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                color: AppColors.disabledText,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) =>
                            value == null || value.isEmpty
                                ? 'Please enter your question'
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: textTheme.labelLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
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
                                      style: textTheme.bodyMedium,
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                          child: Text(
                            'Submit Question',
                            style: textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
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