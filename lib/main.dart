import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/providers/theme_provider.dart';
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ENABLE OFFLINE PERSISTENCE
  // This allows the app to work without internet by caching data locally.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// CHANGE: Extend ConsumerWidget instead of StatelessWidget
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch the theme provider
    final isDarkMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Monthly Expense',
      debugShowCheckedModeBanner: false,

      // 2. Define Mode (Light vs Dark)
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,

      // 3. Define the actual colors
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.dark(
          primary: Colors.teal,
          secondary: Colors.tealAccent,
          surface: const Color(0xFF121212), // Dark grey background
        ),
        useMaterial3: true,
      ),

      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const HomeScreen();
        return const LoginScreen();
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, trace) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}