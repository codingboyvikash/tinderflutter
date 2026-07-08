import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/chat_repository.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return ChatRepositoryImpl(network);
});

class ChatState {
  final List<Map<String, dynamic>> matches;
  final List<Map<String, dynamic>> chats;
  final Map<String, List<Map<String, dynamic>>> roomMessages;
  final bool isLoading;
  final String? activeRoomId;
  final String? typingRoomId;

  ChatState({
    required this.matches,
    required this.chats,
    required this.roomMessages,
    required this.isLoading,
    this.activeRoomId,
    this.typingRoomId,
  });

  ChatState copyWith({
    List<Map<String, dynamic>>? matches,
    List<Map<String, dynamic>>? chats,
    Map<String, List<Map<String, dynamic>>>? roomMessages,
    bool? isLoading,
    String? activeRoomId,
    String? typingRoomId,
  }) {
    return ChatState(
      matches: matches ?? this.matches,
      chats: chats ?? this.chats,
      roomMessages: roomMessages ?? this.roomMessages,
      isLoading: isLoading ?? this.isLoading,
      activeRoomId: activeRoomId ?? this.activeRoomId,
      typingRoomId: typingRoomId ?? this.typingRoomId,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ChatRepository _repository;
  final SocketService _socketService;
  final Ref _ref;

  ChatNotifier(this._repository, this._socketService, this._ref)
      : super(ChatState(matches: [], chats: [], roomMessages: {}, isLoading: false)) {
    
    // Automatically setup socket and sync history on authentication
    _ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        _socketService.connect(next.user);
        _setupSocketListeners();
        loadMatchesAndChats();
      } else {
        _socketService.disconnect();
        state = ChatState(matches: [], chats: [], roomMessages: {}, isLoading: false);
      }
    });
  }

  void _setupSocketListeners() {
    final socket = _socketService.socket;
    if (socket == null) return;

    socket.on('message_received', (data) {
      final message = Map<String, dynamic>.from(data);
      final roomId = message['chatRoom'] as String;

      // Append message to memory room if loaded
      final currentRoomMsgs = List<Map<String, dynamic>>.from(state.roomMessages[roomId] ?? []);
      
      // Avoid duplicates
      if (!currentRoomMsgs.any((m) => m['_id'] == message['_id'])) {
        currentRoomMsgs.insert(0, message);
        final updatedRoomMsgs = Map<String, List<Map<String, dynamic>>>.from(state.roomMessages);
        updatedRoomMsgs[roomId] = currentRoomMsgs;
        state = state.copyWith(roomMessages: updatedRoomMsgs);
      }

      // Automatically refresh active chats history to update the latestMessage text
      loadMatchesAndChats();
    });

    socket.on('typing', (room) {
      if (room == state.activeRoomId) {
        state = state.copyWith(typingRoomId: room as String);
      }
    });

    socket.on('stop_typing', (room) {
      if (room == state.activeRoomId) {
        state = state.copyWith(typingRoomId: null);
      }
    });
  }

  Future<void> loadMatchesAndChats() async {
    try {
      final data = await _repository.getMatchesAndChats();
      final List matchesList = data['matches'] ?? [];
      final List chatsList = data['chats'] ?? [];

      state = state.copyWith(
        matches: matchesList.map((m) => m as Map<String, dynamic>).toList(),
        chats: chatsList.map((c) => c as Map<String, dynamic>).toList(),
      );
    } catch (e) {
      print('Load Matches and Chats error: $e');
    }
  }

  Future<void> openChatRoom(String roomId) async {
    state = state.copyWith(activeRoomId: roomId, typingRoomId: null);
    _socketService.joinChat(roomId);
    await loadMessages(roomId);
  }

  Future<void> loadMessages(String roomId, {int page = 1}) async {
    try {
      final messages = await _repository.getMessages(roomId, page: page);
      
      final updatedRoomMsgs = Map<String, List<Map<String, dynamic>>>.from(state.roomMessages);
      if (page == 1) {
        updatedRoomMsgs[roomId] = messages;
      } else {
        final current = updatedRoomMsgs[roomId] ?? [];
        updatedRoomMsgs[roomId] = [...current, ...messages];
      }
      
      state = state.copyWith(roomMessages: updatedRoomMsgs);
    } catch (e) {
      print('Load Messages error: $e');
    }
  }

  Future<void> sendMessage(String roomId, {String? content, String? attachmentPath, String? replyToId}) async {
    try {
      final message = await _repository.sendMessage(
        roomId,
        content: content,
        attachmentPath: attachmentPath,
        replyToId: replyToId,
      );

      // Append local message optimistically
      final currentRoomMsgs = List<Map<String, dynamic>>.from(state.roomMessages[roomId] ?? []);
      currentRoomMsgs.insert(0, message);

      final updatedRoomMsgs = Map<String, List<Map<String, dynamic>>>.from(state.roomMessages);
      updatedRoomMsgs[roomId] = currentRoomMsgs;
      state = state.copyWith(roomMessages: updatedRoomMsgs);

      // Refresh chats list to update preview
      loadMatchesAndChats();
    } catch (e) {
      print('Send Message error: $e');
    }
  }

  Future<void> deleteMessage(String messageId, String action, String roomId) async {
    try {
      final updatedMsg = await _repository.deleteMessage(messageId, action);
      
      final currentRoomMsgs = List<Map<String, dynamic>>.from(state.roomMessages[roomId] ?? []);
      final msgIndex = currentRoomMsgs.indexWhere((m) => m['_id'] == messageId);
      
      if (msgIndex != -1) {
        if (action == 'everyone') {
          currentRoomMsgs[msgIndex] = updatedMsg;
        } else {
          currentRoomMsgs.removeAt(msgIndex);
        }
        final updatedRoomMsgs = Map<String, List<Map<String, dynamic>>>.from(state.roomMessages);
        updatedRoomMsgs[roomId] = currentRoomMsgs;
        state = state.copyWith(roomMessages: updatedRoomMsgs);
      }
    } catch (e) {
      print('Delete Message error: $e');
    }
  }

  void emitTyping() {
    if (state.activeRoomId != null) {
      _socketService.sendTyping(state.activeRoomId!);
    }
  }

  void emitStopTyping() {
    if (state.activeRoomId != null) {
      _socketService.stopTyping(state.activeRoomId!);
    }
  }
}

final chatNotifierProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final repository = ref.watch(chatRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  return ChatNotifier(repository, socketService, ref);
});
