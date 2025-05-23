import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectAnnouncementsScreen extends StatelessWidget {
  final Map<String, dynamic> subject;

  const SubjectAnnouncementsScreen({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final subjectColor = subject['color'] ?? Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text('All Announcements'),
        backgroundColor: subjectColor,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildAnnouncementCard(
            title: 'Exam Schedule Posted',
            content: 'Final exams will begin next week on Monday',
            time: '2h ago',
            icon: Icons.announcement,
            color: Colors.blue,
          ),
          SizedBox(height: 12),
          _buildAnnouncementCard(
            title: 'Assignment 3 Graded',
            content: 'Grades for the last assignment are now available',
            time: '1d ago',
            icon: Icons.assignment,
            color: Colors.green,
          ),
          SizedBox(height: 12),
          _buildAnnouncementCard(
            title: 'Course Materials Updated',
            content: 'New reading materials have been uploaded for Chapter 4',
            time: '3d ago',
            icon: Icons.library_books,
            color: Colors.orange,
          ),
          // Add more announcements as needed
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard({
    required String title,
    required String content,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(content, style: GoogleFonts.poppins()),
          ],
        ),
      ),
    );
  }
}
