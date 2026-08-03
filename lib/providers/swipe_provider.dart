import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/swipe_repository.dart';
import 'auth_provider.dart';

final swipeRepositoryProvider = Provider<SwipeRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return SwipeRepositoryImpl(network);
});

class SwipeState {
  final List<Map<String, dynamic>> profiles;
  final List<Map<String, dynamic>> incomingRequests;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, dynamic>? lastMatch;

  SwipeState({
    required this.profiles,
    this.incomingRequests = const [],
    required this.isLoading,
    this.errorMessage,
    this.lastMatch,
  });

  SwipeState copyWith({
    List<Map<String, dynamic>>? profiles,
    List<Map<String, dynamic>>? incomingRequests,
    bool? isLoading,
    String? errorMessage,
    Map<String, dynamic>? lastMatch,
  }) {
    return SwipeState(
      profiles: profiles ?? this.profiles,
      incomingRequests: incomingRequests ?? this.incomingRequests,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      lastMatch: lastMatch ?? this.lastMatch,
    );
  }
}

class SwipeNotifier extends StateNotifier<SwipeState> {
  final SwipeRepository _repository;

  SwipeNotifier(this._repository)
      : super(SwipeState(profiles: [], incomingRequests: [], isLoading: false)) {
    loadFeed();
    loadIncomingRequests();
  }

  Future<void> loadFeed({Map<String, dynamic>? filters}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final feed = await _repository.getDiscoveryFeed(filters: filters);
      state = state.copyWith(profiles: feed, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> loadIncomingRequests() async {
    try {
      final requests = await _repository.getIncomingRequests();
      state = state.copyWith(incomingRequests: requests);
    } catch (e) {
      print('Load incoming requests error: $e');
    }
  }

  Future<void> swipeRight(String targetId) async {
    try {
      final res = await _repository.swipeRight(targetId);
      final resData = res['data'];
      
      if (resData['match'] == true) {
        state = state.copyWith(
          lastMatch: {
            'match': resData['matchDetails'],
            'profile': resData['matchedProfile'],
          },
        );
      }
    } catch (e) {
      print('Swipe Right error: $e');
    }
  }

  Future<void> swipeLeft(String targetId) async {
    try {
      await _repository.swipeLeft(targetId);
    } catch (e) {
      print('Swipe Left error: $e');
    }
  }

  Future<void> superLike(String targetId) async {
    try {
      final res = await _repository.superLike(targetId);
      final resData = res['data'];
      
      if (resData['match'] == true) {
        state = state.copyWith(
          lastMatch: {
            'match': resData['matchDetails'],
            'profile': resData['matchedProfile'],
          },
        );
      }
    } catch (e) {
      print('Super Like error: $e');
    }
  }

  void clearFeed() {
    state = state.copyWith(profiles: []);
  }

  Future<void> undo() async {
    state = state.copyWith(isLoading: true);
    try {
      final res = await _repository.undo();
      if (res['status'] == 'success') {
        // Reload feed to retrieve the undone card back in context
        await loadFeed();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void clearMatch() {
    state = state.copyWith(lastMatch: null);
  }
}

final swipeNotifierProvider = StateNotifierProvider<SwipeNotifier, SwipeState>((ref) {
  final repository = ref.watch(swipeRepositoryProvider);
  return SwipeNotifier(repository);
});
