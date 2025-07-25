import 'dart:async';
import 'package:flutter/material.dart';
import 'package:newapp/Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../models/chat_message_model.dart';
import '../services/api_service.dart';
import '../widgets/chat_message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final int subjectId;
  final String roomName;
  final String currentUserRfid;

  const ChatScreen({
    super.key,
    required this.subjectId,
    required this.roomName,
    required this.currentUserRfid,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ApiService _apiService = ApiService();
  int? _roomId;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _readReceiptTimer;

  @override
  void initState() {
    super.initState();
    _initializeChatRoom();
    _startReadReceiptTimer();
  }

  @override
  void dispose() {
    _readReceiptTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _initializeChatRoom() async {
    try {
      _roomId = await _apiService.getOrCreateChatRoom(widget.subjectId);
      await _loadMessages();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load chat: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_roomId == null) return;

    try {
      final messages = await _apiService.getMessagesByRoomId(_roomId!);
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom();
      _markMessagesAsRead();
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load messages');
    }
  }

  Future<void> _refreshMessages() async {
    await _loadMessages();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _roomId == null) return;

    try {
      final newMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        roomId: _roomId ?? 0,
        senderId: widget.currentUserRfid,
        senderName: 'You',
        content: text,
        timestamp: DateTime.now(),
        isRead: true,
      );

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });
      _scrollToBottom();

      await _apiService.sendMessage(
        roomId: _roomId!,
        senderRfid: widget.currentUserRfid,
        messageText: text,
      );

      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to send message: ${e.toString()}',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  void _startReadReceiptTimer() {
    _readReceiptTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _markMessagesAsRead();
    });
  }

  Future<void> _markMessagesAsRead() async {
    if (_roomId == null) return;

    try {
      final unreadMessages = _messages.where((m) =>
      m.senderId != widget.currentUserRfid && !m.isRead).toList();

      if (unreadMessages.isNotEmpty) {
        await _apiService.markMessagesAsRead(
          messageIds: unreadMessages.map((m) => m.id).toList(),
          readerRfid: widget.currentUserRfid,
        );

        setState(() {
          for (final msg in unreadMessages) {
            msg.isRead = true;
          }
        });
      }
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Scaffold(
      backgroundColor: TeacherColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.roomName.toUpperCase(),
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert,
              color: TeacherColors.primaryText,
            ),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isLoading)
            Expanded(
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
                ),
              ),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
                child: Text(
                  _errorMessage!,
                  style: TeacherTextStyles.cardSubtitle.copyWith(
                    color: TeacherColors.dangerAccent,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshMessages,
                backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
                color: TeacherColors.primaryAccent,
                child: Container(
                  decoration: TeacherColors.glassDecoration(),
                  margin: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        return ChatMessageBubble(
                          message: message,
                          isMe: message.senderId == widget.currentUserRfid,
                          showReadReceipt:
                          message.senderId == widget.currentUserRfid,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: TeacherColors.cardBorder,
            width: 1.0,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              TeacherColors.glassEffectLight,
              TeacherColors.glassEffectDark,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.mark_as_unread,
                color: TeacherColors.primaryAccent,
              ),
              title: Text(
                'Mark all as read',
                style: TeacherTextStyles.cardTitle,
              ),
              onTap: () {
                Navigator.pop(context);
                _markAllMessagesAsRead();
              },
            ),
            Divider(
              height: 1,
              color: TeacherColors.cardBorder.withOpacity(0.3),
            ),
            ListTile(
              leading: Icon(
                Icons.delete,
                color: TeacherColors.dangerAccent,
              ),
              title: Text(
                'Clear chat history',
                style: TeacherTextStyles.cardTitle,
              ),
              onTap: () => _confirmClearChat(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _markAllMessagesAsRead() async {
    try {
      final unreadIds = _messages
          .where((m) => m.senderId != widget.currentUserRfid && !m.isRead)
          .map((m) => m.id)
          .toList();

      if (unreadIds.isNotEmpty) {
        await _apiService.markMessagesAsRead(
          messageIds: unreadIds,
          readerRfid: widget.currentUserRfid,
        );

        setState(() {
          for (final msg in _messages) {
            if (unreadIds.contains(msg.id)) {
              msg.isRead = true;
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to mark messages as read: $e',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: TeacherColors.glassDecoration(),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Clear chat history?',
                style: TeacherTextStyles.sectionHeader,
              ),
              const SizedBox(height: 16),
              Text(
                'This will remove all messages from this chat.',
                style: TeacherTextStyles.cardSubtitle,
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
                      style: TeacherTextStyles.cardSubtitle,
                    ),
                  ),
                  Container(
                    height: 30,
                    width: 1,
                    color: TeacherColors.cardBorder,
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _clearChatHistory();
                    },
                    child: Text(
                      'Clear',
                      style: TeacherTextStyles.cardSubtitle.copyWith(
                        color: TeacherColors.dangerAccent,
                      ),
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

  Future<void> _clearChatHistory() async {
    if (_roomId == null) return;

    try {
      await _apiService.clearChatHistory(_roomId!);
      await _loadMessages();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to clear chat: $e',
            style: TeacherTextStyles.cardSubtitle,
          ),
          backgroundColor: TeacherColors.dangerAccent,
        ),
      );
    }
  }

  Widget _buildMessageInput(BuildContext context) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: TeacherColors.glassDecoration(
        borderColor: TeacherColors.primaryAccent.withOpacity(0.3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.add,
              color: TeacherColors.primaryAccent,
            ),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              style: TeacherTextStyles.cardTitle,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                hintStyle: TeacherTextStyles.cardSubtitle,
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  TeacherColors.primaryAccent.withOpacity(0.8),
                  TeacherColors.primaryAccent.withOpacity(0.6),
                ],
              ),
            ),
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

  void _showAttachmentOptions() {
    // Implement attachment options
  }
}