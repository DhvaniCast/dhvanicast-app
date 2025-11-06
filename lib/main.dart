import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'injection.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/dialer/screens/dialer_screen.dart';
import 'features/communication/screens/communication_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/radio/screens/live_radio_screen.dart';
import 'providers/auth_bloc.dart';

void main() {
  // Setup dependency injection
  setupServiceLocator();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (context) => getIt<AuthBloc>(),
      child: MaterialApp(
        title: 'Dhvani Cast App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/dialer': (context) => const DialerScreen(),
          '/communication': (context) => const CommunicationScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/live_radio': (context) {
            final args =
                ModalRoute.of(context)?.settings.arguments
                    as Map<String, dynamic>?;
            return LiveRadioScreen(groupData: args);
          },
        },
      ),
    );
  }
}
