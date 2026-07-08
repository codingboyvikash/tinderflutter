import 'package:dio/dio.dart';
import '../core/network.dart';

abstract class ChatRepository {
  Future<Map<String, dynamic>> getMatchesAndChats();
  Future<List<Map<String, dynamic>>> getMessages(String chatId, {int page = 1});
  Future<Map<String, dynamic>> sendMessage(
    String chatId, {
    String? content,
    String? attachmentPath,
    String? replyToId,
  });
  Future<Map<String, dynamic>> deleteMessage(String messageId, String action);
}

class ChatRepositoryImpl implements ChatRepository {
  final NetworkService _network;

  ChatRepositoryImpl(this._network);

  @override
  Future<Map<String, dynamic>> getMatchesAndChats() async {
    try {
      final response = await _network.dio.get('/api/matches');
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMessages(String chatId, {int page = 1}) async {
    try {
      final response = await _network.dio.get('/api/messages/$chatId', queryParameters: {
        'page': page,
      });
      final list = response.data['data'] as List;
      return list.map((item) => item as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessage(
    String chatId, {
    String? content,
    String? attachmentPath,
    String? replyToId,
  }) async {
    try {
      final Map<String, dynamic> formDataMap = {
        'chatId': chatId,
      };
      if (content != null) formDataMap['content'] = content;
      if (replyToId != null) formDataMap['replyTo'] = replyToId;
      if (attachmentPath != null) {
        final fileName = attachmentPath.split('/').last;
        formDataMap['attachment'] = await MultipartFile.fromFile(attachmentPath, filename: fileName);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _network.dio.post(
        '/api/messages',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data['data'];
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> deleteMessage(String messageId, String action) async {
    try {
      final response = await _network.dio.post('/api/messages/delete', data: {
        'messageId': messageId,
        'action': action,
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
