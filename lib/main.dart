import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Import Riverpod
import 'firebase_options.dart';
import 'features/auth/data/auth_repository.dart'; // Import for the stream provider
import 'features/auth/presentation/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. Wrap the WHOLE app in ProviderScope.
  // This stores all the state for Riverpod.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Monthly Expense',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const AuthGate(), // 3. Set Home to AuthGate
    );
  }
}

// 4. The AuthGate Widget
// It watches the authentication state and decides which page to show.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We "watch" the stream.
    // Whenever Firebase says "User changed", this rebuilds automatically.
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // User is logged in!
          return const Scaffold(body: Center(child: Text("Welcome! (Home Screen)")));
        }
        // User is null (Logged out)
        return const LoginScreen();
      },
      // While checking authentication status (loading)...
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      // If something goes wrong...
      error: (e, trace) => Scaffold(body: Center(child: Text(e.toString()))),
    );
  }
}