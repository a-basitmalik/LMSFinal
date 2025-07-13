import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

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
  final String _baseUrl = 'http://192.168.18.185:5050/SubjectChat';
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
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
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
          SnackBar(content: Text('Assignment created successfully')),
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
        SnackBar(content: Text('Failed to create assignment: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickDueDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: 23, minute: 59),
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
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).primaryColor
                    : Colors.grey[200],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                  bottomLeft: isMe ? Radius.circular(12) : Radius.circular(0),
                  bottomRight: isMe ? Radius.circular(0) : Radius.circular(12),
                ),
              ),
              child: Text(
                message['message_text'] ?? '',
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
            ),
            SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
                if (isMe && message['read_receipts'] != null) ...[
                  SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 12,
                    color: Colors.blue,
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
    return AlertDialog(
      title: Text('Create New Assignment'),
      content: SingleChildScrollView(
        child: Form(
          key: _assignmentFormKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) =>
                value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              TextFormField(
                controller: _pointsController,
                decoration: InputDecoration(labelText: 'Total Points'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                value?.isEmpty ?? true ? 'Points are required' : null,
              ),
              ListTile(
                title: Text(
                  _dueDate == null
                      ? 'Select Due Date'
                      : 'Due: ${DateFormat('MMM dd, yyyy - hh:mm a').format(_dueDate!)}',
                ),
                trailing: Icon(Icons.calendar_today),
                onTap: _pickDueDate,
              ),
              // Attachment upload would go here
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showAssignmentDialog = false;
                      });
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _createAssignment,
                    child: Text('Create'),
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
      animatedIcon: AnimatedIcons.menu_close,
      animatedIconTheme: IconThemeData(size: 22.0),
      visible: true,
      curve: Curves.bounceIn,
      children: [
        SpeedDialChild(
          child: Icon(Icons.assignment),
          backgroundColor: Colors.blue,
          label: 'New Assignment',
          labelStyle: TextStyle(fontSize: 18.0),
          onTap: () => setState(() => _showAssignmentDialog = true),
        ),
        SpeedDialChild(
          child: Icon(Icons.delete),
          backgroundColor: Colors.red,
          label: 'Clear Chat',
          labelStyle: TextStyle(fontSize: 18.0),
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
                SnackBar(content: Text('Failed to clear chat: ${e.toString()}')),
              );
            }
          }
              : null,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.subject['name']} Chat',
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: widget.subject['color'] ?? Theme.of(context).primaryColor,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : _errorMessage.isNotEmpty
                    ? Center(child: Text(_errorMessage))
                    : _messages.isEmpty
                    ? Center(child: Text('No messages yet'))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(8),
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

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 2,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            child: IconButton(
              icon: Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
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