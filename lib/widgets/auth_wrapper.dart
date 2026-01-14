import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../providers/theme_provider.dart';
import '../themes/purple_theme.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/profile.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return StreamBuilder<AuthState>(
          stream: AuthService.authStateChanges,
          builder: (context, snapshot) {
            // Show loading indicator while checking auth state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return MaterialApp(
                title: 'Ruviel - Instagram Clone',
                debugShowCheckedModeBanner: false,
                theme: PurpleTheme.lightTheme.copyWith(
                  textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.lightTheme.textTheme),
                ),
                darkTheme: PurpleTheme.darkTheme.copyWith(
                  textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.darkTheme.textTheme),
                ),
                themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: const Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              );
            }

            // Check if user is authenticated
            final session = snapshot.data?.session;
            final isAuthenticated = session != null;

            return MaterialApp(
              title: 'Ruviel - Instagram Clone',
              debugShowCheckedModeBanner: false,
              theme: PurpleTheme.lightTheme.copyWith(
                textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.lightTheme.textTheme),
              ),
              darkTheme: PurpleTheme.darkTheme.copyWith(
                textTheme: GoogleFonts.poppinsTextTheme(PurpleTheme.darkTheme.textTheme),
              ),
              themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
              home: isAuthenticated ? const HomeScreen() : const LoginScreen(),
              onGenerateRoute: (settings) {
                if (isAuthenticated) {
                  // Authenticated routes
                  switch (settings.name) {
                    case '/home':
                      return MaterialPageRoute(builder: (_) => const HomeScreen());
                    case '/settings':
                      return MaterialPageRoute(builder: (_) => const SettingsScreen());
                    case '/profile':
                      final userId = settings.arguments as String?;
                      return MaterialPageRoute(
                        builder: (_) => ProfileScreen(userId: userId),
                      );
                    default:
                      return MaterialPageRoute(builder: (_) => const HomeScreen());
                  }
                } else {
                  // Unauthenticated routes
                  switch (settings.name) {
                    case '/login':
                      return MaterialPageRoute(builder: (_) => const LoginScreen());
                    case '/register':
                      return MaterialPageRoute(builder: (_) => const RegisterScreen());
                    default:
                      return MaterialPageRoute(builder: (_) => const LoginScreen());
                  }
                }
              },
            );
          },
        );
      },
    );
  }
}