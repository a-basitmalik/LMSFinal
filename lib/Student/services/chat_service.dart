// lib/services/chat_service.dart
import '../models/chat_message_model.dart';

abstract class ChatService {
  // Chat Rooms
  Future<List<Map<String, dynamic>>> getChatRooms();
  Future<int> getUnreadCountForRoom(String roomId);
  Future<void> markRoomAsRead(String roomId);

  // Messages
  Future<List<ChatMessage>> getMessagesForRoom(String roomId, {int limit = 20});
  Future<List<ChatMessage>> loadOlderMessages(
    String roomId,
    DateTime beforeTimestamp,
  );
  Future<ChatMessage> sendMessage(String roomId, String content);
  Future<void> deleteMessage(String messageId);
  Stream<List<ChatMessage>> getMessageStream(String roomId);
}

class MockChatService implements ChatService {
  final String currentUserId;
  final List<Map<String, dynamic>> _mockRooms = [
    {
      'id': 'general',
      'name': 'General Chat',
      'subject': 'General',
      'lastMessage': 'Hello everyone!',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 1)),
    },
    {
      'id': 'math',
      'name': 'Mathematics',
      'subject': 'Math',
      'lastMessage': 'Did you solve problem 5?',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 2)),
    },
    {
      'id': 'science',
      'name': 'Science',
      'subject': 'Science',
      'lastMessage': 'Lab report due tomorrow',
      'lastMessageTime': DateTime.now().subtract(const Duration(hours: 3)),
    },
  ];

  final Map<String, List<ChatMessage>> _mockMessages = {
    'general': [
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user1',
        senderName: 'John Doe',
        content: 'Hello everyone! How are you doing?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user2',
        senderName: 'Jane Smith',
        content: 'I\'m doing great! Working on the math assignment.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ],
    'math': [
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user3',
        senderName: 'Mike Johnson',
        content: 'Did anyone solve problem 5 yet?',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user4',
        senderName: 'Sarah Williams',
        content: 'I got stuck on problem 5 too.',
        timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: true,
      ),
    ],
    'science': [
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user5',
        senderName: 'Alex Brown',
        content: 'Remember the lab report is due tomorrow!',
        timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: true,
      ),
    ],
  };

  MockChatService(this.currentUserId);

  @override
  Future<List<Map<String, dynamic>>> getChatRooms() async {
    await Future.delayed(
      const Duration(milliseconds: 300),
    ); // Simulate network delay
    return _mockRooms;
  }

  @override
  Future<int> getUnreadCountForRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    // Simple mock logic - general chat has 3 unread, others have 0
    return roomId == 'general' ? 3 : 0;
  }

  @override
  Future<void> markRoomAsRead(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // In a real implementation, we would mark messages as read here
  }

  @override
  Future<List<ChatMessage>> getMessagesForRoom(
    String roomId, {
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockMessages[roomId] ?? [];
  }

  @override
  Future<List<ChatMessage>> loadOlderMessages(
    String roomId,
    DateTime beforeTimestamp,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Return some older mock messages
    return [
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user6',
        senderName: 'Teacher',
        content: 'This is an older message from your teacher',
        timestamp: beforeTimestamp.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      ChatMessage(
        id: 1,
        roomId: 1,
        senderId: 'user7',
        senderName: 'Classmate',
        content: 'We had this discussion last week',
        timestamp: beforeTimestamp.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
  }

  @override
  Future<ChatMessage> sendMessage(String roomId, String content) async {
    await Future.delayed(const Duration(milliseconds: 200));

    final newMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      roomId: 1,
      senderId: currentUserId,
      senderName: 'You',
      content: content,
      timestamp: DateTime.now(),
      isRead: true,
    );

    // Add to our mock messages
    if (_mockMessages.containsKey(roomId)) {
      _mockMessages[roomId]!.insert(0, newMessage);
    } else {
      _mockMessages[roomId] = [newMessage];
    }

    // Update last message in room
    for (var room in _mockRooms) {
      if (room['id'] == roomId) {
        room['lastMessage'] = content;
        room['lastMessageTime'] = DateTime.now();
        break;
      }
    }

    return newMessage;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    // Find and remove the message from all rooms
    for (var roomMessages in _mockMessages.values) {
      roomMessages.removeWhere((message) => message.id == messageId);
    }
  }

  @override
  Stream<List<ChatMessage>> getMessageStream(String roomId) {
    // For a mock implementation, we'll just return an empty stream
    // In a real app, you'd connect this to your backend's real-time updates
    return Stream.empty();
  }
}
