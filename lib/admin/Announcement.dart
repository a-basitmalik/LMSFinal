import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart';
class SubjectGroup {
  final int id;
  final String name;

  SubjectGroup({required this.id, required this.name});

  factory SubjectGroup.fromJson(Map<String, dynamic> json) {
    return SubjectGroup(
      id: json['subject_group_id'],
      name: json['subject_group_name'],
    );
  }
}

class AnnouncementAttachment {
  final int? announcementId;
  final int attachmentId;
  final String? fileName;
  final String? fileUrl;
  final DateTime? uploadedAt;

  AnnouncementAttachment({
    this.announcementId,
    required this.attachmentId,
    this.fileName,
    this.fileUrl,
    this.uploadedAt,
  });

  factory AnnouncementAttachment.fromJson(Map<String, dynamic> json) {
    return AnnouncementAttachment(
      announcementId: json['announcement_id'],
      attachmentId: json['attachment_id'],
      fileName: json['file_name'],
      fileUrl: json['file_url'],
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.parse(json['uploaded_at'])
          : null,
    );
  }
}

class AnnouncementApiService {
  static const String baseUrl = 'http://193.203.162.232:5050/announcement';

  static Future<List<SubjectGroup>> fetchSubjectGroups() async {
    final response = await http.get(Uri.parse('$baseUrl/subject_groups'));

    if (response.statusCode == 200) {
      final List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((group) => SubjectGroup.fromJson(group)).toList();
    } else {
      throw Exception('Failed to load subject groups');
    }
  }

  static Future<Map<String, dynamic>> createAnnouncement({
    required String subject,
    required String announcement,
    required String audienceType,
    required int campusId,
    List<int>? subjectGroupIds,
    List<http.MultipartFile>? attachments,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/announcement/create'),
    );

    // Add form fields
    request.fields['subject'] = subject;
    request.fields['announcement'] = announcement;
    request.fields['audience_type'] = audienceType;
    request.fields['campus_id'] = campusId.toString();

    if (subjectGroupIds != null && subjectGroupIds.isNotEmpty) {
      request.fields['subject_group_ids'] = json.encode(subjectGroupIds);
    }

    // Add attachments
    if (attachments != null) {
      for (var attachment in attachments) {
        request.files.add(attachment);
      }
    }

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return json.decode(responseData);
    } else {
      throw Exception('Failed to create announcement: ${response.reasonPhrase}');
    }
  }
}

class AnnouncementCreator extends StatefulWidget {
  final int campusID;
  final String campusName;

  const AnnouncementCreator({
    Key? key,
    required this.campusID,
    required this.campusName,
  }) : super(key: key);

  @override
  _AnnouncementCreatorState createState() => _AnnouncementCreatorState();
}

