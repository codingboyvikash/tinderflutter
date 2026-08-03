import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/subscription_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  double _distanceKm = 50.0;
  RangeValues _ageRange = const RangeValues(18, 35);
  bool _pushNotifications = true;
  bool _showMeOnTinder = true;
  bool _incognitoMode = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'name': 'plus',
      'title': 'Spark Plus',
      'price': '\$9.99/mo',
      'gradient': [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      'badge': 'ESSENTIAL',
      'features': [
        'Unlimited Swiping Likes',
        'Rewind Last Swipe (Undo)',
        'Passport to Any Location',
        'Hide Ads & Promotions',
      ],
    },
    {
      'name': 'gold',
      'title': 'Spark Gold',
      'price': '\$19.99/mo',
      'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      'badge': 'MOST POPULAR',
      'features': [
        'See Who Likes You First',
        '5 Free Super Likes / Day',
        '1 Free Profile Boost / Month',
        'Unlimited Swiping & Rewinds',
      ],
    },
    {
      'name': 'platinum',
      'title': 'Spark VIP',
      'price': '\$29.99/mo',
      'gradient': [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)],
      'badge': 'ULTIMATE',
      'features': [
        'Prioritized Likes to Recipient',
        'Message Before Match',
        'See Likes Sent in Real-Time',
        'All Gold & Plus Features',
      ],
    },
  ];

  void _buyPlan(String planName) {
    ref.read(purchaseNotifierProvider.notifier).purchase(planName);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);
    final authState = ref.watch(authNotifierProvider);
    final apiBaseUrl = ref.watch(networkServiceProvider).dio.options.baseUrl;

    ref.listen<PurchaseState>(purchaseNotifierProvider, (previous, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '🎉 Premium VIP Membership Activated! Enjoy Unlimited Perks.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${next.error}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    String currentPlanName = 'free';
    String displayName = 'User';
    String email = '';
    String photoUrl = '';
    bool isVerifiedBadge = false;

    if (profileState is ProfileLoaded) {
      final p = profileState.profile;
      displayName = p['displayName'] ?? 'User';
      isVerifiedBadge = p['verifiedBadge'] == true;
      final photos = List<String>.from(p['photos'] ?? []);
      if (photos.isNotEmpty) photoUrl = photos.first;

      if (p['isPremium'] == true) {
        currentPlanName = p['premiumType'] ?? 'gold';
      }
    }

    if (authState is AuthAuthenticated) {
      email = authState.user['email'] ?? '';
      if (displayName == 'User') {
        displayName = authState.user['name'] ?? email.split('@')[0];
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings & Profile',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. User Profile Quick Overview Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFF334155)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(50),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Profile Photo Avatar with Glow Border
                    Stack(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppTheme.primaryGradient,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(36),
                            child: photoUrl.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: photoUrl.startsWith('/uploads/')
                                        ? '$apiBaseUrl$photoUrl'
                                        : photoUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.white10),
                                    errorWidget: (context, url, err) =>
                                        const Icon(
                                          Icons.person,
                                          color: Colors.white70,
                                          size: 36,
                                        ),
                                  )
                                : Container(
                                    color: Colors.white10,
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white70,
                                      size: 36,
                                    ),
                                  ),
                          ),
                        ),
                        if (isVerifiedBadge)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.blueAccent,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),

                    // User Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerifiedBadge) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.blueAccent,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            email.isNotEmpty ? email : 'Signed in Account',
                            style: const TextStyle(
                              color: AppTheme.textSecondaryLight,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Edit Profile Button
                          GestureDetector(
                            onTap: () => context.push('/profile-setup'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Edit Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. VIP Subscription Premium Showcase Banner & Plans Carousel
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: currentPlanName != 'free'
                      ? AppTheme.premiumGradient
                      : const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withAlpha(80),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              color: Colors.white,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'SPARK VIP CLUB',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(80),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            currentPlanName.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      currentPlanName == 'free'
                          ? 'Get 5x More Matches!'
                          : 'VIP Membership Active 🎉',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentPlanName == 'free'
                          ? 'Unlock who likes you, unlimited rewinds, location passport & top profile placement.'
                          : 'Enjoy prioritized swiping, unlimited likes, and direct call connections.',
                      style: TextStyle(
                        color: Colors.white.withAlpha(220),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Plans Carousel (If Free or Upgrading)
              if (currentPlanName == 'free') ...[
                const Text(
                  'Choose Premium Tier',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  height: 275,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      final List<Color> bgGradient = plan['gradient'];

                      return Container(
                        width: 340,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: bgGradient.first.withAlpha(120),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: bgGradient.first.withAlpha(40),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: bgGradient,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    plan['badge'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                                Text(
                                  plan['price'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: bgGradient.first,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              plan['title'],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Feature Bullet Points
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: (plan['features'] as List<String>)
                                    .map(
                                      (f) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 5.0,
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              color: bgGradient.first,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                f,
                                                style: const TextStyle(
                                                  fontSize: 11.5,
                                                  color: AppTheme
                                                      .textSecondaryLight,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Subscribe Button
                            GestureDetector(
                              onTap: purchaseState.isLoading
                                  ? null
                                  : () => _buyPlan(plan['name']),
                              child: Container(
                                width: double.infinity,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(colors: bgGradient),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: purchaseState.isLoading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text(
                                          'SUBSCRIBE NOW',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],

              // 3. Discovery & Matching Preferences Controls
              _buildSectionTitle('DISCOVERY PREFERENCES'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    // Distance Radius Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Maximum Distance',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_distanceKm.round()} km',
                          style: const TextStyle(
                            color: AppTheme.primaryPink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _distanceKm,
                      min: 1.0,
                      max: 150.0,
                      activeColor: AppTheme.primaryPink,
                      inactiveColor: Colors.white12,
                      onChanged: (val) => setState(() => _distanceKm = val),
                    ),
                    const Divider(color: Color(0xFF334155)),

                    // Age Filter Range Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Age Range',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${_ageRange.start.round()} - ${_ageRange.end.round()}',
                          style: const TextStyle(
                            color: AppTheme.primaryPink,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18.0,
                      max: 65.0,
                      activeColor: AppTheme.primaryPink,
                      inactiveColor: Colors.white12,
                      onChanged: (val) => setState(() => _ageRange = val),
                    ),
                    const Divider(color: Color(0xFF334155)),

                    // Show Me On Discovery Toggle
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Show Me on Discovery',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Turn off to hide your profile card from swiping feed.',
                        style: TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      value: _showMeOnTinder,
                      activeColor: AppTheme.primaryPink,
                      onChanged: (val) => setState(() => _showMeOnTinder = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 4. Privacy & Notifications Settings
              _buildSectionTitle('NOTIFICATIONS & PRIVACY'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text(
                        'Push Notifications',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Receive alerts for new matches & messages',
                        style: TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      value: _pushNotifications,
                      activeColor: AppTheme.primaryPink,
                      onChanged: (val) =>
                          setState(() => _pushNotifications = val),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    SwitchListTile(
                      title: const Text(
                        'Incognito Ghost Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'Only show profile to people you have liked',
                        style: TextStyle(
                          color: AppTheme.textSecondaryLight,
                          fontSize: 12,
                        ),
                      ),
                      value: _incognitoMode,
                      activeColor: AppTheme.accentPurple,
                      onChanged: (val) => setState(() => _incognitoMode = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 5. Account Actions & Logout
              _buildSectionTitle('ACCOUNT CONTROLS'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.security,
                        color: Colors.blueAccent,
                      ),
                      title: const Text(
                        'Account Security & Verification',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.textSecondaryLight,
                      ),
                      onTap: () => context.push('/profile-setup'),
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.help_outline,
                        color: Colors.amber,
                      ),
                      title: const Text(
                        'Help Center & Safety Guidelines',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppTheme.textSecondaryLight,
                      ),
                      onTap: () {},
                    ),
                    const Divider(color: Color(0xFF334155), height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.logout,
                        color: Colors.redAccent,
                      ),
                      title: const Text(
                        'Logout Session',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.redAccent,
                      ),
                      onTap: () {
                        _showLogoutConfirmationDialog(context);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Footer Version Info
              const Center(
                child: Column(
                  children: [
                    Text(
                      'Spark Tinder App v2.4.0',
                      style: TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Powered by Node.js & Flutter Engine',
                      style: TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondaryLight,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.2,
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout Session?',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to log out of your account?',
          style: TextStyle(color: AppTheme.textSecondaryLight),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(100, 40),
            ),
            onPressed: () {
              Navigator.pop(context);
              ref.read(authNotifierProvider.notifier).logout();
              context.go('/onboarding');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
