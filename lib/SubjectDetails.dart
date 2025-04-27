import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism/glassmorphism.dart';

class SubjectDetailsPage extends StatefulWidget {
  final int subjectId;
  final String year;
  final String subjectName;
  final int campusId;

  const SubjectDetailsPage({
    Key? key,
    required this.subjectId,
    required this.year,
    required this.subjectName,
    required this.campusId,
  }) : super(key: key);

  @override
  _SubjectDetailsPageState createState() => _SubjectDetailsPageState();
}

class _SubjectDetailsPageState extends State<SubjectDetailsPage> {
  List<Student> _students = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
    _searchController.addListener(_filterStudents);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchStudents() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _students = [
        Student(id: 1, name: 'John Doe', rollNumber: 'STU001', avatarColor: Colors.blue),
        Student(id: 2, name: 'Jane Smith', rollNumber: 'STU002', avatarColor: Colors.purple),
        Student(id: 3, name: 'Robert Johnson', rollNumber: 'STU003', avatarColor: Colors.green),
        Student(id: 4, name: 'Emily Davis', rollNumber: 'STU004', avatarColor: Colors.orange),
        Student(id: 5, name: 'Michael Wilson', rollNumber: 'STU005', avatarColor: Colors.red),
      ];
      _isLoading = false;
    });
  }

  void _filterStudents() {
    // Implement search filtering
  }

  Future<void> _removeStudent(int studentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => GlassmorphicAlertDialog(
        title: 'CONFIRM REMOVAL',
        content: 'Remove this student from ${widget.subjectName}?',
        confirmText: 'REMOVE',
        onConfirm: () => Navigator.pop(context, true),
        onCancel: () => Navigator.pop(context, false),
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 800));
      setState(() {
        _students.removeWhere((student) => student.id == studentId);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student removed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _showAddStudentDialog() async {
    final List<Student> allStudents = [
      Student(id: 6, name: 'Alex Turner', rollNumber: 'STU006', avatarColor: Colors.teal),
      Student(id: 7, name: 'Sarah Connor', rollNumber: 'STU007', avatarColor: Colors.pink),
      Student(id: 8, name: 'David Miller', rollNumber: 'STU008', avatarColor: Colors.amber),
    ];

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassmorphicContainer(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.8,
        borderRadius: 20,
        blur: 20,
        alignment: Alignment.bottomCenter,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'ADD STUDENTS',
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GlassmorphicContainer(
                width: double.infinity,
                height: 50,
                borderRadius: 12,
                blur: 20,
                border: 1,
                linearGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderGradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.5),
                    Colors.white.withOpacity(0.1),
                  ],
                ),
                child: TextField(
                  controller: TextEditingController(),
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search students...',
                    hintStyle: TextStyle(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(top: 16),
                itemCount: allStudents.length,
                itemBuilder: (context, index) {
                  final student = allStudents[index];
                  return ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            student.avatarColor.withOpacity(0.8),
                            student.avatarColor.withOpacity(0.4),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          student.name.substring(0, 1),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      student.name,
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      student.rollNumber,
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.add_circle, color: Colors.cyanAccent),
                      onPressed: () async {
                        Navigator.pop(context);
                        setState(() => _students.add(student));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${student.name} added'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.greenAccent,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0A1A),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [
                  Color(0xFF1A1A2E),
                  Color(0xFF000000),
                ],
              ),
            ),
          ),

          // Content
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.subjectName.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 1.5,
                    ),
                  ),
                  centerTitle: true,
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blueAccent.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: GlassmorphicContainer(
                    width: double.infinity,
                    height: 80,
                    borderRadius: 16,
                    blur: 20,
                    border: 1,
                    linearGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderGradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.5),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '${widget.year} • ${_students.length} STUDENTS',
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 16,
                          letterSpacing: 1.2,
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
                    color: Colors.cyanAccent,
                  ),
                ),
              )
                  : _students.isEmpty
                  ? SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 60,
                        color: Colors.white54,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'NO STUDENTS ENROLLED',
                        style: GoogleFonts.orbitron(
                          color: Colors.white54,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              )
                  : SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final student = _students[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: GlassmorphicContainer(
                        width: double.infinity,
                        height: 80,
                        borderRadius: 16,
                        blur: 20,
                        border: 1,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.05),
                          ],
                        ),
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.5),
                            Colors.white.withOpacity(0.1),
                          ],
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  student.avatarColor.withOpacity(0.8),
                                  student.avatarColor.withOpacity(0.4),
                                ],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                student.name.substring(0, 1),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            student.name,
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            student.rollNumber,
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.remove_circle, color: Colors.redAccent),
                            onPressed: () => _removeStudent(student.id),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _students.length,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddStudentDialog,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Colors.cyanAccent, Colors.blueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withOpacity(0.4),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(Icons.add, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
    );
  }
}

class Student {
  final int id;
  final String name;
  final String rollNumber;
  final Color avatarColor;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    required this.avatarColor,
  });
}

class GlassmorphicAlertDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final Function() onConfirm;
  final Function() onCancel;

  const GlassmorphicAlertDialog({
    required this.title,
    required this.content,
    required this.confirmText,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassmorphicContainer(
        width: double.infinity,
        height: 200,
        borderRadius: 20,
        blur: 20,
        border: 1,
        linearGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.5),
            Colors.white.withOpacity(0.1),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 18,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: onCancel,
                    child: Text(
                      'CANCEL',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: Colors.white30,
                  ),
                  TextButton(
                    onPressed: onConfirm,
                    child: Text(
                      confirmText,
                      style: GoogleFonts.orbitron(
                        color: Colors.redAccent,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final double blur;
  final double border;
  final LinearGradient linearGradient;
  final LinearGradient borderGradient;
  final Widget? child;
  final AlignmentGeometry alignment;

  const GlassmorphicContainer({
    required this.width,
    required this.height,
    required this.borderRadius,
    required this.blur,
    required this.border,
    required this.linearGradient,
    required this.borderGradient,
    this.child,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: linearGradient,
        border: Border.all(
          width: border,
          color: Colors.transparent,
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: blur,
            spreadRadius: 0,
            color: Colors.black.withOpacity(0.1),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            width: border,
            style: BorderStyle.solid,
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        child: child,
      ),
    );
  }
}