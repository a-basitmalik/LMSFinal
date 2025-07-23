import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:newapp/admin/themes/theme_colors.dart';
import 'package:newapp/admin/themes/theme_text_styles.dart';

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
          backgroundColor: AdminColors.dangerAccent,
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
        Navigator.pop(context, true);
      } else {
        throw Exception('Failed to delete planner');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting planner: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
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
        backgroundColor: AdminColors.secondaryBackground,
        title: Text(
          'Delete Plan',
          style: AdminTextStyles.cardTitle.copyWith(color: AdminColors.primaryText),
        ),
        content: Text(
          'Are you sure you want to delete this plan?',
          style: AdminTextStyles.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AdminTextStyles.secondaryButton),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePlanner();
            },
            child: Text(
              'DELETE',
              style: AdminTextStyles.secondaryButton.copyWith(color: AdminColors.dangerAccent),
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
            backgroundColor: AdminColors.successAccent,
          ),
        );
      } else {
        throw Exception('Failed to delete attachment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting attachment: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
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
              backgroundColor: AdminColors.successAccent,
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
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog() async {
    final titleController = TextEditingController(text: widget.planner.title);
    final descriptionController = TextEditingController(text: widget.planner.description);
    final pointsController = TextEditingController(
        text: widget.planner.points?.replaceAll('|||', '\n') ?? ''
    );
    final homeworkController = TextEditingController(text: widget.planner.homework ?? '');
    DateTime? selectedDate = DateTime.parse(widget.planner.plannedDate);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AdminColors.secondaryBackground,
        title: Text(
          'Edit Plan',
          style: AdminTextStyles.sectionHeader,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: AdminTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AdminColors.primaryAccent),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: AdminTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AdminColors.primaryAccent),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),
              TextField(
                controller: pointsController,
                style: AdminTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Lesson Points (one per line)',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AdminColors.primaryAccent),
                  ),
                ),
                maxLines: 5,
              ),
              SizedBox(height: 16),
              TextField(
                controller: homeworkController,
                style: AdminTextStyles.cardTitle,
                decoration: InputDecoration(
                  labelText: 'Homework',
                  labelStyle: AdminTextStyles.cardSubtitle,
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AdminColors.primaryAccent),
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
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.dark(
                            primary: AdminColors.primaryAccent,
                            onPrimary: AdminColors.primaryBackground,
                            surface: AdminColors.secondaryBackground,
                            onSurface: AdminColors.primaryText,
                          ),
                          dialogBackgroundColor: AdminColors.primaryBackground,
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
                    labelStyle: AdminTextStyles.cardSubtitle,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, y').format(selectedDate!),
                        style: AdminTextStyles.cardTitle,
                      ),
                      Icon(Icons.calendar_today, color: AdminColors.primaryAccent),
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
            child: Text('CANCEL', style: AdminTextStyles.secondaryButton),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updatePlanner(
                title: titleController.text,
                description: descriptionController.text,
                points: pointsController.text.split('\n').join('|||'),
                homework: homeworkController.text,
                plannedDate: selectedDate,
              );
            },
            child: Text(
              'SAVE',
              style: AdminTextStyles.secondaryButton.copyWith(color: AdminColors.primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePlanner({
    String? title,
    String? description,
    String? points,
    String? homework,
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
          'points': points ?? widget.planner.points,
          'homework': homework ?? widget.planner.homework,
          'planned_date': plannedDate?.toIso8601String() ?? widget.planner.plannedDate,
          'subject_id': subjectId ?? widget.planner.subjectId,
        }),
      );

      if (response.statusCode == 200) {
        final updatedPlanner = json.decode(response.body)['planner'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Plan updated successfully'),
            backgroundColor: AdminColors.successAccent,
          ),
        );
        // Update the parent widget's data if needed
        if (mounted) {
          setState(() {
            widget.planner.title = updatedPlanner['title'];
            widget.planner.description = updatedPlanner['description'];
            widget.planner.points = updatedPlanner['points'];
            widget.planner.homework = updatedPlanner['homework'];
            widget.planner.plannedDate = updatedPlanner['planned_date'];
          });
        }
      } else {
        throw Exception('Failed to update planner');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating planner: ${e.toString()}'),
          backgroundColor: AdminColors.dangerAccent,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildPointsSection() {
    if (widget.planner.points == null || widget.planner.points!.isEmpty) {
      return SizedBox();
    }

    final points = widget.planner.points!.split('|||');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'LESSON POINTS',
          style: AdminTextStyles.cardTitle.copyWith(
            color: AdminColors.secondaryText,
          ),
        ),
        SizedBox(height: 8),
        ...points.map((point) => Padding(
          padding: EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 4, right: 8),
                child: Icon(
                  Icons.circle,
                  size: 8,
                  color: AdminColors.primaryAccent,
                ),
              ),
              Expanded(
                child: Text(
                  point.trim(),
                  style: AdminTextStyles.cardSubtitle.copyWith(
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        )).toList(),
      ],
    );
  }

  Widget _buildHomeworkSection() {
    if (widget.planner.homework == null || widget.planner.homework!.isEmpty) {
      return SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 16),
        Text(
          'HOMEWORK',
          style: AdminTextStyles.cardTitle.copyWith(
            color: AdminColors.secondaryText,
          ),
        ),
        SizedBox(height: 8),
        Text(
          widget.planner.homework!,
          style: AdminTextStyles.cardSubtitle.copyWith(
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final plannedDate = DateTime.parse(widget.planner.plannedDate);
    final createdAt = widget.planner.createdAt != null
        ? DateTime.parse(widget.planner.createdAt!)
        : plannedDate;

    return Scaffold(
      backgroundColor: AdminColors.primaryBackground,
      appBar: AppBar(
        title: Text('PLAN DETAILS', style: AdminTextStyles.sectionHeader),
        backgroundColor: AdminColors.secondaryBackground,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AdminColors.primaryAccent),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: Icon(Icons.delete, color: AdminColors.dangerAccent),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(color: AdminColors.primaryAccent),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Planner Details Card
            Container(
              decoration: AdminColors.glassDecoration(),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.planner.subjectName ?? 'No Subject',
                          style: AdminTextStyles.cardTitle.copyWith(
                            color: AdminColors.plannerColor,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AdminColors.plannerColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AdminColors.plannerColor,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            DateFormat('h:mm a').format(plannedDate),
                            style: AdminTextStyles.cardSubtitle.copyWith(
                              color: AdminColors.plannerColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.planner.title ?? 'Untitled Plan',
                      style: AdminTextStyles.sectionHeader,
                    ),
                    SizedBox(height: 16),
                    Text(
                      widget.planner.description ?? 'No description provided',
                      style: AdminTextStyles.cardSubtitle.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 24),
                    _buildPointsSection(),
                    _buildHomeworkSection(),
                    Divider(color: AdminColors.cardBorder),
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
              style: AdminTextStyles.cardTitle.copyWith(
                color: AdminColors.secondaryText,
              ),
            ),
            SizedBox(height: 8),
            if (_hasAttachments)
              Column(
                children: [
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _attachments.length,
                    itemBuilder: (context, index) {
                      final attachment = _attachments[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 8),
                        decoration: AdminColors.glassDecoration(),
                        child: ListTile(
                          leading: Icon(
                            _getAttachmentIcon(attachment['type']),
                            color: AdminColors.primaryAccent,
                          ),
                          title: Text(
                            attachment['name'] ?? 'Unnamed file',
                            style: AdminTextStyles.cardTitle,
                          ),
                          subtitle: Text(
                            attachment['size']?.toString() ?? '',
                            style: AdminTextStyles.cardSubtitle,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.download,
                                    color: AdminColors.primaryAccent),
                                onPressed: () {
                                  // Handle download
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete,
                                    color: AdminColors.dangerAccent),
                                onPressed: () {
                                  if (attachment['attachment_id'] != null) {
                                    _deleteAttachment(attachment['attachment_id']);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 8),
                  _buildAddAttachmentButton(),
                ],
              )
            else
              Column(
                children: [
                  _buildAddAttachmentButton(),
                  SizedBox(height: 16),
                ],
              ),
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
        Icon(icon, size: 20, color: AdminColors.secondaryText),
        SizedBox(width: 8),
        Text(
          '$label: $value',
          style: AdminTextStyles.cardSubtitle,
        ),
      ],
    );
  }

  Widget _buildAddAttachmentButton() {
    return InkWell(
      onTap: _uploadAttachment,
      child: Container(
        height: 100,
        decoration: AdminColors.glassDecoration(),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AdminColors.secondaryText),
              SizedBox(height: 8),
              Text(
                'Add files or links',
                style: AdminTextStyles.cardSubtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(String? type) {
    if (type == null) return Icons.insert_drive_file;

    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
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