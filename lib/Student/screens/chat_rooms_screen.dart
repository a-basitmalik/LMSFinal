import 'package:flutter/material.dart';
import '../../Teacher/themes/theme_extensions.dart';
import '../../Teacher/themes/theme_colors.dart';
import '../../Teacher/themes/theme_text_styles.dart';
import '../services/api_service.dart';
import '../screens/chat_screen.dart';
import '../widgets/base_screen.dart';

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

      if (subjects == null || subjects.isEmpty) {
        setState(() {
          _chatRoomsFuture = Future.value([]);
          _isLoading = false;
        });
        return;
      }

      // Create rooms with unread counts
      final rooms = await Future.wait(subjects.map((subject) async {
        final unreadCount = await _apiService.getUnreadCount(
            widget.rfid, subject.id.toString());
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

      // Add general chat with its unread count
      final generalUnreadCount = await _apiService.getUnreadCount(
          widget.rfid, 'general');
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
      setState(() {
        _errorMessage = 'Failed to load chat rooms. Please try again.';
        _isLoading = false;
        _chatRoomsFuture = Future.value([]);
      });
    }
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
          'CHAT ROOMS',
          style: TeacherTextStyles.sectionHeader,
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: TeacherColors.primaryText),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(TeacherColors.primaryAccent),
        ),
      )
          : _errorMessage != null
          ? Center(
        child: Text(
          _errorMessage!,
          style: TeacherTextStyles.cardSubtitle.copyWith(
            color: TeacherColors.dangerAccent,
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadChatRooms,
        backgroundColor: TeacherColors.primaryAccent.withOpacity(0.2),
        color: TeacherColors.primaryAccent,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'General Chat',
                  style: TeacherTextStyles.sectionHeader,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _chatRoomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final generalRoom = snapshot.data!.firstWhere(
                              (room) => room['isGeneral']);
                      return _buildGeneralChatCard(
                          context, generalRoom);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Subject Chats',
                  style: TeacherTextStyles.sectionHeader,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _chatRoomsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final subjectRooms = snapshot.data!
                          .where((room) => !room['isGeneral'])
                          .toList();

                      if (subjectRooms.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'No subjects enrolled',
                            style: TeacherTextStyles.cardSubtitle,
                          ),
                        );
                      }

                      return Column(
                        children: subjectRooms
                            .map((room) => _buildSubjectChatCard(
                            context, room))
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

  Widget _buildGeneralChatCard(
      BuildContext context, Map<String, dynamic> generalRoom) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToChatScreen(context, generalRoom),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: TeacherColors.primaryAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: TeacherColors.primaryAccent.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.people,
                  color: TeacherColors.primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      generalRoom['name'],
                      style: TeacherTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      generalRoom['lastMessage'],
                      style: TeacherTextStyles.cardSubtitle,
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
                  decoration: BoxDecoration(
                    color: TeacherColors.dangerAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    generalRoom['unreadCount'].toString(),
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectChatCard(
      BuildContext context, Map<String, dynamic> room) {
    final colors = context.teacherColors;
    final textStyles = context.teacherTextStyles;
    final subjectColor = _getSubjectColor(room['subject']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: TeacherColors.glassDecoration(),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToChatScreen(context, room),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: subjectColor.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  room['subject'].toString().substring(0, 1),
                  style: TeacherTextStyles.cardTitle.copyWith(
                    color: subjectColor,
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
                      style: TeacherTextStyles.cardTitle,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${room['instructor']} • ${room['lastMessage']}',
                      style: TeacherTextStyles.cardSubtitle,
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
                  decoration: BoxDecoration(
                    color: TeacherColors.dangerAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    room['unreadCount'].toString(),
                    style: TeacherTextStyles.cardSubtitle.copyWith(
                      color: TeacherColors.primaryText,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subjectCode) {
    final prefix = subjectCode.length >= 3
        ? subjectCode.substring(0, 3)
        : subjectCode;

    final colors = {
      '11': TeacherColors.secondaryAccent,
      '17': TeacherColors.infoAccent,
      '18': TeacherColors.warningAccent,
      '19': TeacherColors.primaryAccent,
      '110': TeacherColors.successAccent,
      '111': TeacherColors.secondaryAccent,
      '119': TeacherColors.dangerAccent,
    };

    return colors[prefix] ?? TeacherColors.primaryAccent;
  }

  void _navigateToChatScreen(
      BuildContext context, Map<String, dynamic> room) {
    final subjectId = int.tryParse(room['id'].toString()) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserRfid: widget.rfid,
          subjectId: subjectId,
          roomName: room['name'].toString(),
        ),
      ),
    );
  }
}