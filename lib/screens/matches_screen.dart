import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/swipe_provider.dart';

class MatchesScreen extends ConsumerStatefulWidget {
  const MatchesScreen({super.key});

  @override
  ConsumerState<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends ConsumerState<MatchesScreen> {
  @override
  void initState() {
    super.initState();
    // Load matches history & incoming swipe requests
    Future.microtask(() {
      ref.read(chatNotifierProvider.notifier).loadMatchesAndChats();
      ref.read(swipeNotifierProvider.notifier).loadIncomingRequests();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider);
    final swipeState = ref.watch(swipeNotifierProvider);
    final incomingRequests = swipeState.incomingRequests;

    final apiBaseUrl = ref.watch(networkServiceProvider).dio.options.baseUrl;
    final currentUser = (ref.watch(authNotifierProvider) as AuthAuthenticated).user;
    final myUserId = currentUser['id'] as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Matches & Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(chatNotifierProvider.notifier).loadMatchesAndChats();
            await ref.read(swipeNotifierProvider.notifier).loadIncomingRequests();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Box
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Matches or Chats',
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryLight),
                    filled: true,
                    fillColor: AppTheme.surfaceDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Incoming User Requests Section (If Any)
                if (incomingRequests.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        'User Requests',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${incomingRequests.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 125,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: incomingRequests.length,
                      itemBuilder: (context, index) {
                        final req = incomingRequests[index];
                        final profile = req['profile'] as Map<String, dynamic>;
                        final likerId = req['likerId'] as String;
                        final photos = List<String>.from(profile['photos'] ?? []);
                        final photo = photos.isNotEmpty ? photos.first : '';
                        final isSuperLike = req['type'] == 'superlike';

                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          width: 85,
                          child: Column(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 62,
                                    height: 62,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSuperLike ? Colors.blueAccent : AppTheme.primaryPink,
                                        width: 2.5,
                                      ),
                                      image: photo.isNotEmpty
                                          ? DecorationImage(
                                              image: CachedNetworkImageProvider(
                                                photo.startsWith('/uploads/') ? '$apiBaseUrl$photo' : photo,
                                              ),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: photo.isEmpty
                                        ? const Icon(Icons.person, color: Colors.white54, size: 32)
                                        : null,
                                  ),
                                  if (isSuperLike)
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.blueAccent,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.star, color: Colors.white, size: 12),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                profile['displayName'] ?? 'User',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () async {
                                  await ref.read(swipeNotifierProvider.notifier).swipeRight(likerId);
                                  ref.read(swipeNotifierProvider.notifier).loadIncomingRequests();
                                  ref.read(chatNotifierProvider.notifier).loadMatchesAndChats();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryPink,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Match',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // New Matches Section
                Text(
                  'New Matches',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),
                
                chatState.matches.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: Text(
                          'No new matches yet. Keep swiping!',
                          style: TextStyle(color: AppTheme.textSecondaryLight),
                        ),
                      )
                    : SizedBox(
                        height: 110,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: chatState.matches.length,
                          itemBuilder: (context, index) {
                            final match = chatState.matches[index];
                            final profile = match['profile'];
                            final photos = List<String>.from(profile['photos'] ?? []);
                            final photo = photos.isNotEmpty ? photos.first : '';

                            return GestureDetector(
                              onTap: () {
                                ref.read(chatNotifierProvider.notifier).openChatRoom(match['chatRoomId']);
                                context.push('/chat/${match['chatRoomId']}', extra: profile);
                              },
                              child: Container(
                                margin: const EdgeInsets.only(right: 20),
                                width: 70,
                                child: Column(
                                  children: [
                                    Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: AppTheme.primaryPink, width: 2),
                                        image: DecorationImage(
                                          image: CachedNetworkImageProvider(
                                            photo.startsWith('/uploads/') ? '$apiBaseUrl$photo' : photo,
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      profile['displayName'] ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                const SizedBox(height: 32),

                // Active Messages Section
                Text(
                  'Messages',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 16),

                chatState.chats.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40.0),
                        child: Center(
                          child: Text(
                            'No active chats yet. Start swiping to match!',
                            style: TextStyle(color: AppTheme.textSecondaryLight),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: chatState.chats.length,
                        itemBuilder: (context, index) {
                          final chat = chatState.chats[index];
                          final profile = chat['profile'];
                          final photos = List<String>.from(profile['photos'] ?? []);
                          final photo = photos.isNotEmpty ? photos.first : '';
                          final latestMsg = chat['latestMessage'];

                          String previewText = 'No messages yet';
                          bool isUnread = false;

                          if (latestMsg != null) {
                            if (latestMsg['isDeletedForEveryone'] == true) {
                              previewText = 'This message was deleted';
                            } else {
                              final content = latestMsg['content'] as String? ?? '';
                              final attachments = latestMsg['attachments'] as List? ?? [];
                              
                              if (content.isNotEmpty) {
                                previewText = content;
                              } else if (attachments.isNotEmpty) {
                                final type = attachments.first['type'];
                                previewText = type == 'audio' ? '🎤 Voice message' : '📷 Photo';
                              }
                            }
                            
                            // Check seen status
                            final seenBy = List<String>.from(latestMsg['seenBy'] ?? []);
                            final senderId = latestMsg['sender'] as String? ?? '';
                            if (senderId != myUserId && !seenBy.contains(myUserId)) {
                              isUnread = true;
                            }
                          }

                          return GestureDetector(
                            onTap: () {
                              ref.read(chatNotifierProvider.notifier).openChatRoom(chat['chatRoomId']);
                              context.push('/chat/${chat.chatRoomId}', extra: profile);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  // User Photo
                                  Container(
                                    width: 55,
                                    height: 55,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      image: DecorationImage(
                                        image: CachedNetworkImageProvider(
                                          photo.startsWith('/uploads/') ? '$apiBaseUrl$photo' : photo,
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  
                                  // Chat Info Text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          profile['displayName'] ?? '',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          previewText,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isUnread ? Colors.white : AppTheme.textSecondaryLight,
                                            fontWeight: isUnread ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status Indicators
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isUnread)
                                        Container(
                                          width: 10,
                                          height: 10,
                                          decoration: const BoxDecoration(
                                            color: AppTheme.primaryPink,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
extension on Object {
  String get chatRoomId => (this as Map)['chatRoomId'] as String;
}
