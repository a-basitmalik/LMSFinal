// services/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/assignment_model.dart';
import '../models/query_model.dart';
import '../models/subject_model.dart';
import 'package:newapp/Student/models/chat_message_model.dart';
class ApiService {
  final String baseUrl = 'http://193.203.162.232:5050';

  Future<List<Subject>> getSubjectsByStudentRfid(String rfid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/subject/api/students/$rfid/subjects'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);

        // Extract subjects from the 'subjects' key
        final List<dynamic> subjectsList = responseData['subjects'] ?? [];

        return subjectsList.map((json) => Subject.fromJson(json)).toList();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load subjects: $e');
    }
  }
// Add these to your ApiService class
  Future<List<ChatMessage>> getMessagesByRoomId(int roomId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);

        // Handle both array and object responses
        final List<dynamic> messagesData = responseData is List
            ? responseData
            : (responseData['messages'] ?? responseData['data'] ?? []);

        return messagesData.map<ChatMessage>((json) {
          try {
            return ChatMessage.fromJson(json);
          } catch (e) {
            print('Error parsing message: $e\nJSON: $json');
            return ChatMessage(
              id: 0,
              roomId: roomId,
              senderId: 'unknown',
              senderName: 'Unknown',
              content: 'Failed to load message',
              timestamp: DateTime.now(),
              isRead: false,
            );
          }
        }).toList();
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to fetch messages: $e');
    }
  }

  Future<int> getOrCreateChatRoom(int subjectId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'subject_id': subjectId}),
      );

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Handle different response formats
        final roomId = data is Map ? (data['room_id'] ?? data['id']) : data;

        // Convert to int safely
        final parsedRoomId = int.tryParse(roomId.toString());
        if (parsedRoomId == null) {
          throw Exception('Invalid room ID format: $roomId');
        }
        return parsedRoomId;
      } else {
        throw Exception('Failed to get/create chat room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create chat room: $e');
    }
  }

  Future<void> sendMessage({
    required int roomId,
    required String senderRfid,
    required String messageText,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/messages'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'room_id': roomId,
        'sender_rfid': senderRfid,
        'message_text': messageText,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }
  }

  Future<void> markMessagesAsRead({
    required List<int> messageIds,
    required String readerRfid,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/read-receipts'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message_ids': messageIds,
        'reader_rfid': readerRfid,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark messages as read');
    }
  }

  Future<void> clearChatHistory(int roomId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/chat/rooms/$roomId/messages'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear chat history');
    }
  }

  Future<int> getUnreadCount(String rfid, String subjectId) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/unread-count')
          .replace(queryParameters: {'rfid': rfid, 'subjectId': subjectId});

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        throw Exception('Failed to fetch unread count: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching unread count: $e');
      return 0;
    }
  }

  Future<Map<int, List<String>>> getMessageReaders(List<int> messageIds) async {
    try {
      final uri = Uri.parse('$baseUrl/chat/message-readers');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'message_ids': messageIds}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final Map<String, dynamic> readers = data['readers'] ?? {};

        return readers.map<int, List<String>>((key, value) {
          return MapEntry(int.parse(key), List<String>.from(value));
        });
      } else {
        throw Exception('Failed to fetch message readers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching message readers: $e');
      return {};
    }
  }


  Future<List<Query>> getQueries(String studentRfid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/queries/get_queries?student_id=$studentRfid'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Query.fromJson(json)).toList();
      }
      throw Exception('Failed to load queries');
    } catch (e) {
      throw Exception('Error fetching queries: $e');
    }
  }

  Future<Query> submitQuery({
    required String subjectId,
    required String question,
    required String studentRfid
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/queries/submit_query'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'student_id': studentRfid,
          'subject_id': subjectId,
          'question': question,
        }),
      );
      if (response.statusCode == 201) {
        return Query.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to submit query');
    } catch (e) {
      throw Exception('Error submitting query: $e');
    }
  }



  Future<List<Assignment>> getAssignments(String studentRfid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/assignments/get_assignment?student_rfid=$studentRfid'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Assignment.fromJson(json)).toList();
      }
      throw Exception('Failed to load assignments');
    } catch (e) {
      throw Exception('Error fetching assignments: $e');
    }
  }

  Future<Assignment> submitAssignment({
    required int assignmentId,
    required String fileName,
    required String filePath,
    required String studentRfid
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/assignments/submit'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'assignment_id': assignmentId,
          'student_rfid': studentRfid,
          'file_name': fileName,
          'file_path': filePath,
        }),
      );
      if (response.statusCode == 201) {
        return Assignment.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to submit assignment');
    } catch (e) {
      throw Exception('Error submitting assignment: $e');
    }
  }
  Future<void> updateAssignmentStatus({
    required int assignmentId,
    required String status,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/assignments/$assignmentId/status'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': status}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update assignment status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating assignment status: $e');
    }
  }
}

