import 'package:flutter/material.dart';
import '../models/query_model.dart';
import '../models/subject_model.dart';
import '../services/api_service.dart';
import '../utils/app_design_system.dart';
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
    return Scaffold(
      appBar: AppDesignSystem.appBar(context, 'My Queries'),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary.withOpacity(0.05), AppColors.background],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(child: Text(_errorMessage!))
            : RefreshIndicator(
          onRefresh: _loadData,
          child: FutureBuilder<List<Query>>(
            future: _queriesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final queries = snapshot.data!;
                if (queries.isEmpty) {
                  return const Center(
                    child: Text('No queries yet. Ask your first question!'),
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
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  Widget _buildQueryCard(BuildContext context, Query query) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSubjectColor(query.subject),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  query.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                query.question,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (query.answer != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(query.answer!),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.lightGrey,
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
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                query.timeAgo,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
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
      'Physics': AppColors.accentBlue,
      'Chemistry': AppColors.accentPink,
      'Biology': AppColors.success,
      'English': AppColors.primaryLight,
      'History': AppColors.accentAmber,
    };
    return colors[subject] ?? AppColors.primary;
  }

  Future<void> _showNewQueryDialog(BuildContext context) async {
    String? selectedSubjectId;
    final TextEditingController questionController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final subjects = await _subjectsFuture;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text('Ask a Question'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: selectedSubjectId,
                        decoration: InputDecoration(
                          labelText: 'Select Subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        items: subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject.id,
                            child: Text(subject.name),
                          );
                        }).toList(),
                        validator: (value) =>
                        value == null ? 'Please select a subject' : null,
                        onChanged: (value) {
                          setState(() {
                            selectedSubjectId = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: questionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Type your question here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? 'Please enter your question'
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      try {
                        final newQuery = await _apiService.submitQuery(
                          subjectId: selectedSubjectId!,
                          question: questionController.text,
                          studentRfid: widget.studentRfid
                        );
                        Navigator.pop(context);
                        setState(() {
                          _queriesFuture = _apiService.getQueries(widget.studentRfid);
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit query: $e'),
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Submit Question'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}