import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/subscription_repository.dart';
import 'auth_provider.dart';
import 'profile_provider.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return SubscriptionRepositoryImpl(network);
});

class PurchaseState {
  final bool isLoading;
  final String? error;
  final bool success;

  PurchaseState({required this.isLoading, this.error, required this.success});
}

class PurchaseNotifier extends StateNotifier<PurchaseState> {
  final SubscriptionRepository _repository;
  final Ref _ref;

  PurchaseNotifier(this._repository, this._ref)
      : super(PurchaseState(isLoading: false, success: false));

  Future<void> purchase(String planName) async {
    state = PurchaseState(isLoading: true, success: false);
    try {
      final res = await _repository.purchaseSubscription(planName, 30);
      if (res['status'] == 'success') {
        state = PurchaseState(isLoading: false, success: true);
        // Refresh local user profile details to sync premium state
        _ref.read(profileNotifierProvider.notifier).loadProfile();
      } else {
        state = PurchaseState(isLoading: false, success: false, error: res['message']);
      }
    } catch (e) {
      state = PurchaseState(isLoading: false, success: false, error: e.toString());
    }
  }
}

final purchaseNotifierProvider = StateNotifierProvider<PurchaseNotifier, PurchaseState>((ref) {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return PurchaseNotifier(repository, ref);
});
