import 'package:dio/dio.dart';
import '../core/network.dart';

abstract class CallRepository {
  Future<Map<String, dynamic>> getAgoraToken(String channelName, int uid);
}

class CallRepositoryImpl implements CallRepository {
  final NetworkService _network;

  CallRepositoryImpl(this._network);

  @override
  Future<Map<String, dynamic>> getAgoraToken(String channelName, int uid) async {
    try {
      final response = await _network.dio.post('/api/agora/token', data: {
        'channelName': channelName,
        'uid': uid,
      });
      return response.data['data'];
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
