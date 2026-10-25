import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:testapp3/books/book_provider.dart';
import 'package:testapp3/homepage.dart';
import 'package:testapp3/landing.dart';
import 'package:testapp3/util/constants.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Unable to start Bookfania. Please try again.'),
                TextButton(onPressed: main, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      ),
    );
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final Widget? homeOverride;
  const MyApp({super.key, this.homeOverride});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    if (homeOverride != null) return _buildApp(context, null);
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, snapshot) => _buildApp(context, snapshot.data),
    );
  }

  Widget _buildApp(BuildContext context, User? currentUser) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: Constants.cocoa,
      brightness: Brightness.light,
      primary: Constants.cocoa,
      secondary: Constants.surfaceAlt,
      surface: Constants.surface,
    );

    return ChangeNotifierProvider(
      key: ValueKey(currentUser?.uid),
      create: (_) => BookProvider(),
      child: MaterialApp(
        title: 'Bookfania',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: baseScheme,
          scaffoldBackgroundColor: Constants.background,
          canvasColor: Constants.background,
          dividerColor: Constants.outline,
          appBarTheme: AppBarTheme(
            backgroundColor: Constants.appBar,
            foregroundColor: Constants.ink,
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            shape: const Border(
              bottom: BorderSide(color: Constants.outline, width: 1.2),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              overlayColor: WidgetStatePropertyAll(Colors.transparent),
              splashFactory: NoSplash.splashFactory,
            ),
          ),
          iconTheme: const IconThemeData(color: Constants.ink),
          cardTheme: CardTheme(
            color: Constants.surface,
            elevation: 2,
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: Constants.outline, width: 1.2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Constants.cocoa,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: Constants.ink,
              side: const BorderSide(color: Constants.outline, width: 1.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Constants.navSurface,
            selectedItemColor: Constants.ink,
            unselectedItemColor: Constants.mutedInk,
            showUnselectedLabels: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Constants.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Constants.outline,
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Constants.cocoa, width: 2),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Constants.sky,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Constants.surface,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
        home:
            homeOverride ??
            (currentUser != null
                ? const HomePage(initialpage: 2)
                : const LandingPage()),
      ),
    );
  }
}
