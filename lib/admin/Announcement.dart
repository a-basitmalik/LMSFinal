import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';

void main() {
  runApp(AnnouncementApp());
}

class AnnouncementApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeoAnnounce',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0A0E21),
        primaryColor: Color(0xFF00D1FF),
        colorScheme: ColorScheme.dark(
          secondary: Color(0xFF00FFA3),
          surface: Color(0xFF1D1E33),
        ),
        cardTheme: CardTheme(
          elevation: 6,
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.blueGrey.shade800, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color(0xFF1D1E33),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.blueGrey.shade700),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Color(0xFF00D1FF)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      home: AnnouncementCreator(campusID: 1),
    );
  }
}

class AnnouncementCreator extends StatefulWidget {
  final int campusID;

  const AnnouncementCreator({Key? key, required this.campusID}) : super(key: key);

  @override
  _AnnouncementCreatorState createState() => _AnnouncementCreatorState();
}

class _AnnouncementCreatorState extends State<AnnouncementCreator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _announcementController = TextEditingController();

  bool _isAllStudents = true;
  bool _isLoading = false;
  final List<String> _selectedGroups = [];
  final List<String> _availableGroups = ['FA', 'PreMedical', 'PreEngineering', 'ICS'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _subjectController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final url = "http://193.203.162.232:5050/announcement/create";
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'subject': _subjectController.text,
          'announcement': _announcementController.text,
          'audience_type': _isAllStudents ? 'all' : 'group',
          'subject_groups': _isAllStudents ? [] : _selectedGroups,
          'campus_id': widget.campusID,
        }),
      ).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          _showSuccess();
        } else {
          _showError('Failed to post announcement');
        }
      } else {
        _showError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Network error: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Announcement posted successfully!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
    _subjectController.clear();
    _announcementController.clear();
    setState(() {
      _selectedGroups.clear();
      _isAllStudents = true;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildGroupChip(String group) {
    final isSelected = _selectedGroups.contains(group);
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
          colors: [Color(0xFF00D1FF), Color(0xFF00FFA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
            : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? Colors.transparent : Colors.blueGrey.shade600,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedGroups.remove(group);
            } else {
              _selectedGroups.add(group);
            }
          });
          HapticFeedback.lightImpact();
        },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            group,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF00D1FF)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'CREATE ANNOUNCEMENT',
          style: TextStyle(
            fontSize: 16,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00D1FF),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A0E21).withOpacity(0.8),
                Color(0xFF1D1E33).withOpacity(0.9),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Audience Selection
                Text(
                  'TARGET AUDIENCE',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Radio(
                              value: true,
                              groupValue: _isAllStudents,
                              onChanged: (value) {
                                setState(() {
                                  _isAllStudents = value as bool;
                                });
                                HapticFeedback.lightImpact();
                              },
                              activeColor: Color(0xFF00D1FF),
                            ),
                            Text(
                              'All Students',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Radio(
                              value: false,
                              groupValue: _isAllStudents,
                              onChanged: (value) {
                                setState(() {
                                  _isAllStudents = value as bool;
                                });
                                HapticFeedback.lightImpact();
                              },
                              activeColor: Color(0xFF00D1FF),
                            ),
                            Text(
                              'Specific Groups',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                        if (!_isAllStudents) ...[
                          SizedBox(height: 12),
                          Text(
                            'SELECT GROUPS:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueGrey.shade400,
                              letterSpacing: 1.1,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            children: _availableGroups
                                .map((group) => _buildGroupChip(group))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Subject Input
                Text(
                  'ANNOUNCEMENT SUBJECT',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _subjectController,
                      decoration: InputDecoration(
                        labelText: 'Enter subject',
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400),
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(fontSize: 16),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Subject is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // Announcement Content
                Text(
                  'ANNOUNCEMENT CONTENT',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blueGrey.shade400,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: TextFormField(
                      controller: _announcementController,
                      decoration: InputDecoration(
                        labelText: 'Enter announcement',
                        labelStyle: TextStyle(color: Colors.blueGrey.shade400),
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      style: TextStyle(fontSize: 16),
                      maxLines: 6,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Announcement content is required';
                        }
                        return null;
                      },
                    ),
                  ),
                ),
                SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _postAnnouncement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF00D1FF), Color(0xFF00FFA3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : Text(
                          'POST ANNOUNCEMENT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}