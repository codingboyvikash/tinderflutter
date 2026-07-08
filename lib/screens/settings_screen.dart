import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  final List<Map<String, String>> _plans = [
    {
      'name': 'plus',
      'title': 'Tinder Plus',
      'benefits': 'Unlimited Likes • Undo Swipes • Passport to any location',
      'price': '\$9.99/mo',
    },
    {
      'name': 'gold',
      'title': 'Tinder Gold',
      'benefits': 'See Who Likes You • 5 Super Likes/day • 1 Free Boost/mo',
      'price': '\$19.99/mo',
    },
    {
      'name': 'platinum',
      'title': 'Tinder Platinum',
      'benefits': 'Message Before Match • Prioritized Likes • See Likes Sent',
      'price': '\$29.99/mo',
    },
  ];

  void _buyPlan(String planName) {
    ref.read(purchaseNotifierProvider.notifier).purchase(planName);
  }

  @override
  Widget build(BuildContext context) {
    final purchaseState = ref.watch(purchaseNotifierProvider);
    final profileState = ref.watch(profileNotifierProvider);

    // Watch purchase success to show alerts
    ref.listen<PurchaseState>(purchaseNotifierProvider, (previous, next) {
      if (next.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Premium membership activated successfully! 🎉'), backgroundColor: Colors.green),
        );
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchase failed: ${next.error}'), backgroundColor: Colors.redAccent),
        );
      }
    });

    String currentPlanName = 'free';
    if (profileState is ProfileLoaded) {
      final isPremium = profileState.profile['isPremium'] == true;
      if (isPremium) {
        currentPlanName = profileState.profile['premiumType'] ?? 'plus';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium subscription banner header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.premiumGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withAlpha(102),
                      blurRadius: 12,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'PREMIUM ENTITLEMENTS',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
                          child: Text(
                            currentPlanName.toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentPlanName == 'free' 
                          ? 'Unlock Premium Sparks'
                          : 'You are currently Premium!',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      currentPlanName == 'free'
                          ? 'Get access to unlimited likes, custom search filters, rewinds, and call signaling.'
                          : 'Thank you for supporting us. Feel free to switch plans below.',
                      style: TextStyle(color: Colors.white.withAlpha(204), fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Plans listing selector
              if (currentPlanName == 'free') ...[
                Text('Select Plan', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _plans.length,
                    itemBuilder: (context, index) {
                      final plan = _plans[index];
                      return Container(
                        width: 220,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF334155)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  plan['title']!,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  plan['price']!,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.primaryPink, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Text(
                                plan['benefits']!,
                                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryLight, height: 1.4),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: purchaseState.isLoading ? null : () => _buyPlan(plan['name']!),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 38),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: purchaseState.isLoading 
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Subscribe', style: TextStyle(fontSize: 12)),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 36),
              ],

              // Settings Items List
              Text('Account Settings', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              // Edit profile setup shortcut
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.white70),
                title: const Text('Edit Profile details'),
                trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryLight),
                onTap: () => context.push('/profile-setup'),
              ),
              const Divider(color: Color(0xFF334155)),

              // Logout list option
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Logout Session', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  ref.read(authNotifierProvider.notifier).logout();
                  context.go('/onboarding');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
