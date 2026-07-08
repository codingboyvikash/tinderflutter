import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/call_repository.dart';
import 'auth_provider.dart';

final callRepositoryProvider = Provider<CallRepository>((ref) {
  final network = ref.watch(networkServiceProvider);
  return CallRepositoryImpl(network);
});
