import 'package:get_it/get_it.dart';
import 'package:mini_feed/core/constants/api_constants.dart';
import 'package:mini_feed/core/network/network_client.dart';
import 'package:mini_feed/core/network/network_info.dart';
import 'package:mini_feed/core/network/connectivity_checker.dart';
import 'package:mini_feed/core/storage/storage_service.dart';
import 'package:mini_feed/core/storage/token_storage.dart';
import 'package:mini_feed/core/sync/sync_service.dart';
import 'package:mini_feed/core/error_handling/error_reporter.dart';
import 'package:mini_feed/data/datasources/remote/auth_remote_datasource.dart';
import 'package:mini_feed/data/datasources/remote/post_remote_datasource.dart';
import 'package:mini_feed/data/repositories/auth_repository_impl.dart';
import 'package:mini_feed/data/repositories/post_repository_impl.dart';
import 'package:mini_feed/domain/repositories/auth_repository.dart';
import 'package:mini_feed/domain/repositories/post_repository.dart';
import 'package:mini_feed/domain/usecases/auth/check_auth_status_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/login_usecase.dart';
import 'package:mini_feed/domain/usecases/auth/logout_usecase.dart';
import 'package:mini_feed/presentation/blocs/auth/auth_bloc.dart';
import 'package:mini_feed/presentation/blocs/feed/feed_bloc.dart';
import 'package:mini_feed/presentation/blocs/connectivity/connectivity_cubit.dart';
import 'package:mini_feed/domain/usecases/posts/get_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/search_posts_usecase.dart';
import 'package:mini_feed/domain/usecases/posts/get_post_details_usecase.dart';
import 'package:mini_feed/domain/usecases/comments/get_comments_usecase.dart';
import 'package:mini_feed/domain/usecases/favorites/toggle_favorite_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_details/post_details_bloc.dart';
import 'package:mini_feed/domain/usecases/posts/create_post_usecase.dart';
import 'package:mini_feed/presentation/blocs/post_creation/post_creation_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // BLoCs
  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      logoutUseCase: sl(),
      checkAuthStatusUseCase: sl(),
      getCurrentUserUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => FeedBloc(
      getPostsUseCase: sl(),
      searchPostsUseCase: sl(),
    ),
  );
  
  sl.registerFactory(
    () => PostDetailsBloc(
      getPostDetailsUseCase: sl(),
      getCommentsUseCase: sl(),
      toggleFavoriteUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => PostCreationBloc(
      createPostUseCase: sl(),
    ),
  );

  sl.registerLazySingleton(
    () => ConnectivityCubit(
      networkInfo: sl(),
      syncService: sl(),
    ),
  );

  // Use Cases - Auth
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => CheckAuthStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  // Use Cases - Posts
  sl.registerLazySingleton(() => GetPostsUseCase(sl()));
  sl.registerLazySingleton(() => SearchPostsUseCase(sl()));
  sl.registerLazySingleton(() => GetPostDetailsUseCase(sl()));
  sl.registerLazySingleton(() => GetCommentsUseCase(sl()));
  sl.registerLazySingleton(() => ToggleFavoriteUseCase(sl()));
  sl.registerLazySingleton(() => CreatePostUseCase(sl()));


  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      storageService: sl(),
      tokenStorage: sl(),
      networkInfo: sl(),
    ),
  );

  sl.registerLazySingleton<PostRepository>(
    () => PostRepositoryImpl(
      remoteDataSource: sl(),
      storageService: sl(),
      networkInfo: sl(),
    ),
  );

  // Data Sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl(instanceName: 'authNetworkClient')),
  );

  sl.registerLazySingleton<PostRemoteDataSource>(
    () => PostRemoteDataSourceImpl(sl(instanceName: 'postNetworkClient')),
  );

  // Core Services
  sl.registerLazySingleton<NetworkClient>(
    () => NetworkClient(baseUrl: ApiConstants.authBaseUrl),
    instanceName: 'authNetworkClient',
  );
  sl.registerLazySingleton<NetworkClient>(
    () => NetworkClient(baseUrl: ApiConstants.baseUrl),
    instanceName: 'postNetworkClient',
  );
  sl.registerLazySingleton<ConnectivityChecker>(() => ConnectivityChecker());
  sl.registerLazySingleton<StorageService>(() => StorageServiceImpl());
  sl.registerLazySingleton<TokenStorage>(() => TokenStorageImpl(sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton<SyncService>(() => SyncServiceImpl(
    networkInfo: sl(),
    storageService: sl(),
    postRemoteDataSource: sl(),
  ));
  sl.registerLazySingleton<ErrorReporter>(() => ErrorReporterImpl(
    storageService: sl(),
  ));
}