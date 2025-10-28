import 'package:get_it/get_it.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/frequency_repository.dart';
import 'data/repositories/group_repository.dart';
import 'data/repositories/communication_repository.dart';
import 'data/network/websocket_client.dart';
import 'core/services/http_client.dart';
import 'presentation/state/auth/auth_bloc.dart';
import 'presentation/services/dialer_service.dart';
import 'presentation/services/communication_service.dart';

final GetIt getIt = GetIt.instance;

void setupServiceLocator() {
  // Register HttpClient as singleton
  getIt.registerLazySingleton<HttpClient>(() => HttpClient());

  // Register Repositories
  getIt.registerLazySingleton<AuthService>(() => AuthService());
  getIt.registerLazySingleton<FrequencyRepository>(() => FrequencyRepository());
  getIt.registerLazySingleton<GroupRepository>(() => GroupRepository());
  getIt.registerLazySingleton<CommunicationRepository>(
    () => CommunicationRepository(),
  );

  // Register WebSocket Client as singleton
  getIt.registerLazySingleton<WebSocketClient>(() => WebSocketClient());

  // Register Services
  getIt.registerLazySingleton<DialerService>(() => DialerService());
  getIt.registerLazySingleton<CommunicationService>(
    () => CommunicationService(),
  );

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
