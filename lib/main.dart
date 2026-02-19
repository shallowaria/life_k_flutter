import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'services/storage_service.dart';
import 'services/destiny_api_service.dart';
import 'blocs/user_input/user_input_bloc.dart';
import 'blocs/user_input/user_input_event.dart';
import 'blocs/destiny_result/destiny_result_bloc.dart';
import 'blocs/destiny_result/destiny_result_event.dart';
import 'screens/input_screen.dart';
import 'screens/result_screen.dart';

void main() {
  runApp(const LifeKApp());
}

class LifeKApp extends StatelessWidget {
  const LifeKApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storageService = StorageService();

    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://api.anthropic.com',
    );

    const authToken = String.fromEnvironment('API_AUTH_TOKEN');

    const model = String.fromEnvironment(
      'API_MODEL',
      defaultValue: 'claude-sonnet-4-20250514',
    );

    final apiService = DestinyApiService(
      baseUrl: baseUrl,
      authToken: authToken,
      model: model,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: storageService),
        RepositoryProvider.value(value: apiService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                UserInputBloc(storageService: storageService)
                  ..add(const UserInputLoaded()),
          ),
          BlocProvider(
            create: (context) => DestinyResultBloc(
              apiService: apiService,
              storageService: storageService,
            )..add(const DestinyResultLoaded()),
          ),
        ],
        child: MaterialApp.router(
          title: '人生K线图',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('zh', 'CN'),
            Locale('en', 'US'),
          ],
          theme: _buildTheme(),
          routerConfig: _router,
        ),
      ),
    );
  }

  static ThemeData _buildTheme() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B3A3A),
        brightness: Brightness.light,
      ),
      fontFamily: 'Noto Sans SC',
      appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static final _router = GoRouter(
    initialLocation: '/input',
    routes: [
      GoRoute(path: '/input', builder: (context, state) => const InputScreen()),
      GoRoute(
        path: '/result',
        builder: (context, state) => const ResultScreen(),
      ),
    ],
  );
}
