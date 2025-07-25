import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:newapp/Teacher/themes/theme_colors.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import 'package:newapp/Teacher/themes/theme_text_styles.dart';


class SubjectChatScreen extends StatefulWidget {
  final Map<String, dynamic> subject;
  final String teacherId;

  const SubjectChatScreen({
    Key? key,
    required this.subject,
    required this.teacherId,
  }) : super(key: key);

  @override
  _SubjectChatScreenState createState() => _SubjectChatScreenState();
}

class _SubjectChatScreenState extends State<SubjectChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int? _roomId;
  final String _baseUrl = 'http://193.203.162.232:5050/SubjectChat';
  bool _showAssignmentDialog = false;
  final _assignmentFormKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _pointsController = TextEditingController();
  DateTime? _dueDate;
  List<Map<String, dynamic>> _attachments = [];

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
  }

  Future<void> _initializeChatRoom() async {
    try {
      final roomResponse = await http.post(
        Uri.parse('$_baseUrl/chat/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subject_id': widget.subject['subject_id']}),
      );

      if (roomResponse.statusCode == 200) {
        final roomData = json.decode(roomResponse.body);
        _roomId = roomData['room_id'];
        await _fetchMessages();
      } else {
        throw Exception('Failed to create chat room');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error initializing chat: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchMessages() async {
    if (_roomId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/chat/rooms/$_roomId/messages'),
      );

      if (response.statusCode == 200) {
        final messages = json.decode(response.body);
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading messages: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _roomId == null) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/messages'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'room_id': _roomId,
          'teacher_id': widget.teacherId,
          'message_text': message,
        }),
      );

      if (response.statusCode == 200) {
        await _fetchMessages();
      } else {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${e.toString()}',
            style: TeacherTextStyles.cardSubtitle.copyWith(color: TeacherColors.primaryText),
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
      _messageController.text = message;
    }
  }

  Future<void> _createAssignment() async {
    if (!_assignmentFormKey.currentState!.validate()) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/subjects/${widget.subject['subject_id']}/assignments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'due_date': _dueDate?.toIso8601String(),
          'total_points': int.tryParse(_pointsController.text) ?? 100,
          'attachments': _attachments,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Assignment created successfully',
              style: TeacherTextStyles.cardSubtitle.copyWith(color: TeacherColors.primaryText),
            ),
            backgroundColor: TeacherColors.successAccent,
          ),
        );
        setState(() {
          _showAssignmentDialog = false;
          _titleController.clear();
          _descriptionController.clear();
          _pointsController.clear();
          _dueDate = null;
          _attachments = [];
        });
      } else {
        throw Exception('Failed to create assignment');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to create assignment: ${e.toString()}',
            style: TeacherTextStyles.cardSubtitle.copyWith(color: TeacherColors.primaryText),
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: TeacherColors.assignmentColor,
              onPrimary: TeacherColors.primaryText,
              onSurface: TeacherColors.primaryText,
            ),
            dialogBackgroundColor: TeacherColors.primaryBackground,
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 23, minute: 59),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: ColorScheme.light(
                primary: TeacherColors.assignmentColor,
                onPrimary: TeacherColors.primaryText,
                onSurface: TeacherColors.primaryText,
              ),
              dialogBackgroundColor: TeacherColors.primaryBackground,
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Widget _buildMessageBubble(dynamic message) {
    final isMe = message['sender_id'] == widget.teacherId;
    final timestamp = message['sent_at'] != null
        ? DateTime.parse(message['sent_at'])
        : DateTime.now();
    final timeString = DateFormat('h:mm a').format(timestamp);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? TeacherColors.primaryAccent
                    : TeacherColors.cardBackground,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isMe ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isMe ? Radius.zero : const Radius.circular(12),
                ),
                border: Border.all(
                  color: TeacherColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Text(
                message['message_text'] ?? '',
                style: isMe
                    ? TeacherTextStyles.primaryButton
                    : TeacherTextStyles.listItemTitle,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeString,
                  style: TeacherTextStyles.cardSubtitle,
                ),
                if (isMe && message['read_receipts'] != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 12,
                    color: TeacherColors.infoAccent,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentDialog() {
    return Dialog(
      backgroundColor: TeacherColors.primaryBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: TeacherColors.cardBorder),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _assignmentFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Create New Assignment',
                style: TeacherTextStyles.sectionHeader.copyWith(
                  color: TeacherColors.assignmentColor,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                ),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pointsController,
                style: TeacherTextStyles.listItemTitle,
                decoration: InputDecoration(
                  labelText: 'Total Points',
                  labelStyle: TeacherTextStyles.cardSubtitle,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: TeacherColors.cardBorder),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Points are required' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate!)}',
                  style: TeacherTextStyles.listItemTitle,
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: TeacherColors.assignmentColor,
                ),
                onTap: _pickDueDate,
                tileColor: TeacherColors.cardBackground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: TeacherColors.cardBorder),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.dangerAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _showAssignmentDialog = false;
                      });
                    },
                    child: Text(
                      'Cancel',
                      style: TeacherTextStyles.primaryButton,
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TeacherColors.assignmentColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _createAssignment,
                    child: Text(
                      'Create',
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

  Widget _buildFloatingActionButtons() {
    return SpeedDial(
      icon: Icons.add,
      activeIcon: Icons.close,
      backgroundColor: TeacherColors.assignmentColor,
      foregroundColor: TeacherColors.primaryText,
      overlayColor: Colors.black,
      overlayOpacity: 0.5,
      spacing: 12,
      spaceBetweenChildren: 8,
      children: [
        SpeedDialChild(
          child: Icon(Icons.assignment, color: TeacherColors.primaryText),
          backgroundColor: TeacherColors.assignmentColor,
          label: 'New Assignment',
          labelStyle: TeacherTextStyles.sectionHeader,
          onTap: () => setState(() => _showAssignmentDialog = true),
        ),
        SpeedDialChild(
          child: Icon(Icons.delete, color: TeacherColors.primaryText),
          backgroundColor: TeacherColors.dangerAccent,
          label: 'Clear Chat',
          labelStyle: TeacherTextStyles.sectionHeader,
          onTap: _roomId != null
              ? () async {
            try {
              final response = await http.delete(
                Uri.parse('$_baseUrl/chat/rooms/$_roomId/messages'),
              );
              if (response.statusCode == 200) {
                setState(() {
                  _messages.clear();
                });
              } else {
                throw Exception('Failed to clear chat');
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to clear chat: ${e.toString()}',
                    style: TeacherTextStyles.cardSubtitle
                        .copyWith(color: TeacherColors.primaryText),
                  ),
                  backgroundColor: TeacherColors.dangerAccent,
                ),
              );
            }
          }
              : null,
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: TeacherColors.secondaryBackground,
        border: Border(
          top: BorderSide(
            color: TeacherColors.cardBorder,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: TeacherTextStyles.listItemTitle,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TeacherTextStyles.cardSubtitle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: TeacherColors.cardBackground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: TeacherColors.primaryAccent.toCircleDecoration(),
            child: IconButton(
              icon: Icon(
                Icons.send,
                color: TeacherColors.primaryText,
              ),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Chat',
          style: TeacherTextStyles.className,
        ),
        backgroundColor: TeacherColors.chatColor,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(
                  child: CircularProgressIndicator(
                    color: TeacherColors.primaryAccent,
                  ),
                )
                    : _errorMessage.isNotEmpty
                    ? Center(
                  child: Text(
                    _errorMessage,
                    style: TeacherTextStyles.cardTitle,
                  ),
                )
                    : _messages.isEmpty
                    ? Center(
                  child: Text(
                    'No messages yet',
                    style: TeacherTextStyles.cardTitle,
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
              ),
              _buildMessageInput(),
            ],
          ),
          if (_showAssignmentDialog) _buildAssignmentDialog(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }
}