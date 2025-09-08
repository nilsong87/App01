import 'package:flutter/material.dart';
import 'package:musiconnect/routes.dart';
import 'package:musiconnect/main_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musiconnect/screens/auth_screen.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:musiconnect/providers/user_profile_provider.dart'; // Import UserProfileProvider
import 'package:musiconnect/providers/post_provider.dart'; // Import PostProvider
import 'package:musiconnect/providers/vaga_provider.dart'; // Import VagaProvider
// Import UsersListScreen
import 'package:musiconnect/screens/comments_screen.dart'; // Import CommentsScreen
import 'package:musiconnect/screens/group_detail_screen.dart'; // Import GroupDetailScreen
import 'package:musiconnect/models/group.dart'; // Import Group model
import 'package:musiconnect/utils/app_colors.dart'; // Import custom app colors
import 'package:musiconnect/l10n/app_localizations.dart'; // Import generated localizations
import 'package:flutter_localizations/flutter_localizations.dart'; // Import flutter_localizations

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => PostProvider()),
        ChangeNotifierProvider(create: (context) => VagaProvider()), // Add VagaProvider
      ],
      child: const MyApp(),
    ),
  );
}





class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppLocalizations.of(context)!.appTitle, // Use localized title
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('pt', ''), // Portuguese
        // Add other supported locales here
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: primaryColor,
          secondary: accentColor,
          surface: lightBlue,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.light,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: accentColor,
          unselectedItemColor: grayPurple,
          backgroundColor: primaryColor,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: primaryColor,
          secondary: accentColor,
          surface: grayPurple,
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurface: Colors.white,
          error: Colors.red,
          onError: Colors.white,
          brightness: Brightness.dark,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          selectedItemColor: accentColor,
          unselectedItemColor: lightBlue,
          backgroundColor: primaryColor,
        ),
        useMaterial3: true
      ),
      themeMode: ThemeMode.system, // Follows system theme
      routes: {
        AppRoutes.auth: (context) => const AuthScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.comments: (context) {
          final postId = ModalRoute.of(context)?.settings.arguments as String?;
          if (postId == null) {
            // Handle error or navigate to a default screen if postId is null
            return const Text('Error: Post ID not found'); // Or a more user-friendly error screen
          }
          return CommentsScreen(postId: postId);
        },
        AppRoutes.groupDetail: (context) {
          final group = ModalRoute.of(context)?.settings.arguments as Group?;
          if (group == null) {
            // Handle error or navigate to a default screen if group is null
            return const Text('Error: Group not found'); // Or a more user-friendly error screen
          }
          return GroupDetailScreen(group: group);
        },
      },
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (ctx, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userSnapshot.hasData) {
            // Fetch user profile when user is logged in
            Provider.of<UserProfileProvider>(
              context,
              listen: false,
            ).fetchUserProfile(userSnapshot.data!.uid);
            // Navigate after the current frame is built
            Future.microtask(() {
              if (!context.mounted) return; // Add this line
              Navigator.of(context).pushReplacementNamed(AppRoutes.main);
            });
            return const SizedBox.shrink(); // Return an empty widget while navigating
          }
          if (userSnapshot.hasError) {
            return Center(
              child: Text('An error occurred: ${userSnapshot.error}'),
            );
          }
          Future.microtask(() {
            if (!context.mounted) return; // Add this line
            Navigator.of(context).pushReplacementNamed(AppRoutes.auth);
          });
          return const SizedBox.shrink(); // Return an empty widget while navigating
        },
      ),
    );
  }
}


