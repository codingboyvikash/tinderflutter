import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/profile_repository.dart';
import 'auth_provider.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return ProfileRepositoryImpl(network);
});

// Profile State Definitions
abstract class ProfileState {
  const ProfileState();
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final Map<String, dynamic> profile;
  const ProfileLoaded(this.profile);
}

class ProfileError extends ProfileState {
  final String message;
  const ProfileError(this.message);
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final Ref _ref;

  ProfileNotifier(this._repository, this._ref) : super(const ProfileInitial()) {
    // Automatically load profile if authenticated
    _ref.listen(authNotifierProvider, (previous, next) {
      if (next is AuthAuthenticated) {
        loadProfile();
      } else {
        state = const ProfileInitial();
      }
    });
  }

  Future<void> loadProfile() async {
    state = const ProfileLoading();
    try {
      final result = await _repository.getProfile();
      if (result['status'] == 'success') {
        state = ProfileLoaded(result['data']);
      } else {
        state = ProfileError(result['message'] ?? 'Failed to load profile');
      }
    } catch (e) {
      // If profile doesn't exist yet, we capture it as ProfileError or handle creating state
      state = ProfileError(e.toString());
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> profileData) async {
    state = const ProfileLoading();
    try {
      final result = await _repository.updateProfile(profileData);
      if (result['status'] == 'success') {
        state = ProfileLoaded(result['data']);
        // Update user session metadata inside auth provider to indicate profile exists
        _ref.read(authNotifierProvider.notifier).checkStatus();
        return true;
      } else {
        state = ProfileError(result['message'] ?? 'Failed to update profile');
        return false;
      }
    } catch (e) {
      state = ProfileError(e.toString());
      return false;
    }
  }

  Future<void> uploadPhoto(String filePath) async {
    if (state is! ProfileLoaded) return;
    final currentProfile = (state as ProfileLoaded).profile;
    
    state = const ProfileLoading();
    try {
      final result = await _repository.uploadPhoto(filePath);
      if (result['status'] == 'success') {
        final updatedPhotos = List<String>.from(result['data']['photos']);
        final updatedProfile = Map<String, dynamic>.from(currentProfile);
        updatedProfile['photos'] = updatedPhotos;
        state = ProfileLoaded(updatedProfile);
      } else {
        state = ProfileError(result['message'] ?? 'Failed to upload photo');
      }
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }

  Future<void> deletePhoto(String photoUrl) async {
    if (state is! ProfileLoaded) return;
    final currentProfile = (state as ProfileLoaded).profile;
    
    state = const ProfileLoading();
    try {
      final result = await _repository.deletePhoto(photoUrl);
      if (result['status'] == 'success') {
        final updatedPhotos = List<String>.from(result['data']['photos']);
        final updatedProfile = Map<String, dynamic>.from(currentProfile);
        updatedProfile['photos'] = updatedPhotos;
        state = ProfileLoaded(updatedProfile);
      } else {
        state = ProfileError(result['message'] ?? 'Failed to delete photo');
      }
    } catch (e) {
      state = ProfileError(e.toString());
    }
  }
}

final profileNotifierProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repository = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repository, ref);
});
