// lib/screens/chat_rooms_screen.dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../screens/chat_screen.dart';
import '../utils/app_design_system.dart';
import '../widgets/base_screen.dart';
import '../utils/theme.dart';

class ChatRoomsScreen extends StatefulWidget {
  final String rfid;

  const ChatRoomsScreen({super.key, required this.rfid});

  @override
  State<ChatRoomsScreen> createState() => _ChatRoomsScreenState();
}

class _ChatRoomsScreenState extends State<ChatRoomsScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _chatRoomsFuture;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadChatRooms();
  }

  Future<void> _loadChatRooms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final subjects = await _apiService.getSubjectsByStudentRfid(widget.rfid);
      print('API Response Subjects: $subjects');

      if (subjects == null || subjects.isEmpty) {
        print('No subjects received from API');
        setState(() {
          _chatRoomsFuture = Future.value([]);
          _isLoading = false;
        });
        return;
      }

      // Create rooms with unread counts
      final rooms = await Future.wait(subjects.map((subject) async {
        final unreadCount = await _apiService.getUnreadCount(widget.rfid, subject.id.toString());
        print('Unread count for ${subject.name}: $unreadCount');

        return {
          'id': subject.id,
          'name': subject.name,
          'subject': subject.code.toString(),
          'unreadCount': unreadCount,
          'lastMessage': 'Tap to start chatting',
          'isGeneral': false,
          'instructor': subject.instructor,
        };
      }));

      print('Created rooms: $rooms');

      // Add general chat with its unread count
      final generalUnreadCount = await _apiService.getUnreadCount(widget.rfid, 'general');
      rooms.insert(0, {
        'id': 'general',
        'name': 'General Chat',
        'subject': 'General',
        'unreadCount': generalUnreadCount,
        'lastMessage': 'Hello everyone!',
        'isGeneral': true,
        'instructor': 'All Students',
      });

      setState(() {
        _chatRoomsFuture = Future.value(rooms);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading chat rooms: $e');
      setState(() {
        _errorMessage = 'Failed to load chat rooms. Please try again.';
        _isLoading = false;
        _chatRoomsFuture = Future.value([]);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Chat Rooms',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : RefreshIndicator(
        onRefresh: _loadChatRooms,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppDesignSystem.sectionHeader(context, 'General Chat'),
              Padding(
                padding: AppDesignSystem.sectionPadding,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _chatRoomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final generalRoom = snapshot.data!
                          .firstWhere((room) => room['isGeneral']);
                      return _buildGeneralChatCard(context, generalRoom);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              AppDesignSystem.sectionHeader(context, 'Subject Chats'),
              Padding(
                padding: AppDesignSystem.sectionPadding,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _chatRoomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final subjectRooms = snapshot.data!
                          .where((room) => !room['isGeneral'])
                          .toList();

                      if (subjectRooms.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No subjects enrolled'),
                        );
                      }

                      return Column(
                        children: subjectRooms
                            .map((room) => _buildSubjectChatCard(context, room))
                            .toList(),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralChatCard(BuildContext context, Map<String, dynamic> generalRoom) {
    return AppDesignSystem.card(
      context: context,
      onTap: () => _navigateToChatScreen(context, generalRoom),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.people, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  generalRoom['name'],
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  generalRoom['lastMessage'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (generalRoom['unreadCount'] > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.accentPink,
                shape: BoxShape.circle,
              ),
              child: Text(
                generalRoom['unreadCount'].toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubjectChatCard(
      BuildContext context,
      Map<String, dynamic> room,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AppDesignSystem.card(
        context: context,
        onTap: () => _navigateToChatScreen(context, room),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getSubjectColor(room['subject']),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                room['subject'].toString().substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room['name'],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${room['instructor']} • ${room['lastMessage']}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (room['unreadCount'] > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.accentPink,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  room['unreadCount'].toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String subjectCode) {
    final prefix = subjectCode.length >= 3 ? subjectCode.substring(0, 3) : subjectCode;

    final colors = {
      '11': AppColors.secondary,
      '17': AppColors.accentBlue,
      '18': AppColors.accentAmber,
      '19': AppColors.primaryLight,
      '110': AppColors.darkSurface,
      '111': AppColors.darkSecondary,
      '119': AppColors.darkPrimary,
    };

    return colors[prefix] ?? AppColors.primary;
  }

  void _navigateToChatScreen(BuildContext context, Map<String, dynamic> room) {
    final subjectId = int.tryParse(room['id'].toString()) ?? 0;

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => ChatScreen(
          currentUserRfid: widget.rfid,
          subjectId: subjectId,
          roomName: room['name'].toString(),
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}