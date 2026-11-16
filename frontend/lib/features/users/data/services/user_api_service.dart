import 'package:dio/dio.dart';
import 'package:fiapp/core/network/api_client.dart';
import 'package:fiapp/features/users/domain/entities/app_user.dart';

/// Cliente de los endpoints `/usuarios/` y `/tenants/current` (HU01).
class UserApiService {
  final Dio _dio;

  UserApiService([Dio? dio]) : _dio = dio ?? ApiClient.instance.dio;

  Future<CurrentMembership> getCurrentMembership() async {
    final resp = await _dio.get('/tenants/current');
    return CurrentMembership.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<AppUser>> getUsers() async {
    final resp = await _dio.get('/usuarios/');
    final data = resp.data as List<dynamic>;
    return data.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<AppUser> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    final resp = await _dio.post('/usuarios/', data: {
      'nombre': name,
      'email': email,
      'password': password,
      'rol': role,
    });
    return AppUser.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<AppUser> updateUser(String membershipId, {bool? active, String? role}) async {
    final resp = await _dio.patch('/usuarios/$membershipId', data: {
      if (active != null) 'activo': active,
      if (role != null) 'rol': role,
    });
    return AppUser.fromJson(resp.data as Map<String, dynamic>);
  }
}
