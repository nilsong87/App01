import 'package:flutter/material.dart';
import 'package:musiconnect/screens/home_screen.dart';
import 'package:musiconnect/screens/vagas_screen.dart';
import 'package:musiconnect/screens/trupe_screen.dart';
import 'package:musiconnect/screens/artista_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musiconnect/screens/auth_screen.dart';
import 'package:provider/provider.dart'; // Import provider
import 'package:musiconnect/providers/user_profile_provider.dart'; // Import UserProfileProvider
import 'package:musiconnect/providers/post_provider.dart'; // Import PostProvider
import 'package:musiconnect/providers/vaga_provider.dart'; // Import VagaProvider
import 'package:musiconnect/screens/users_list_screen.dart'; // Import UsersListScreen

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

// Define the custom color palette
Map<int, Color> getMaterialColor(int hexColor) {
  return {
    50: Color(hexColor).withAlpha((255 * 0.1).round()),
    100: Color(hexColor).withAlpha((255 * 0.2).round()),
    200: Color(hexColor).withAlpha((255 * 0.3).round()),
    300: Color(hexColor).withAlpha((255 * 0.4).round()),
    400: Color(hexColor).withAlpha((255 * 0.5).round()),
    500: Color(hexColor).withAlpha((255 * 0.6).round()),
    600: Color(hexColor).withAlpha((255 * 0.7).round()),
    700: Color(hexColor).withAlpha((255 * 0.8).round()),
    800: Color(hexColor).withAlpha((255 * 0.9).round()),
    900: Color(hexColor).withAlpha((255 * 1.0).round()),
  };
}

final MaterialColor primaryColor = MaterialColor(
  0xFF72577C,
  getMaterialColor(0xFF72577C),
);
final MaterialColor accentColor = MaterialColor(
  0xFF562155,
  getMaterialColor(0xFF562155),
);
final MaterialColor lightBlue = MaterialColor(
  0xFFC5F7F0,
  getMaterialColor(0xFFC5F7F0),
);
final MaterialColor mediumBlue = MaterialColor(
  0xFFA9C2C9,
  getMaterialColor(0xFFA9C2C9),
);
final MaterialColor grayPurple = MaterialColor(
  0xFF8E8CA3,
  getMaterialColor(0xFF8E8CA3),
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MusiConnect',
      theme: ThemeData(
        primarySwatch: primaryColor,
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
        primarySwatch: primaryColor,
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
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system, // Follows system theme
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
            return const MainScreen();
          }
          return const AuthScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    VagasScreen(),
    TrupeScreen(),
    ArtistaScreen(),
    UsersListScreen(), // New Chat tab
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MusiConnect')),
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Vagas'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Trupe'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Artista'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Chat'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
