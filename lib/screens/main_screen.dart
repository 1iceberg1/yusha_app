import 'package:flutter/material.dart';
import 'package:yusha_test/widgets/hover_button.dart'; // Ensure this is the correct path
import 'package:yusha_test/screens/drawing_screen.dart';
import 'package:yusha_test/screens/gallery_screen.dart';
import 'package:yusha_test/screens/camera_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoggedIn = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoginMode = true; // Toggle between login and signup

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final user = _supabase.auth.currentUser;
    setState(() {
      _isLoggedIn = user != null;
    });
  }

  Future<void> _authenticate() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    try {
      if (_isLoginMode) {
        // Login
        await _supabase.auth
            .signInWithPassword(email: email, password: password);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login successful!")),
        );

        // Update login state
        setState(() {
          _isLoggedIn = true;
        });
      } else {
        // Signup
        await _supabase.auth.signUp(email: email, password: password);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Please login.")),
        );
        setState(() {
          _isLoginMode = true; // Switch to login mode after signup
        });
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication failed: $error')),
      );
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   actions: [
      //     if (_isLoggedIn)
      //       IconButton(
      //         icon: const Icon(Icons.logout),
      //         onPressed: _logout,
      //       ),
      //   ],
      // ),
      body: Stack(
        children: [
          Positioned(
            top: 30,
            right: 20,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HoverButton(
                    defaultColor: Colors.orange,
                    hoverColor: Colors.grey,
                    icon: Icons.edit,
                    onPressed: () {
                      if (_isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => DrawingScreen()),
                        );
                      }
                    }),
                const SizedBox(width: 10),
                HoverButton(
                    defaultColor: Colors.orange,
                    hoverColor: Colors.grey,
                    icon: Icons.image,
                    onPressed: () {
                      if (_isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => GalleryScreen()),
                        );
                      }
                    }),
                const SizedBox(width: 10),
                HoverButton(
                    defaultColor: Colors.orange,
                    hoverColor: Colors.grey,
                    icon: Icons.camera_alt,
                    onPressed: () {
                      if (_isLoggedIn) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CameraScreen()),
                        );
                      }
                    }),
              ],
            ),
          ),
          if (!_isLoggedIn)
            _buildLoginModal(), // Display login modal if not logged in
        ],
      ),
    );
  }

  Widget _buildLoginModal() {
    return GestureDetector(
      onTap: () {}, // Prevent dismissing modal by tapping outside
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/planet-yusha.png', // Local image path
                      height: 100,
                      width: 100,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      _isLoginMode ? 'Login' : 'Signup',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _authenticate,
                      child: Text(_isLoginMode ? 'Login' : 'Signup'),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                        });
                      },
                      child: Text(
                        _isLoginMode
                            ? "Don't have an account? Signup"
                            : "Already have an account? Login",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
