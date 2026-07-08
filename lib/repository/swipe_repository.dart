import 'package:dio/dio.dart';
import '../core/network.dart';

abstract class SwipeRepository {
  Future<List<Map<String, dynamic>>> getDiscoveryFeed({Map<String, dynamic>? filters});
  Future<Map<String, dynamic>> swipeRight(String targetId);
  Future<Map<String, dynamic>> swipeLeft(String targetId);
  Future<Map<String, dynamic>> superLike(String targetId);
  Future<Map<String, dynamic>> undo();
}

class SwipeRepositoryImpl implements SwipeRepository {
  final NetworkService _network;

  SwipeRepositoryImpl(this._network);

  @override
  Future<List<Map<String, dynamic>>> getDiscoveryFeed({Map<String, dynamic>? filters}) async {
    try {
      final response = await _network.dio.get('/api/swipe/discovery', queryParameters: filters);
      final data = response.data['data'] as List;
      return data.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> swipeRight(String targetId) async {
    try {
      final response = await _network.dio.post('/api/swipe/right', data: {
        'targetId': targetId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> swipeLeft(String targetId) async {
    try {
      final response = await _network.dio.post('/api/swipe/left', data: {
        'targetId': targetId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> superLike(String targetId) async {
    try {
      final response = await _network.dio.post('/api/swipe/super-like', data: {
        'targetId': targetId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> undo() async {
    try {
      final response = await _network.dio.post('/api/swipe/undo');
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
