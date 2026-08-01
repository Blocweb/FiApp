import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fiapp/core/network/api_client.dart';
import '../../data/repositories/profile_repository_remote_impl.dart';
import '../../domain/repositories/profile_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryRemoteImpl(ApiClient.instance.dio);
});
