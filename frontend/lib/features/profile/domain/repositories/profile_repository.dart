import '../entities/profile.dart';

abstract class ProfileRepository {
  Future<Profile> getProfile();
  Future<Profile> updateProfile(Map<String, dynamic> data);
}
