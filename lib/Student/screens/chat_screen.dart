import 'dart:async';

import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/api_service.dart';
import '../widgets/chat_message_bubble.dart';
import '../utils/theme.dart';

class ChatScreen extends StatefulWidget {
  final int subjectId;
  final String roomName;
  final String currentUserRfid; // Add current user RFID

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
      _markMessagesAsRead(); // Mark messages as read when loaded
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
        id: DateTime.now().millisecondsSinceEpoch, // convert int to String
        roomId: _roomId ??0,                          // convert int to String
        senderId: widget.currentUserRfid,                    // already String
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
        SnackBar(content: Text('Failed to send message: ${e.toString()}')),
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
      // Get unread messages from others
      final unreadMessages = _messages.where((m) =>
      m.senderId != widget.currentUserRfid && !m.isRead
      ).toList();

      if (unreadMessages.isNotEmpty) {
        await _apiService.markMessagesAsRead(
          messageIds: unreadMessages.map((m) => m.id).toList(),
          readerRfid: widget.currentUserRfid,
        );

        // Update local state
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
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.roomName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.05),
              AppColors.background
            ],
          ),
        ),
        child: Column(
          children: [
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_errorMessage != null)
              Expanded(
                child: Center(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshMessages,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  color: Colors.white,
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return ChatMessageBubble(
                        message: message,
                        isMe: message.senderId == widget.currentUserRfid,
                        showReadReceipt: message.senderId == widget.currentUserRfid,
                      );
                    },
                  ),
                ),
              ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }


  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.mark_as_unread),
            title: const Text('Mark all as read'),
            onTap: () {
              Navigator.pop(context);
              _markAllMessagesAsRead();
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Clear chat history'),
            onTap: () => _confirmClearChat(context),
          ),
        ],
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
        SnackBar(content: Text('Failed to mark messages as read: $e')),
      );
    }
  }

  void _confirmClearChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat history?'),
        content: const Text('This will remove all messages from this chat.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearChatHistory();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
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
        SnackBar(content: Text('Failed to clear chat: $e')),
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.add, color: AppColors.primary),
            onPressed: _showAttachmentOptions,
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
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