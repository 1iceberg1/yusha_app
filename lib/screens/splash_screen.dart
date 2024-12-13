import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleSplashLogic();
  }

  Future<void> _handleSplashLogic() async {
    final supabaseClient = Supabase.instance.client;

    // Check if the user is already logged in
    final session = supabaseClient.auth.currentSession;

    if (session == null) {
      // User is not logged in, show splash for 3 seconds
      await Future.delayed(Duration(seconds: 3));
      _navigateToMainScreen();
    } else {
      // User is logged in, perform logout
      await _logoutAndNavigate();
    }
  }

  Future<void> _logoutAndNavigate() async {
    try {
      // Log out from Supabase
      final supabaseClient = Supabase.instance.client;
      await supabaseClient.auth.signOut();

      // Navigate to the MainScreen after logout is complete
      _navigateToMainScreen();
    } catch (e) {
      // Handle error (e.g., show a message or retry)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  void _navigateToMainScreen() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          'assets/images/menu-logo.png', // Local image path
          height: 100,
          width: 100,
        ),
      ),
    );
  }
}
