import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/auth/session_store.dart';
import 'core/theme/theme.dart';
import 'core/theme/theme_store.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    publishableKey: dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'] ?? '',
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
