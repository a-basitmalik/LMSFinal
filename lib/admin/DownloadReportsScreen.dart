// download_reports_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_extensions.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class DownloadReportsScreen extends StatefulWidget {
  final int campusID;
  final String campusName;
  final int initialTab;

  const DownloadReportsScreen({
    Key? key,
    required this.campusID,
    required this.campusName,
    this.initialTab = 0,
  }) : super(key: key);

  @override
  _DownloadReportsScreenState createState() => _DownloadReportsScreenState();
}

class _DownloadReportsScreenState extends State<DownloadReportsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _isLoadingSubjects = false;
  List<Subject> _subjects = [];
  Subject? _selectedSubject;
  final TextEditingController _yearController = TextEditingController();
  String? _selectedAssessmentType;
  final List<String> _assessmentTypes = [
    'Monthly', 'Send Up', 'Mocks', 'Other', 'Test Session',
    'Weekly', 'Half Book', 'Full Book',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTab,
    );

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    setState(() => _isLoadingSubjects = true);
    try {
      final uri = Uri.http(
        '193.203.162.232:5050',
        '/ReportDownload/subjects',
        {'campusid': widget.campusID.toString()},
      );
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final raw = jsonDecode(resp.body) as List<dynamic>;
        final subjects = raw.map((e) => Subject.fromJson(e as Map<String, dynamic>)).toList();
        setState(() => _subjects = subjects);
      } else {
        _showToast('Error ${resp.statusCode}: ${resp.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSubjects = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      body: Stack(
        children: [
          // Animated Background
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      AdminColors.reportsColor.withOpacity(_fadeAnimation.value * 0.3),
                      AdminColors.secondaryBackground.withOpacity(_fadeAnimation.value * 0.3),
                      AdminColors.primaryBackground,
                    ],
                    stops: [0.1, 0.5, 1.0],
                  ),
                ),
              );
            },
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      return Text(
                        'GENERATE REPORTS',
                        style: AdminTextStyles.sectionTitle(AdminColors.primaryAccent).copyWith(
                          shadows: [
                            Shadow(
                              blurRadius: 10 * _fadeAnimation.value,
                              color: AdminColors.primaryAccent.withOpacity(_fadeAnimation.value),
                            ),
                          ],
                          color: AdminColors.primaryText.withOpacity(_fadeAnimation.value),
                        ),
                      );
                    },
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AdminColors.reportsColor.withOpacity(0.7),
                          AdminColors.secondaryBackground.withOpacity(0.7),
                          AdminColors.primaryBackground.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: GlassCard(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            AdminColors.primaryAccent.withOpacity(0.8),
                            AdminColors.secondaryAccent.withOpacity(0.8),
                          ],
                        ),
                      ),
                      labelColor: AdminColors.primaryBackground,
                      unselectedLabelColor: AdminColors.primaryText.withOpacity(0.7),
                      tabs: const [
                        Tab(text: 'SUBJECT'),
                        Tab(text: 'ASSESSMENT'),
                        Tab(text: 'MONTHLY QUIZZES'),
                        Tab(text: 'ALL SUBJECTS'),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child: _buildCurrentTab(),
                  ),
                ),
              ),
            ],
          ),

          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AdminColors.primaryAccent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_tabController.index) {
      case 0:
        return _buildSubjectReportTab();
      case 1:
        return _buildAssessmentReportTab();
      case 2:
        return _buildMonthlyWithQuizzesTab();
      case 3:
        return _buildAllSubjectsReportTab();
      default:
        return Container();
    }
  }

  Widget _buildSubjectReportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.assignment, color: AdminColors.primaryAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SUBJECT REPORT',
                        style: AdminTextStyles.sectionHeader.copyWith(
                          color: AdminColors.primaryAccent,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All assessment types with quiz data',
                        style: AdminTextStyles.cardSubtitle.copyWith(
                          color: AdminColors.primaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildSubjectDropdown(),
        SizedBox(height: 16),
        _buildYearField(),
        SizedBox(height: 24),
        _buildGenerateButton(
          'GENERATE REPORT',
          _generateSubjectReport,
        ),
      ],
    );
  }

  Widget _buildAssessmentReportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.assessment, color: AdminColors.primaryAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSESSMENT REPORT',
                        style: AdminTextStyles.sectionHeader.copyWith(
                          color: AdminColors.primaryAccent,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selected assessment type for subject',
                        style: AdminTextStyles.cardSubtitle.copyWith(
                          color: AdminColors.primaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildSubjectDropdown(),
        SizedBox(height: 16),
        _buildYearField(),
        SizedBox(height: 16),
        _buildAssessmentTypeDropdown(),
        SizedBox(height: 24),
        _buildGenerateButton(
          'GENERATE REPORT',
          _generateAssessmentReport,
        ),
      ],
    );
  }

  Widget _buildMonthlyWithQuizzesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.quiz, color: AdminColors.primaryAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MONTHLY QUIZZES',
                        style: AdminTextStyles.sectionHeader.copyWith(
                          color: AdminColors.primaryAccent,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Monthly assessments with quiz data',
                        style: AdminTextStyles.cardSubtitle.copyWith(
                          color: AdminColors.primaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildYearField(),
        SizedBox(height: 24),
        _buildGenerateButton(
          'GENERATE REPORT',
          _generateMonthlyWithQuizzesReport,
        ),
      ],
    );
  }

  Widget _buildAllSubjectsReportTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.library_books, color: AdminColors.primaryAccent, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ALL SUBJECTS',
                        style: AdminTextStyles.sectionHeader.copyWith(
                          color: AdminColors.primaryAccent,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Selected assessment type for all subjects',
                        style: AdminTextStyles.cardSubtitle.copyWith(
                          color: AdminColors.primaryText.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        _buildYearField(),
        SizedBox(height: 16),
        _buildAssessmentTypeDropdown(),
        SizedBox(height: 24),
        _buildGenerateButton(
          'GENERATE REPORT',
          _generateAllSubjectsReport,
        ),
      ],
    );
  }

  Widget _buildSubjectDropdown() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SUBJECT',
              style: AdminTextStyles.cardSubtitle.copyWith(
                color: AdminColors.primaryText.withOpacity(0.7),
              ),
            ),
            DropdownButtonFormField<Subject>(
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              items: _subjects.map((subject) {
                return DropdownMenuItem<Subject>(
                  value: subject,
                  child: Text(
                    '${subject.name} (ID: ${subject.id})',
                    style: AdminTextStyles.cardTitle.copyWith(color: AdminColors.primaryText),
                  ),
                );
              }).toList(),
              onChanged: (subject) {
                setState(() {
                  _selectedSubject = subject;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a subject';
                }
                return null;
              },
              hint: _isLoadingSubjects
                  ? Text('Loading subjects...', style: AdminTextStyles.cardSubtitle)
                  : Text('Select subject', style: AdminTextStyles.cardSubtitle),
              dropdownColor: AdminColors.secondaryBackground,
              icon: Icon(Icons.arrow_drop_down, color: AdminColors.primaryText),
              value: _selectedSubject,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearField() {
    return GlassInputField(
      controller: _yearController,
      label: 'YEAR',
      icon: Icons.calendar_today,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter year';
        }
        return null;
      },
    );
  }

  Widget _buildAssessmentTypeDropdown() {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ASSESSMENT TYPE',
              style: AdminTextStyles.cardSubtitle.copyWith(
                color: AdminColors.primaryText.withOpacity(0.7),
              ),
            ),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                border: InputBorder.none,
                isDense: true,
              ),
              items: _assessmentTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style: AdminTextStyles.cardTitle.copyWith(color: AdminColors.primaryText),
                  ),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  _selectedAssessmentType = type;
                });
              },
              hint: Text(
                'Select assessment type',
                style: AdminTextStyles.cardSubtitle,
              ),
              dropdownColor: AdminColors.secondaryBackground,
              icon: Icon(Icons.arrow_drop_down, color: AdminColors.primaryText),
              value: _selectedAssessmentType,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(String text, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AdminColors.primaryText.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primaryAccent.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.cardBackground,
          foregroundColor: AdminColors.primaryText,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator(color: AdminColors.primaryText)
            : Text(
          text,
          style: AdminTextStyles.primaryButton.copyWith(
            fontSize: 16,
            letterSpacing: 1.1,
          ),
        ),
      ),
    );
  }

  Future<void> _generateSubjectReport() async {
    if (_selectedSubject == null || _yearController.text.isEmpty) {
      _showToast('Please select a subject and year');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final resp = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/subject-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'subjectid': _selectedSubject!.id,
          'year': _yearController.text.trim(),
        }),
      );

      if (resp.statusCode == 200) {
        final fileName = 'subject_${_selectedSubject!.id}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([resp.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final dir =
              await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final path = '${dir.path}/$fileName';
          File(path).writeAsBytesSync(resp.bodyBytes);
          await OpenFile.open(path);
          _showToast('Saved to $path');
        }
      } else {
        _showToast('Error: ${resp.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _generateAssessmentReport() async {
    if (_selectedSubject == null ||
        _yearController.text.isEmpty ||
        _selectedAssessmentType == null) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/assessment-report'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'subjectid': _selectedSubject!.id,
          'year': _yearController.text,
          'assessment_type': _selectedAssessmentType,
        }),
      );

      if (response.statusCode == 200) {
        final fileName = 'assessment_${_selectedSubject!.id}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateMonthlyWithQuizzesReport() async {
    if (_yearController.text.isEmpty) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/all-monthlies-with-quizzes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'year': _yearController.text,
        }),
      );

      if (response.statusCode == 200) {
        final fileName = 'monthly_quizzes_${widget.campusID}_report.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir = await getDownloadsDirectory() ??
              await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _generateAllSubjectsReport() async {
    if (_yearController.text.isEmpty || _selectedAssessmentType == null) {
      _showToast('Please fill all fields');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://193.203.162.232:5050/ReportDownload/all-subjects-assessments'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'campusid': widget.campusID,
          'year': _yearController.text.trim(),
          'assessment_type': _selectedAssessmentType,
        }),
      );

      if (response.statusCode == 200) {
        final fileName =
            'all_subjects_${widget.campusID}_${_yearController.text}_${_selectedAssessmentType}.xlsx';

        if (kIsWeb) {
          final blob = html.Blob([response.bodyBytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          html.AnchorElement(href: url)
            ..setAttribute('download', fileName)
            ..click();
          html.Url.revokeObjectUrl(url);
          _showToast('Report download started!');
        } else {
          final downloadsDir =
              await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          final filePath = '${downloadsDir.path}/$fileName';
          final file = File(filePath)..writeAsBytesSync(response.bodyBytes);
          await OpenFile.open(filePath);
          _showToast('Saved to $filePath');
        }
      } else {
        _showToast('Error generating report: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showToast('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: AdminColors.secondaryBackground,
      textColor: AdminColors.primaryText,
    );
  }
}

class Subject {
  final int id;
  final String name;
  final String day;
  final String teacher;
  final int year;

  Subject({
    required this.id,
    required this.name,
    required this.day,
    required this.teacher,
    required this.year,
  });

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
    id: json['subject_id'] as int,
    name: json['subject_name'] as String,
    day: json['day'] as String,
    teacher: json['teacher_name'] as String,
    year: json['year'] as int,
  );

  @override
  String toString() => '$name ($id)';
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final Color? borderColor;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;

  const GlassCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 16,
    this.borderColor,
    this.margin,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AdminColors.cardBorder,
          width: 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AdminColors.glassEffectLight,
            AdminColors.glassEffectDark,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AdminColors.primaryBackground.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: child,
      ),
    );
  }
}

class GlassInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;

  const GlassInputField({
    Key? key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: AdminTextStyles.cardTitle.copyWith(color: AdminColors.primaryText),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AdminTextStyles.cardSubtitle.copyWith(
              color: AdminColors.primaryText.withOpacity(0.7),
            ),
            border: InputBorder.none,
            icon: Icon(icon, color: AdminColors.primaryText.withOpacity(0.7)),
          ),
          validator: validator,
        ),
      ),
    );
  }
}