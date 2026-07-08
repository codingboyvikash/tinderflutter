import 'package:dio/dio.dart';
import '../core/network.dart';

abstract class SubscriptionRepository {
  Future<Map<String, dynamic>> purchaseSubscription(String planName, int durationDays);
}

class SubscriptionRepositoryImpl implements SubscriptionRepository {
  final NetworkService _network;

  SubscriptionRepositoryImpl(this._network);

  @override
  Future<Map<String, dynamic>> purchaseSubscription(String planName, int durationDays) async {
    try {
      final response = await _network.dio.post('/api/subscription', data: {
        'plan': planName,
        'durationInDays': durationDays,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  String _handleDioError(DioException error) {
    if (error.response?.data != null && error.response?.data['message'] != null) {
      return error.response?.data['message'];
    }
    return error.message ?? 'An unknown error occurred';
  }
}