class _AnnouncementCreatorState extends State<AnnouncementCreator> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _announcementController = TextEditingController();

  bool _isAllStudents = true;
  bool _isLoading = false;
  bool _isLoadingGroups = true;
  List<SubjectGroup> _availableGroups = [];
  List<int> _selectedGroupIds = [];
  List<File> _attachments = [];

  @override
  void initState() {
    super.initState();
    _loadSubjectGroups();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadSubjectGroups() async {
    setState(() => _isLoadingGroups = true);
    try {
      final groups = await AnnouncementApiService.fetchSubjectGroups();
      setState(() {
        _availableGroups = groups;
        _isLoadingGroups = false;
      });
    } catch (e) {
      setState(() => _isLoadingGroups = false);
      _showError('Failed to load groups: ${e.toString()}');
    }
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() {
          _attachments.addAll(result.paths.map((path) => File(path!)).toList());
        });
      }
    } catch (e) {
      _showError('Error picking files: ${e.toString()}');
    }
  }

  Future<void> _removeAttachment(int index) async {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _postAnnouncement() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_isAllStudents && _selectedGroupIds.isEmpty) {
      _showError('Please select at least one group');
      return;
    }

    setState(() => _isLoading = true);

    try {
      List<http.MultipartFile> multipartFiles = [];
      for (var file in _attachments) {
        multipartFiles.add(await http.MultipartFile.fromPath(
          'attachments',
          file.path,
          filename: file.path.split('/').last,
        ));
      }

      final response = await AnnouncementApiService.createAnnouncement(
        subject: _subjectController.text,
        announcement: _announcementController.text,
        audienceType: _isAllStudents ? 'all' : 'group',
        campusId: widget.campusID,
        subjectGroupIds: _isAllStudents ? null : _selectedGroupIds,
        attachments: multipartFiles,
      );

      if (response['success']) {
        _showSuccess();
      } else {
        _showError(response['message'] ?? 'Failed to post announcement');
      }
    } catch (e) {
      _showError('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectGroups(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SELECT GROUPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _isLoadingGroups
                        ? const Center(
                      child: CircularProgressIndicator(color: Colors.cyanAccent),
                    )
                        : ListView.builder(
                      itemCount: _availableGroups.length,
                      itemBuilder: (context, index) {
                        final group = _availableGroups[index];
                        final isSelected = _selectedGroupIds.contains(group.id);
                        return ListTile(
                          title: Text(
                            group.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
                              : null,
                          onTap: () {
                            setModalState(() {
                              if (isSelected) {
                                _selectedGroupIds.remove(group.id);
                              } else {
                                _selectedGroupIds.add(group.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor: Colors.cyanAccent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('DONE'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }


  Widget _buildAttachmentPreview() {
    if (_attachments.isEmpty) return SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'ATTACHMENTS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _attachments.length,
          itemBuilder: (context, index) {
            final file = _attachments[index];
            return Card(
              color: Color(0xFF1A1A2E),
              margin: EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  _getAttachmentIcon(file.path.split('.').last),
                  color: Colors.cyanAccent,
                ),
                title: Text(
                  file.path.split('/').last,
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: Text(
                  '${(file.lengthSync() / 1024).toStringAsFixed(2)} KB',
                  style: TextStyle(color: Colors.white70),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeAttachment(index),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return InkWell(
      onTap: _pickFiles,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white24,
            width: 1,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: Colors.white54),
              SizedBox(height: 8),
              Text(
                'Add files',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf': return Icons.picture_as_pdf;
      case 'doc': case 'docx': return Icons.description;
      case 'jpg': case 'jpeg': case 'png': case 'gif': return Icons.image;
      default: return Icons.insert_drive_file;
    }
  }

  void _showSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Announcement posted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('CREATE ANNOUNCEMENT'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _postAnnouncement,
              child: Text(
                'POST',
                style: TextStyle(color: Colors.cyanAccent),
              ),
            ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audience Selection
              Card(
                color: Color(0xFF1A1A2E),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TARGET AUDIENCE',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Radio(
                            value: true,
                            groupValue: _isAllStudents,
                            onChanged: (value) {
                              setState(() {
                                _isAllStudents = value as bool;
                              });
                            },
                            activeColor: Colors.cyanAccent,
                          ),
                          Text('All Students', style: TextStyle(color: Colors.white)),
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
                            },
                            activeColor: Colors.cyanAccent,
                          ),
                          Text('Specific Groups', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      if (!_isAllStudents) ...[
                        SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _selectGroups(context),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.cyanAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('SELECT GROUPS'),
                          ),
                        ),
                        if (_selectedGroupIds.isNotEmpty) ...[
                          SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _selectedGroupIds.map((id) {
                              final group = _availableGroups.firstWhere((g) => g.id == id);
                              return Chip(
                                label: Text(group.name),
                                backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                                deleteIcon: Icon(Icons.close, size: 16),
                                onDeleted: () {
                                  setState(() {
                                    _selectedGroupIds.remove(id);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Subject Input
              TextFormField(
                controller: _subjectController,
                decoration: InputDecoration(
                  labelText: 'Subject',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF1A1A2E),
                ),
                style: TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Announcement Content
              TextFormField(
                controller: _announcementController,
                decoration: InputDecoration(
                  labelText: 'Announcement Content',
                  labelStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFF1A1A2E),
                  alignLabelWithHint: true,
                ),
                style: TextStyle(color: Colors.white),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter announcement content';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Attachments
              Text(
                'ATTACHMENTS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              _buildAddAttachmentButton(),
              _buildAttachmentPreview(),
              SizedBox(height: 32),

              // Submit Button
              if (!_isLoading)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _postAnnouncement,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.cyanAccent,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'POST ANNOUNCEMENT',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(color: Colors.cyanAccent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}