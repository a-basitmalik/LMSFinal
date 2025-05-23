import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'package:file_picker/file_picker.dart';

class SubjectChatScreen extends StatefulWidget {
  final Map<String, dynamic> subject;

  const SubjectChatScreen({super.key, required this.subject});

  @override
  _SubjectChatScreenState createState() => _SubjectChatScreenState();
}

class _SubjectChatScreenState extends State<SubjectChatScreen>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  final String _apiUrl = 'https://your-api-endpoint.com/chat';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  PlatformFile? _pickedFile; // To store the selected file

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _fetchMessages();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await http.get(
        Uri.parse('$_apiUrl?subject=${widget.subject['code']}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          messages = List<Map<String, dynamic>>.from(data['messages']);
          _isLoading = false;
        });
        _animationController.forward();
        _scrollToBottom();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading messages: $e')));
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = {
      'text': _messageController.text,
      'is_teacher': true,
      'timestamp': DateTime.now().toIso8601String(),
      'subject': widget.subject['code'],
    };

    setState(() {
      _isSending = true;
      messages.add(newMessage);
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newMessage),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to send message');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      setState(() {
        messages.removeLast();
      });
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _scrollToBottom() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _pickedFile = result.files.first;
        });
        // You can now upload this file or attach it to the message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: ${_pickedFile!.name}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subjectColor = widget.subject['color'] ?? theme.primaryColor;
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            _buildChatHeader(theme, subjectColor),
            Expanded(
              child:
                  _isLoading
                      ? Center(child: CircularProgressIndicator())
                      : messages.isEmpty
                      ? FadeTransition(
                        opacity: _fadeAnimation,
                        child: _buildEmptyState(theme),
                      )
                      : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(top: 8, bottom: 80),
                        itemCount: messages.length,
                        itemBuilder:
                            (context, index) => SlideTransition(
                              position: Tween<Offset>(
                                begin: Offset(0, 0.5),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    0.1 * index,
                                    1.0,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              ),
                              child: _buildMessageBubble(
                                messages[index],
                                theme,
                                subjectColor,
                              ),
                            ),
                      ),
            ),
            _buildMessageInput(theme, subjectColor),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Your navigation action
        },
        backgroundColor: subjectColor,
        child: Icon(Icons.navigation),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
    );
  }

  Widget _buildChatHeader(ThemeData theme, Color subjectColor) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: subjectColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Text(
            '${widget.subject['name']} Chat',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.forum_outlined,
            size: 80,
            color: theme.colorScheme.onSurface.withOpacity(0.3),
          ),
          SizedBox(height: 16),
          Text(
            'No messages yet',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Start the conversation!',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    ThemeData theme,
    Color subjectColor,
  ) {
    final isTeacher = message['is_teacher'] ?? false;
    final timestamp = DateTime.parse(message['timestamp']);
    final timeString = DateFormat('h:mm a').format(timestamp);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: isTeacher ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Column(
            crossAxisAlignment:
                isTeacher ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isTeacher ? subjectColor : theme.colorScheme.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(isTeacher ? 18 : 0),
                    topRight: Radius.circular(isTeacher ? 0 : 18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 1,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message['text'],
                  style: GoogleFonts.poppins(
                    color:
                        isTeacher ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 15,
                  ),
                ),
              ),
              SizedBox(height: 6),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  timeString,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(ThemeData theme, Color subjectColor) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: theme.dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pickedFile != null)
                _buildFileAttachmentIndicator(theme, subjectColor),
              Row(
                children: [
                  // Attachment Button
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.attach_file, color: subjectColor),
                      onPressed: _pickFile,
                      padding: EdgeInsets.all(12),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Message Input Field
                  Expanded(
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight:
                            120, // Limits the height for multi-line input
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceVariant.withOpacity(
                          0.2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        style: theme.textTheme.bodyMedium,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      color: subjectColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon:
                          _isSending
                              ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: _isSending ? null : _sendMessage,
                      padding: EdgeInsets.all(12),
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

  Widget _buildFileAttachmentIndicator(ThemeData theme, Color subjectColor) {
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.insert_drive_file, color: subjectColor, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              _pickedFile!.name,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _pickedFile = null),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}
