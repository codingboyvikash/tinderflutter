import 'package:dio/dio.dart';
import '../core/network.dart';

abstract class ProfileRepository {
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData);
  Future<Map<String, dynamic>> uploadPhoto(String filePath);
  Future<Map<String, dynamic>> deletePhoto(String photoUrl);
}

class ProfileRepositoryImpl implements ProfileRepository {
  final NetworkService _network;

  ProfileRepositoryImpl(this._network);

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await _network.dio.get('/api/profile');
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _network.dio.put('/api/profile', data: profileData);
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    try {
      final fileName = filePath.split('/').last;
      final formData = FormData.fromMap({
        'photo': await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _network.dio.post(
        '/api/profile/upload-photo',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> deletePhoto(String photoUrl) async {
    try {
      final response = await _network.dio.post('/api/profile/delete-photo', data: {
        'photoUrl': photoUrl,
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
