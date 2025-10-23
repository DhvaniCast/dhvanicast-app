import 'package:get_it/get_it.dart';

import 'data/repositories/auth_repository.dart';
import 'core/services/http_client.dart';
import 'presentation/state/auth/auth_bloc.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Register HttpClient as singleton
  getIt.registerLazySingleton<HttpClient>(() => HttpClient());

  // Register AuthService as singleton
  getIt.registerLazySingleton<AuthService>(() => AuthService());

  // Register AuthBloc as factory (new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authService: getIt<AuthService>()),
  );
}

// Helper methods for easy access
T get<T extends Object>() => getIt<T>();

// Dispose method for cleanup
void disposeServiceLocator() {
  getIt.reset();
}
