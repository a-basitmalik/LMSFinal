import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';
import '../Student/models/subject_model.dart';

class SubjectAnnouncementScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectAnnouncementScreen({super.key, required this.subject});

  @override
  _AnnouncementScreenState createState() => _AnnouncementScreenState();
}

class _AnnouncementScreenState extends State<SubjectAnnouncementScreen> {
  List<Map<String, dynamic>> announcements = [];
  bool isLoading = true;
  String errorMessage = '';
  final String baseUrl = 'http://193.203.162.232:5050/SubjectAnnouncement';

  @override
  void initState() {
    super.initState();
    _fetchAnnouncements();
  }

  Future<void> _fetchAnnouncements() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subject/${widget.subject['subject_id']}/announcements'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          announcements = List<Map<String, dynamic>>.from(data);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load announcements');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading announcements: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _addAnnouncement() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    List<PlatformFile> selectedFiles = [];

    final result = await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.all(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    TeacherColors.primaryBackground.withOpacity(0.95),
                    TeacherColors.secondaryBackground.withOpacity(0.95),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: TeacherColors.cardBorder.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New Announcement',
                      style: TeacherTextStyles.sectionHeader.copyWith(
                        fontSize: 24,
                        color: TeacherColors.primaryAccent,
                      ),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: titleController,
                      style: TeacherTextStyles.listItemTitle,
                      decoration: InputDecoration(
                        labelText: 'Title',
                        labelStyle: TeacherTextStyles.cardSubtitle,
                        floatingLabelStyle: TextStyle(color: TeacherColors.primaryAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: TeacherColors.primaryAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: TeacherColors.secondaryBackground.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      style: TeacherTextStyles.listItemTitle,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TeacherTextStyles.cardSubtitle,
                        floatingLabelStyle: TextStyle(color: TeacherColors.primaryAccent),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: TeacherColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: TeacherColors.primaryAccent, width: 2),
                        ),
                        filled: true,
                        fillColor: TeacherColors.secondaryBackground.withOpacity(0.7),
                      ),
                    ),
                    SizedBox(height: 16),
                    if (selectedFiles.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Attachments:',
                            style: TeacherTextStyles.sectionHeader.copyWith(fontSize: 16),
                          ),
                          SizedBox(height: 8),
                          ...selectedFiles.map((file) => Container(
                            margin: EdgeInsets.only(bottom: 8),
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: TeacherColors.secondaryBackground.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: TeacherColors.cardBorder.withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.attach_file, color: TeacherColors.primaryAccent),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    file.name,
                                    style: TeacherTextStyles.listItemTitle,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, size: 20, color: TeacherColors.dangerAccent),
                                  onPressed: () => setState(() => selectedFiles.remove(file)),
                                ),
                              ],
                            ),
                          )),
                        ],
                      ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          allowMultiple: true,
                        );
                        if (result != null) {
                          setState(() => selectedFiles.addAll(result.files));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
                        foregroundColor: TeacherColors.primaryAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: TeacherColors.primaryAccent, width: 1.5),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.attach_file, size: 20),
                          SizedBox(width: 8),
                          Text('Add Attachments', style: TeacherTextStyles.primaryButton),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: Text('Cancel', style: TeacherTextStyles.secondaryButton),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            if (titleController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Title is required', style: TeacherTextStyles.listItemTitle),
                                  backgroundColor: TeacherColors.dangerAccent,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              );
                              return;
                            }
                            Navigator.pop(context, {
                              'title': titleController.text,
                              'description': descriptionController.text,
                              'files': selectedFiles,
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TeacherColors.primaryAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                            elevation: 3,
                            shadowColor: TeacherColors.primaryAccent.withOpacity(0.3),
                          ),
                          child: Text('Post', style: TeacherTextStyles.primaryButton),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result != null) {
      await _submitAnnouncement(
        result['title'],
        result['description'],
        result['files'],
      );
    }
  }

  Future<void> _submitAnnouncement(
      String title,
      String description,
      List<PlatformFile> files,
      ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/announcement'),
      );

      request.fields['subject_id'] = widget.subject['subject_id'].toString();
      request.fields['title'] = title;
      request.fields['description'] = description;

      for (var file in files) {
        final mimeType = lookupMimeType(file.name);
        final fileExtension = mimeType?.split('/').last ?? '';

        request.files.add(await http.MultipartFile.fromPath(
          'attachments',
          file.path!,
          contentType: MediaType.parse(mimeType ?? 'application/octet-stream'),
          filename: '${DateTime.now().millisecondsSinceEpoch}.$fileExtension',
        ));
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement posted successfully', style: TeacherTextStyles.listItemTitle),
            backgroundColor: TeacherColors.successAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(20),
          ),
        );
        _fetchAnnouncements();
      } else {
        throw Exception('Failed to post announcement: $responseData');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}', style: TeacherTextStyles.listItemTitle),
          backgroundColor: TeacherColors.dangerAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(20),
        ),
      );
    }
  }

  void _openAttachment(String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                TeacherColors.primaryBackground.withOpacity(0.95),
                TeacherColors.secondaryBackground.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: TeacherColors.cardBorder.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.insert_drive_file_rounded,
                size: 48,
                color: TeacherColors.primaryAccent,
              ),
              SizedBox(height: 16),
              Text(
                'Attachment Options',
                style: TeacherTextStyles.sectionHeader.copyWith(fontSize: 20),
              ),
              SizedBox(height: 16),
              Text(
                'Would you like to download or view this attachment?',
                style: TeacherTextStyles.listItemTitle,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: Text(
                      'Cancel',
                      style: TeacherTextStyles.secondaryButton,
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening attachment...', style: TeacherTextStyles.listItemTitle),
                          backgroundColor: TeacherColors.infoAccent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: EdgeInsets.all(20),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      elevation: 3,
                      shadowColor: TeacherColors.primaryAccent.withOpacity(0.3),
                    ),
                    child: Text(
                      'Open',
                      style: TeacherTextStyles.primaryButton,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Announcements',
          style: TeacherTextStyles.className.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
        backgroundColor: TeacherColors.primaryAccent,
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TeacherColors.primaryAccent.withOpacity(0.9),
                TeacherColors.primaryAccent.withOpacity(0.7),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: TeacherColors.primaryAccent.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
                offset: Offset(0, 5),
              ),
            ],
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(24),
            ),
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: TeacherColors.primaryAccent,
              strokeWidth: 3,
            ),
            SizedBox(height: 20),
            Text(
              'Loading Announcements...',
              style: TeacherTextStyles.listItemTitle.copyWith(
                color: TeacherColors.primaryText.withOpacity(0.7),
              ),
            ),
          ],
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: TeacherColors.dangerAccent,
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage,
                style: TeacherTextStyles.listItemTitle,
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAnnouncements,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text(
                'Retry',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ],
        ),
      )
          : announcements.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.announcement_rounded,
              size: 60,
              color: TeacherColors.primaryText.withOpacity(0.3),
            ),
            SizedBox(height: 16),
            Text(
              'No announcements yet',
              style: TeacherTextStyles.listItemTitle.copyWith(
                color: TeacherColors.primaryText.withOpacity(0.5),
              ),
            ),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _addAnnouncement,
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherColors.primaryAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
              child: Text(
                'Create First Announcement',
                style: TeacherTextStyles.primaryButton,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchAnnouncements,
        color: TeacherColors.primaryAccent,
        backgroundColor: TeacherColors.primaryBackground,
        displacement: 40,
        strokeWidth: 3,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    final announcement = announcements[index];
                    final createdDate = DateTime.parse(announcement['created_at']);
                    final formattedDate = DateFormat('MMM dd, yyyy - hh:mm a').format(createdDate);
                    final isNew = DateTime.now().difference(createdDate).inDays < 1;

                    return Container(
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            TeacherColors.cardBackground.withOpacity(0.7),
                            TeacherColors.cardBackground.withOpacity(0.4),
                          ],
                        ),
                        border: Border.all(
                          color: TeacherColors.cardBorder.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 15,
                            spreadRadius: 1,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {},
                          child: Padding(
                            padding: EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            announcement['title'],
                                            style: TeacherTextStyles.cardTitle.copyWith(
                                              fontSize: 20,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            formattedDate,
                                            style: TeacherTextStyles.cardSubtitle.copyWith(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isNew)
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: TeacherColors.dangerAccent.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: TeacherColors.dangerAccent,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          'NEW',
                                          style: TeacherTextStyles.primaryButton.copyWith(
                                            fontSize: 10,
                                            color: TeacherColors.dangerAccent,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  announcement['description'] ?? '',
                                  style: TeacherTextStyles.listItemSubtitle.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 16),
                                if (announcement['attachments'] != null &&
                                    announcement['attachments'].length > 0)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Attachments:',
                                        style: TeacherTextStyles.sectionHeader.copyWith(
                                          fontSize: 16,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: announcement['attachments']
                                            .map<Widget>((attachment) {
                                          return InkWell(
                                            onTap: () => _openAttachment(attachment['file_url']),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Container(
                                              padding: EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: TeacherColors.secondaryBackground.withOpacity(0.5),
                                                borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: TeacherColors.cardBorder.withOpacity(0.3),
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.attach_file,
                                                    size: 16,
                                                    color: TeacherColors.primaryAccent,
                                                  ),
                                                  SizedBox(width: 6),
                                                  Text(
                                                    attachment['file_name'],
                                                    style: TeacherTextStyles.listItemSubtitle,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: announcements.length,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAnnouncement,
        child: Icon(Icons.add, size: 28),
        backgroundColor: TeacherColors.primaryAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}