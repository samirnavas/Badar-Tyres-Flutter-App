import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/session_store.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_store.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://gqdwrtxluxrcrfhtygdf.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdxZHdydHhsdXhyY3JmaHR5Z2RmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIxMzk5OTYsImV4cCI6MjA5NzcxNTk5Nn0.urcRoMfln8T1TX-KNHqBCuVCeJjYmUw7DUfZERC6TDw',
  );
  
  await ThemeStore.instance.init();
  final rememberedUser = await SessionStore.instance.loadCurrentUser();
  runApp(MyApp(startLoggedIn: rememberedUser != null));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.startLoggedIn = false});

  /// Whether a remembered session was found at startup, so we can skip login.
  final bool startLoggedIn;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeStore.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Badar Tyres',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeStore.instance.themeMode,
          home: startLoggedIn ? const HomeShell() : const LoginScreen(),
        );
      },
    );
  }
}
