import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';
import '../utils/theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool showReadReceipt;
  final VoidCallback? onViewReaders;

  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showReadReceipt = false,
    this.onViewReaders,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primaryLight : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  message.senderName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
              Text(
                message.content,
                style: TextStyle(color: isMe ? Colors.white : Colors.black),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
                  if (isMe && showReadReceipt)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        message.readers.isNotEmpty ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.readers.isNotEmpty ? Colors.blue : Colors.white70,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        // Read receipts section
        // Replace the read receipts section with this:
        if (isMe && showReadReceipt)
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Always show the icon
                Icon(
                  message.readers.isNotEmpty ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.readers.isNotEmpty ? Colors.blue : Colors.grey,
                ),
                const SizedBox(width: 4),
                // Show either "Read by X" or "Delivered"
                Text(
                  message.readers.isNotEmpty
                      ? 'Read by ${message.readers.length}'
                      : 'Delivered',
                  style: TextStyle(
                    fontSize: 12,
                    color: message.readers.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                ),
                // Only show info button if there are readers
                if (message.readers.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onViewReaders,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}