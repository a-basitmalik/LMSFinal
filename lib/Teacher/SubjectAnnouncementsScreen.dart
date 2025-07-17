import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
  final String baseUrl = 'http://192.168.18.185:5050/SubjectAnnouncement';

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
            title: Text(
              'New Announcement',
              style: GoogleFonts.poppins(),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  if (selectedFiles.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attachments:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ...selectedFiles.map((file) => ListTile(
                          leading: Icon(Icons.attach_file),
                          title: Text(file.name),
                          trailing: IconButton(
                            icon: Icon(Icons.close),
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
                    child: Text('Add Attachments'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Title is required')),
                    );
                    return;
                  }

                  Navigator.pop(context, {
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'files': selectedFiles,
                  });
                },
                child: Text('Post'),
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
          SnackBar(content: Text('Announcement posted successfully')),
        );
        _fetchAnnouncements();
      } else {
        throw Exception('Failed to post announcement: $responseData');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _openAttachment(String fileUrl) {
    // In a real app, you would use url_launcher or a file viewer
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Attachment'),
        content: Text('Would you like to download or view this attachment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement actual download/view logic here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening attachment...')),
              );
            },
            child: Text('Open'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FF),
      appBar: AppBar(
        title: Text(
          'All Announcements',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF4361EE),
        elevation: 0,
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : announcements.isEmpty
          ? Center(child: Text('No announcements yet'))
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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
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
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (isNew)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius:
                            BorderRadius.circular(10),
                          ),
                          child: Text(
                            'NEW',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
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
                        decoration: const BoxDecoration(
                          color: Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Text(
                        formattedDate,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Content
                  Text(
                    announcement['description'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.5,
                    ),
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
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
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
                                  color: Colors.grey[100],
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.attach_file,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      attachment['file_name'],
                                      style:
                                      GoogleFonts.poppins(),
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
        backgroundColor: const Color(0xFF4361EE),
      ),
    );
  }
}