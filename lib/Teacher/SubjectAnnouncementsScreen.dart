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
          return AlertDialog(
            backgroundColor: TeacherColors.primaryBackground,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: TeacherColors.cardBorder),
            ),
            title: Text(
              'New Announcement',
              style: TeacherTextStyles.sectionHeader.copyWith(color: TeacherColors.primaryText),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: TeacherTextStyles.listItemTitle,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      labelStyle: TeacherTextStyles.cardSubtitle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TeacherColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TeacherColors.cardBorder),
                      ),
                      filled: true,
                      fillColor: TeacherColors.secondaryBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    style: TeacherTextStyles.listItemTitle,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      labelStyle: TeacherTextStyles.cardSubtitle,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TeacherColors.cardBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: TeacherColors.cardBorder),
                      ),
                      filled: true,
                      fillColor: TeacherColors.secondaryBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (selectedFiles.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachments:',
                          style: TeacherTextStyles.sectionHeader,
                        ),
                        ...selectedFiles.map((file) => ListTile(
                          leading: Icon(Icons.attach_file, color: TeacherColors.primaryAccent),
                          title: Text(file.name, style: TeacherTextStyles.listItemTitle),
                          trailing: IconButton(
                            icon: Icon(Icons.close, color: TeacherColors.dangerAccent),
                            onPressed: () {
                              setState(() {
                                selectedFiles.remove(file);
                              });
                            },
                          ),
                        )),
                      ],
                    ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    ),
                    onPressed: () async {
                      final result = await FilePicker.platform.pickFiles(
                        allowMultiple: true,
                      );
                      if (result != null) {
                        setState(() {
                          selectedFiles.addAll(result.files);
                        });
                      }
                    },
                    child: Text('Add Attachments', style: TeacherTextStyles.primaryButton),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TeacherTextStyles.secondaryButton),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TeacherColors.successAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Title is required', style: TeacherTextStyles.listItemTitle),
                        backgroundColor: TeacherColors.dangerAccent,
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
                child: Text('Post', style: TeacherTextStyles.primaryButton),
              ),
            ],
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
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/announcement'),
      );

      // Add fields
      request.fields['subject_id'] = widget.subject['subject_id'].toString();
      request.fields['title'] = title;
      request.fields['description'] = description;

      // Add files
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

      // Send request
      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Announcement posted successfully', style: TeacherTextStyles.listItemTitle),
            backgroundColor: TeacherColors.successAccent,
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
        ),
      );
    }
  }

  void _openAttachment(String fileUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: TeacherColors.primaryBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: TeacherColors.cardBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Attachment',
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 16),
              Text(
                'Would you like to download or view this attachment?',
                style: TeacherTextStyles.listItemTitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TeacherTextStyles.secondaryButton,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.primaryAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Opening attachment...', style: TeacherTextStyles.listItemTitle),
                          backgroundColor: TeacherColors.infoAccent,
                        ),
                      );
                    },
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
          'All Announcements',
          style: TeacherTextStyles.className,
        ),
        backgroundColor: TeacherColors.primaryAccent,
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: TeacherColors.primaryAccent,
        ),
      )
          : errorMessage.isNotEmpty
          ? Center(
        child: Text(
          errorMessage,
          style: TeacherTextStyles.listItemTitle,
        ),
      )
          : announcements.isEmpty
          ? Center(
        child: Text(
          'No announcements yet',
          style: TeacherTextStyles.listItemTitle,
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: announcements.length,
        separatorBuilder: (context, index) =>
        const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final announcement = announcements[index];
          final createdDate = DateTime.parse(
              announcement['created_at']);
          final formattedDate =
          DateFormat('MMM dd, yyyy - hh:mm a')
              .format(createdDate);
          final isNew = DateTime.now()
              .difference(createdDate)
              .inDays <
              1;

          return Container(
            decoration: TeacherColors.glassDecoration(
              borderRadius: 16,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with NEW badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          announcement['title'],
                          style: TeacherTextStyles.cardTitle,
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: TeacherColors.dangerAccent,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Text(
                            'NEW',
                            style: TeacherTextStyles.primaryButton.copyWith(fontSize: 10),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Time with circle bullet
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: TeacherColors.secondaryText,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: TeacherTextStyles.cardSubtitle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Content
                  Text(
                    announcement['description'] ?? '',
                    style: TeacherTextStyles.listItemSubtitle,
                  ),
                  const SizedBox(height: 12),

                  // Attachments
                  if (announcement['attachments'] != null &&
                      announcement['attachments'].length > 0)
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachments:',
                          style: TeacherTextStyles.sectionHeader,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: announcement['attachments']
                              .map<Widget>((attachment) {
                            return GestureDetector(
                              onTap: () =>
                                  _openAttachment(attachment['file_url']),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: TeacherColors.secondaryBackground,
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      size: 16,
                                      color: TeacherColors.primaryAccent,
                                    ),
                                    const SizedBox(width: 4),
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addAnnouncement,
        child: Icon(Icons.add),
        backgroundColor: TeacherColors.primaryAccent,
      ),
    );
  }
}