import 'package:get_it/get_it.dart';
import '../device/device_detector.dart';
import '../network/dynamic_api_client.dart';
import '../storage/secure_storage_service.dart';
import '../../features/admin/domain/repositories/api_config_repository.dart';
import '../../features/admin/data/repositories/api_config_repository_impl.dart';
import '../../features/admin/presentation/bloc/admin_cubit.dart';
import '../../features/catalog/data/repositories/catalog_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core Services
  sl.registerLazySingleton<DeviceDetector>(() => DeviceDetector());
  sl.registerLazySingleton<SecureStorageService>(() => SecureStorageService());
  sl.registerLazySingleton<DynamicApiClient>(() => DynamicApiClient());

  // Repositories
  sl.registerLazySingleton<ApiConfigRepository>(
    () => ApiConfigRepositoryImpl(
      storageService: sl<SecureStorageService>(),
      apiClient: sl<DynamicApiClient>(),
    ),
  );

  sl.registerLazySingleton<CatalogRepository>(
    () => CatalogRepository(
      apiClient: sl<DynamicApiClient>(),
      configRepository: sl<ApiConfigRepository>(),
      storageService: sl<SecureStorageService>(),
    ),
  );

  // BLoCs / Cubits
  sl.registerFactory<AdminCubit>(() => AdminCubit(sl<ApiConfigRepository>()));
}
