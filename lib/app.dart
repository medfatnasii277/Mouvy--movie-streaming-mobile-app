import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/movies_list_screen.dart';
import 'screens/movie_detail_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const Color accentGreen = Color(0xFF00FF7F);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFF00FF7F)),
              ),
            ),
          );
        }

        final theme = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          primaryColor: accentGreen,
          colorScheme: ColorScheme.fromSeed(seedColor: accentGreen, brightness: Brightness.dark),
          inputDecorationTheme: const InputDecorationTheme(
            filled: true,
            fillColor: Color(0xFF0A0A0A),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00FF7F)),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        );

        return MaterialApp(
          navigatorKey: authProvider.navigatorKey,
          title: 'SmokeX',
          theme: theme,
          debugShowCheckedModeBanner: false,
          initialRoute: authProvider.isAuthenticated ? '/home' : '/login',
          routes: {
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/home': (context) => const HomeScreen(),
            '/movies': (context) => const MoviesListScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/movie-detail') {
              final movieId = settings.arguments as String?;
              if (movieId != null) {
                return MaterialPageRoute(
                  builder: (context) => MovieDetailScreen(movieId: movieId),
                );
              }
            }
            return null;
          },
        );
      },
    );
  }
}