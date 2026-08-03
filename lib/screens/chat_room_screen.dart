import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String chatId;
  final Map<String, dynamic> recipientProfile;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.recipientProfile,
  });

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTypingLocal = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatNotifierProvider.notifier).openChatRoom(widget.chatId);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTypingLocal) {
      setState(() => _isTypingLocal = true);
      ref.read(chatNotifierProvider.notifier).emitTyping();
    } else if (text.isEmpty && _isTypingLocal) {
      setState(() => _isTypingLocal = false);
      ref.read(chatNotifierProvider.notifier).emitStopTyping();
    }
  }

  Future<void> _pickAttachment() async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 60);
      if (image != null && mounted) {
        ref.read(chatNotifierProvider.notifier).sendMessage(
              widget.chatId,
              attachmentPath: image.path,
            );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image Picker Error: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    ref.read(chatNotifierProvider.notifier).sendMessage(widget.chatId, content: content);
    _messageController.clear();
    setState(() => _isTypingLocal = false);
    ref.read(chatNotifierProvider.notifier).emitStopTyping();
  }

  void _onMessageLongPress(Map<String, dynamic> message, String myUserId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        final isMyMsg = message['sender']['_id'] == myUserId || message['sender'] == myUserId;
        
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Delete for Me'),
                onTap: () {
                  ref.read(chatNotifierProvider.notifier).deleteMessage(message['_id'], 'me', widget.chatId);
                  Navigator.of(context).pop();
                },
              ),
              if (isMyMsg && message['isDeletedForEveryone'] != true)
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                  title: const Text('Delete for Everyone'),
                  onTap: () {
                    ref.read(chatNotifierProvider.notifier).deleteMessage(message['_id'], 'everyone', widget.chatId);
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final apiBaseUrl = ref.watch(networkServiceProvider).dio.options.baseUrl;
    
    final currentUser = (ref.watch(authNotifierProvider) as AuthAuthenticated).user;
    final myUserId = currentUser['id'] as String;

    final messages = chatState.roomMessages[widget.chatId] ?? [];
    final otherUserPhotos = List<String>.from(widget.recipientProfile['photos'] ?? []);
    final otherUserPhoto = otherUserPhotos.isNotEmpty ? otherUserPhotos.first : '';

    ImageProvider? avatarImage;
    if (otherUserPhoto.isNotEmpty) {
      avatarImage = CachedNetworkImageProvider(
        otherUserPhoto.startsWith('/uploads/') ? '$apiBaseUrl$otherUserPhoto' : otherUserPhoto,
      );
    }

    final isTyping = chatState.typingRoomId == widget.chatId;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: avatarImage,
              child: avatarImage == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.recipientProfile['displayName'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  isTyping ? 'typing...' : 'Online',
                  style: TextStyle(
                    fontSize: 12, 
                    color: isTyping ? AppTheme.primaryPink : Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone),
            onPressed: () {
              // Agora Audio Call mapping in Module 6
              context.push('/call', extra: {
                'chatId': widget.chatId,
                'recipientId': widget.recipientProfile['user'] ?? '',
                'recipientName': widget.recipientProfile['displayName'] ?? '',
                'isVideo': false,
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.videocam),
            onPressed: () {
              // Agora Video Call mapping in Module 6
              context.push('/call', extra: {
                'chatId': widget.chatId,
                'recipientId': widget.recipientProfile['user'] ?? '',
                'recipientName': widget.recipientProfile['displayName'] ?? '',
                'isVideo': true,
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.all(16.0),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final msg = messages[index];
                  final senderObj = msg['sender'];
                  
                  final String senderId = senderObj is Map ? senderObj['_id'] as String : senderObj as String;
                  final isMe = senderId == myUserId;

                  final content = msg['content'] as String? ?? '';
                  final attachments = msg['attachments'] as List? ?? [];
                  final isDeleted = msg['isDeletedForEveryone'] == true;

                  final seenBy = List<String>.from(msg['seenBy'] ?? []);
                  final isSeen = seenBy.contains(widget.recipientProfile['user'] ?? '');

                  return Align(
                    alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: GestureDetector(
                      onLongPress: () => _onMessageLongPress(msg, myUserId),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe 
                              ? (isDeleted ? AppTheme.surfaceDark : AppTheme.primaryPink)
                              : AppTheme.surfaceDark,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                          ),
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Render image attachment if present
                            if (attachments.isNotEmpty && !isDeleted) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: attachments.first['url'].toString().startsWith('/uploads/')
                                      ? '$apiBaseUrl${attachments.first['url']}'
                                      : attachments.first['url'].toString(),
                                  placeholder: (context, url) => const SizedBox(
                                    width: 150,
                                    height: 150,
                                    child: Center(child: CircularProgressIndicator()),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            
                            // Text content
                            if (content.isNotEmpty)
                              Text(
                                content,
                                style: TextStyle(
                                  color: isDeleted ? AppTheme.textSecondaryLight : Colors.white,
                                  fontSize: 16,
                                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                                ),
                              ),

                            // State Ticks Indicator
                            if (isMe && !isDeleted) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Icon(
                                    Icons.done_all, 
                                    size: 14, 
                                    color: isSeen ? Colors.blueAccent : Colors.white60,
                                  ),
                                ],
                              )
                            ]
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // typing indicator bubble
            if (isTyping)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(left: 16, bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('typing...', style: TextStyle(color: AppTheme.textSecondaryLight, fontStyle: FontStyle.italic)),
                ),
              ),

            // Message bar
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: const BoxDecoration(
                color: AppTheme.surfaceDark,
                border: Border(top: BorderSide(color: Color(0xFF334155), width: 1)),
              ),
              child: Row(
                children: [
                  // Attachment trigger
                  IconButton(
                    icon: const Icon(Icons.add_photo_alternate, color: AppTheme.textSecondaryLight),
                    onPressed: _pickAttachment,
                  ),
                  
                  // Text input
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      onChanged: _onTextChanged,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  
                  // Send Button
                  IconButton(
                    icon: const Icon(Icons.send, color: AppTheme.primaryPink),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
