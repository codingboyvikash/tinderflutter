import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../providers/swipe_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  
  double _filterDistance = 50.0;
  RangeValues _filterAgeRange = const RangeValues(18, 50);
  String _filterGender = 'female';
  final TextEditingController _religionFilterController = TextEditingController();
  final TextEditingController _educationFilterController = TextEditingController();
  final TextEditingController _professionFilterController = TextEditingController();

  @override
  void dispose() {
    _swiperController.dispose();
    _religionFilterController.dispose();
    _educationFilterController.dispose();
    _professionFilterController.dispose();
    super.dispose();
  }

  void _onSwipeDetected(int index, CardSwiperDirection direction, List<Map<String, dynamic>> profiles) {
    if (index >= profiles.length) return;
    
    final targetProfile = profiles[index];
    final targetUserId = targetProfile['user']['_id'] as String;

    if (direction == CardSwiperDirection.right) {
      ref.read(swipeNotifierProvider.notifier).swipeRight(targetUserId);
    } else if (direction == CardSwiperDirection.left) {
      ref.read(swipeNotifierProvider.notifier).swipeLeft(targetUserId);
    } else if (direction == CardSwiperDirection.top) {
      ref.read(swipeNotifierProvider.notifier).superLike(targetUserId);
    }
  }

  void _showMatchDialog(BuildContext context, Map<String, dynamic> lastMatch, String myPhoto, String apiBaseUrl) {
    final targetProfile = lastMatch['profile'];
    final targetPhotos = List<String>.from(targetProfile['photos'] ?? []);
    final targetPhoto = targetPhotos.isNotEmpty ? targetPhotos.first : '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(229), // 90% opacity
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.favorite, color: AppTheme.primaryPink, size: 80),
                const SizedBox(height: 16),
                Text(
                  'It\'s a Match!',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You and ${targetProfile['displayName']} liked each other.',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 48),

                // Match Avatars Comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // My Avatar
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            myPhoto.startsWith('/uploads/') ? '$apiBaseUrl$myPhoto' : myPhoto,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Matched User Avatar
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(
                            targetPhoto.startsWith('/uploads/') ? '$apiBaseUrl$targetPhoto' : targetPhoto,
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 64),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(swipeNotifierProvider.notifier).clearMatch();
                      // Redirect to Chat Room in Module 5
                      context.go('/matches');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryPink,
                      minimumSize: const Size(double.infinity, 56),
                    ),
                    child: const Text('Send Message'),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ref.read(swipeNotifierProvider.notifier).clearMatch();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      side: const BorderSide(color: Colors.white70),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Keep Swiping'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Discovery Filters', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 24),

                    // Distance Filter
                    Text('Maximum Distance: ${_filterDistance.toInt()} km', style: const TextStyle(fontSize: 16)),
                    Slider(
                      value: _filterDistance,
                      min: 1,
                      max: 100,
                      activeColor: AppTheme.primaryPink,
                      onChanged: (val) {
                        setSheetState(() => _filterDistance = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Age Filter Range
                    Text('Age Range: ${_filterAgeRange.start.toInt()} - ${_filterAgeRange.end.toInt()}', style: const TextStyle(fontSize: 16)),
                    RangeSlider(
                      values: _filterAgeRange,
                      min: 18,
                      max: 80,
                      activeColor: AppTheme.primaryPink,
                      onChanged: (val) {
                        setSheetState(() => _filterAgeRange = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Gender Preference Selection
                    const Text('Gender Preference', style: TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Male'),
                          selected: _filterGender == 'male',
                          onSelected: (selected) {
                            if (selected) setSheetState(() => _filterGender = 'male');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Female'),
                          selected: _filterGender == 'female',
                          onSelected: (selected) {
                            if (selected) setSheetState(() => _filterGender = 'female');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Everyone'),
                          selected: _filterGender == 'everyone',
                          onSelected: (selected) {
                            if (selected) setSheetState(() => _filterGender = 'everyone');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Religion Filter
                    TextField(
                      controller: _religionFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Religion Filter',
                        hintText: 'e.g. Christian, Hindu, None',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Education Filter
                    TextField(
                      controller: _educationFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Education Keywords',
                        hintText: 'e.g. Stanford University',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Profession Filter
                    TextField(
                      controller: _professionFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Profession Keywords',
                        hintText: 'e.g. Engineer, Doctor',
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Apply Button
                    ElevatedButton(
                      onPressed: () {
                        final filterMap = <String, dynamic>{
                          'distance': _filterDistance.toInt(),
                          'minAge': _filterAgeRange.start.toInt(),
                          'maxAge': _filterAgeRange.end.toInt(),
                          'gender': _filterGender,
                        };
                        if (_religionFilterController.text.trim().isNotEmpty) {
                          filterMap['religion'] = _religionFilterController.text.trim();
                        }
                        if (_educationFilterController.text.trim().isNotEmpty) {
                          filterMap['education'] = _educationFilterController.text.trim();
                        }
                        if (_professionFilterController.text.trim().isNotEmpty) {
                          filterMap['profession'] = _professionFilterController.text.trim();
                        }

                        ref.read(swipeNotifierProvider.notifier).loadFeed(filters: filterMap);
                        Navigator.of(context).pop();
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final swipeState = ref.watch(swipeNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final apiBaseUrl = ref.watch(networkServiceProvider).dio.options.baseUrl;

    // Fetch my photo for match overlay comparison
    String myPhoto = '';
    if (profileState is ProfileLoaded) {
      final myPhotos = List<String>.from(profileState.profile['photos'] ?? []);
      if (myPhotos.isNotEmpty) myPhoto = myPhotos.first;
    }

    // Trigger match overlay check
    if (swipeState.lastMatch != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showMatchDialog(context, swipeState.lastMatch!, myPhoto, apiBaseUrl);
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.person, color: AppTheme.textSecondaryLight),
          onPressed: () => context.push('/settings'),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite, color: AppTheme.primaryPink, size: 24),
            const SizedBox(width: 4),
            Text(
              'spark',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primaryPink,
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: -0.5,
                  ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppTheme.textSecondaryLight),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.textSecondaryLight),
            // Match History and Chats redirect in Module 5
            onPressed: () => context.push('/matches'),
          )
        ],
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: swipeState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : swipeState.profiles.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_searching, size: 70, color: AppTheme.textSecondaryLight),
                          const SizedBox(height: 24),
                          Text(
                            'No Matches Near You',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'You have swiped on everyone in your distance preference. Expand your range or check back later!',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: () => ref.read(swipeNotifierProvider.notifier).loadFeed(),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh Discovery'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(200, 56),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : Column(
                    children: [
                      // Swiper Stack View
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: CardSwiper(
                            controller: _swiperController,
                            cardsCount: swipeState.profiles.length,
                            numberOfCardsDisplayed: swipeState.profiles.length.clamp(1, 2),
                            cardBuilder: (context, index, percentX, percentY) {
                              final profile = swipeState.profiles[index];
                              final photos = List<String>.from(profile['photos'] ?? []);
                              final photo = photos.isNotEmpty ? photos.first : '';
                              
                              return Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(51),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // Profile Image
                                    CachedNetworkImage(
                                      imageUrl: photo.startsWith('/uploads/') ? '$apiBaseUrl$photo' : photo,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                      errorWidget: (context, url, error) => Container(
                                        color: AppTheme.surfaceDark,
                                        child: const Icon(Icons.person, size: 80, color: Colors.white30),
                                      ),
                                    ),
                                    // Gradient Cover overlay
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.transparent,
                                            Colors.black.withAlpha(204),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    // Details Text info overlay
                                    Positioned(
                                      bottom: 24,
                                      left: 24,
                                      right: 24,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${profile['displayName']}, ${profile['age'] ?? ""}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              if (profile['verifiedBadge'] == true)
                                                const Icon(Icons.verified, color: Colors.blue, size: 24),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Colors.green,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Text('Online', style: TextStyle(color: Colors.green, fontSize: 13)),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.location_on, color: Colors.white70, size: 14),
                                              const SizedBox(width: 4),
                                              const Text('Nearby', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            profile['bio'] ?? 'No bio provided',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onSwipe: (previousIndex, currentIndex, direction) {
                              _onSwipeDetected(previousIndex, direction, swipeState.profiles);
                              return true;
                            },
                          ),
                        ),
                      ),

                      // Swipe Actions Toolbar Control
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Undo
                            FloatingActionButton(
                              heroTag: 'undo',
                              onPressed: () => ref.read(swipeNotifierProvider.notifier).undo(),
                              backgroundColor: AppTheme.surfaceDark,
                              elevation: 2,
                              child: const Icon(Icons.replay, color: Color(0xFFF59E0B)),
                            ),
                            const SizedBox(width: 20),
                            // PASS Left
                            FloatingActionButton.large(
                              heroTag: 'pass',
                              onPressed: () => _swiperController.swipe(CardSwiperDirection.left),
                              backgroundColor: AppTheme.surfaceDark,
                              elevation: 4,
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 36),
                            ),
                            const SizedBox(width: 16),
                            // LIKE Right
                            FloatingActionButton.large(
                              heroTag: 'like',
                              onPressed: () => _swiperController.swipe(CardSwiperDirection.right),
                              backgroundColor: AppTheme.surfaceDark,
                              elevation: 4,
                              child: const Icon(Icons.favorite, color: Colors.green, size: 36),
                            ),
                            const SizedBox(width: 20),
                            // Superlike Up
                            FloatingActionButton(
                              heroTag: 'superlike',
                              onPressed: () => _swiperController.swipe(CardSwiperDirection.top),
                              backgroundColor: AppTheme.surfaceDark,
                              elevation: 2,
                              child: const Icon(Icons.star, color: Colors.blueAccent),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
      ),
    );
  }
}
