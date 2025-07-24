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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final messageColor = isMe ? AppColors.primary : AppColors.textSecondary;
    final textColor = isMe ? AppColors.textPrimary : AppColors.textPrimary;
    final receiptColor = isMe ? AppColors.primaryLight : AppColors.textSecondary;

    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.defaultBorderRadius),
            border: isMe ? null : Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMe)
                Text(
                  message.senderName,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              Text(
                message.content,
                style: textTheme.bodyMedium?.copyWith(color: textColor),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('h:mm a').format(message.timestamp),
                    style: textTheme.labelSmall?.copyWith(
                      color: textColor.withOpacity(0.7),
                    ),
                  ),
                  if (isMe && showReadReceipt)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Icon(
                        message.readers.isNotEmpty ? Icons.done_all : Icons.done,
                        size: 12,
                        color: message.readers.isNotEmpty
                            ? AppColors.secondary
                            : textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        if (isMe && showReadReceipt)
          Padding(
            padding: const EdgeInsets.only(right: 12, bottom: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  message.readers.isNotEmpty ? Icons.done_all : Icons.done,
                  size: 14,
                  color: message.readers.isNotEmpty
                      ? AppColors.secondary
                      : receiptColor,
                ),
                const SizedBox(width: 4),
                Text(
                  message.readers.isNotEmpty
                      ? 'Read by ${message.readers.length}'
                      : 'Delivered',
                  style: textTheme.labelSmall?.copyWith(
                    color: message.readers.isNotEmpty
                        ? AppColors.secondary
                        : receiptColor,
                  ),
                ),
                if (message.readers.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onViewReaders,
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.secondary,
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