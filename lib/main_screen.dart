import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:musiconnect/providers/user_profile_provider.dart';
import 'package:musiconnect/screens/home_screen.dart';
import 'package:musiconnect/screens/vagas_screen.dart';
import 'package:musiconnect/screens/trupe_screen.dart';
import 'package:musiconnect/screens/artista_screen.dart';
import 'package:musiconnect/screens/users_list_screen.dart';
import 'package:musiconnect/l10n/app_localizations.dart'; // Import generated localizations

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
    final userProfileProvider = Provider.of<UserProfileProvider>(context);
    final localizations = AppLocalizations.of(context)!; // Get localizations instance

    if (userProfileProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(localizations.appTitle)), // Use localized app title
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: localizations.home),
          BottomNavigationBarItem(icon: const Icon(Icons.work), label: localizations.jobs),
          BottomNavigationBarItem(icon: const Icon(Icons.group), label: localizations.group),
          BottomNavigationBarItem(icon: const Icon(Icons.person), label: localizations.artist),
          BottomNavigationBarItem(icon: const Icon(Icons.chat), label: localizations.chat),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
