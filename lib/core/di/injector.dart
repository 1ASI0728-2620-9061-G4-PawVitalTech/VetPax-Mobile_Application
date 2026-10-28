import 'package:vetpax_frontend/core/api/api_client.dart';
import 'package:vetpax_frontend/core/constants.dart';
import 'package:vetpax_frontend/core/storage/token_storage.dart';
import 'package:vetpax_frontend/core/storage/token_storage_impl.dart';
import 'package:vetpax_frontend/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vetpax_frontend/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:vetpax_frontend/features/auth/domain/repositories/auth_repository.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/login_user.dart';
import 'package:vetpax_frontend/features/auth/domain/usecases/register_user.dart';
import 'package:vetpax_frontend/features/vetpax/data/vetpax_repository.dart';

final TokenStorage tokenStorage = TokenStorageImpl();
final ApiClient apiClient = ApiClient(baseUrl: BASE_URL, tokenStorage: tokenStorage);
final AuthRemoteDataSource authRemoteDataSource = AuthRemoteDataSource(apiClient: apiClient);
final AuthRepository authRepository = AuthRepositoryImpl(
  remoteDataSource: authRemoteDataSource, tokenStorage: tokenStorage,
);
final LoginUser loginUserUseCase = LoginUser(authRepository);
final RegisterUser registerUserUseCase = RegisterUser(authRepository);
final VetPaxRepository vetPaxRepository = VetPaxRepository(apiClient);

void configureInjector() {
  apiClient.refreshAccessToken = authRepository.refreshAccessToken;
}
T injector<T>() {
  if (T == TokenStorage) return tokenStorage as T;
  if (T == ApiClient) return apiClient as T;
  if (T == AuthRepository) return authRepository as T;
  if (T == LoginUser) return loginUserUseCase as T;
  if (T == RegisterUser) return registerUserUseCase as T;
  if (T == VetPaxRepository) return vetPaxRepository as T;
  throw StateError('Dependencia no registrada: $T');
}
