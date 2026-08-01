import 'package:dio/dio.dart';

import '../../domain/entities/profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../models/profile_model.dart';

class ProfileRepositoryRemoteImpl implements ProfileRepository {
  final Dio _dio;

  ProfileRepositoryRemoteImpl(this._dio);

  @override
  Future<Profile> getProfile() async {
    final response = await _dio.get('/api/profile');
    return ProfileModel.fromJson(response.data as Map<String, dynamic>);
  }
}
