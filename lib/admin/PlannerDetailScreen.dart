import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';

import 'PlannerListScreen.dart';

class PlannerDetailScreen extends StatefulWidget {
  final Planner planner;

  const PlannerDetailScreen({required this.planner, Key? key}) : super(key: key);

  @override
  _PlannerDetailScreenState createState() => _PlannerDetailScreenState();
}

class _PlannerDetailScreenState extends State<PlannerDetailScreen> {
  bool _isLoading = false;
  bool _hasAttachments = false;
  List<dynamic> _attachments = [];

  @override
  void initState() {
    super.initState();
    _fetchAttachments();
  }

  Future<void> _fetchAttachments() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://193.203.162.232:5050/Planner/attachments?planner_id=${widget.planner.plannerId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attachments = data['attachments'] ?? [];
          _hasAttachments = _attachments.isNotEmpty;
        });
      } else {
        throw Exception('Failed to load attachments');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attachments: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deletePlanner() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('http://193.203.162.232:5050/Planner/planners/${widget.planner.plannerId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        Navigator.pop(context, true); // Return success
      } else {
        throw Exception('Failed to delete planner');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting planner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Delete Plan',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete this plan?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlanner();
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAttachment(int attachmentId) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.delete(
        Uri.parse('http://193.203.162.232:5050/Planner/attachments/$attachmentId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _attachments.removeWhere((a) => a['attachment_id'] == attachmentId);
          _hasAttachments = _attachments.isNotEmpty;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attachment deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to delete attachment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting attachment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAttachment() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        setState(() => _isLoading = true);

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://193.203.162.232:5050/Planner/attachments'),
        );

        request.fields['planner_id'] = widget.planner.plannerId.toString();
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            file.path,
            filename: result.files.single.name,
          ),
        );

        var response = await request.send();
        final respStr = await response.stream.bytesToString();

        if (response.statusCode == 201) {
          final data = json.decode(respStr);
          setState(() {
            _attachments.add(data['attachment']);
            _hasAttachments = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attachment uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          throw Exception('Failed to upload attachment');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading attachment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: widget.planner.title);
    final descriptionController = TextEditingController(text: widget.planner.description);
    DateTime? selectedDate = DateTime.parse(widget.planner.plannedDate);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A2E),
        title: Text(
          'Edit Plan',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                    builder: (context, child) {
                      return Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: Colors.cyanAccent,
                            onPrimary: Colors.black,
                            surface: Color(0xFF1A1A2E),
                            onSurface: Colors.white,
                          ),
                          dialogBackgroundColor: Color(0xFF0A0A1A),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null && picked != selectedDate) {
                    selectedDate = picked;
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, y').format(selectedDate!),
                        style: TextStyle(color: Colors.white),
                      ),
                      Icon(Icons.calendar_today, color: Colors.cyanAccent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updatePlanner(
                title: titleController.text,
                description: descriptionController.text,
                plannedDate: selectedDate,
              );
            },
            child: Text(
              'SAVE',
              style: TextStyle(color: Colors.cyanAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePlanner({
    String? title,
    String? description,
    DateTime? plannedDate,
    int? subjectId,
  }) async {
    setState(() => _isLoading = true);
    try {
      final response = await http.put(
        Uri.parse('http://193.203.162.232:5050/Planner/planners/${widget.planner.plannerId}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': title ?? widget.planner.title,
          'description': description ?? widget.planner.description,
          'planned_date': plannedDate?.toIso8601String() ?? widget.planner.plannedDate,
          'subject_id': subjectId ?? widget.planner.subjectId,
        }),
      );

      if (response.statusCode == 200) {
        // You might want to refresh the planner data here
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        // Optionally refresh the data
        _fetchAttachments();
      } else {
        throw Exception('Failed to update planner');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating planner: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plannedDate = DateTime.parse(widget.planner.plannedDate);
    final createdAt = widget.planner.createdAt != null
        ? DateTime.parse(widget.planner.createdAt!)
        : plannedDate;

    return Scaffold(
      backgroundColor: Color(0xFF0A0A1A),
      appBar: AppBar(
        title: Text('PLAN DETAILS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: Colors.cyanAccent),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Color(0xFF1A1A2E),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Colors.cyanAccent.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.planner.subjectName ?? 'No Subject',
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.cyanAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.cyanAccent, width: 1),
                          ),
                          child: Text(
                            DateFormat('h:mm a').format(plannedDate),
                            style: TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.planner.title ?? 'Untitled Plan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.planner.description ?? 'No description provided',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 24),
                    Divider(color: Colors.white24),
                    SizedBox(height: 16),
                    if (widget.planner.teacherName != null) ...[
                      _buildDetailRow(
                        icon: Icons.person_outline,
                        label: 'Teacher',
                        value: widget.planner.teacherName!,
                      ),
                      SizedBox(height: 8),
                    ],
                    _buildDetailRow(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('MMMM d, y').format(plannedDate),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: DateFormat('h:mm a').format(plannedDate),
                    ),
                    SizedBox(height: 8),
                    _buildDetailRow(
                      icon: Icons.schedule,
                      label: 'Created',
                      value: DateFormat('MMMM d, y').format(createdAt),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'ATTACHMENTS',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            _hasAttachments
                ? ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _attachments.length,
              itemBuilder: (context, index) {
                final attachment = _attachments[index];
                return Card(
                  color: Color(0xFF1A1A2E),
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      _getAttachmentIcon(attachment['type']),
                      color: Colors.cyanAccent,
                    ),
                    title: Text(
                      attachment['name'],
                      style: TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${attachment['size'] ?? ''}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download, color: Colors.cyanAccent),
                          onPressed: () {
                            // Handle download
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteAttachment(attachment['attachment_id']);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
                : _buildAddAttachmentButton(),
            if (!_hasAttachments) SizedBox(height: 16),
            if (!_hasAttachments) _buildAddAttachmentButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.white70),
        SizedBox(width: 8),
        Text(
          '$label: $value',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return InkWell(
      onTap: _uploadAttachment,
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
                'Add files or links',
                style: TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'link':
        return Icons.link;
      default:
        return Icons.insert_drive_file;
    }
  }
}