import 'package:get_it/get_it.dart';

import 'core/auth_repository.dart';
import 'core/frequency_repository.dart';
import 'core/group_repository.dart';
import 'core/communication_repository.dart';
import 'core/websocket_client.dart';
import 'shared/services/http_client.dart';
import 'providers/auth_bloc.dart';
import 'shared/services/dialer_service.dart';
import 'shared/services/communication_service.dart';
import 'shared/services/audio_service.dart';
import 'shared/services/livekit_service.dart';
import 'shared/services/social_service.dart';

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
  getIt.registerLazySingleton<AudioService>(() => AudioService());
  getIt.registerLazySingleton<LiveKitService>(() => LiveKitService());
  getIt.registerLazySingleton<SocialService>(() => SocialService());

  // Register AuthBloc as factory (new instance each time)
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authService: getIt<AuthService>()),
  );
}
