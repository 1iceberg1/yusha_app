import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Supabase.initialize(
    url: 'https://rmhfunncqzrridcwwquo.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJtaGZ1bm5jcXpycmlkY3d3cXVvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDA4MDA5NDQsImV4cCI6MjAxNjM3Njk0NH0.R-txtFkJNaV04QAg3Slx1g0RUWLiHcI6DkdpYesuQvE',
  );
  runApp(YushaApp());
}

class YushaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yusha App',
      theme: ThemeData(primarySwatch: Colors.orange),
      home: SplashScreen(),
    );
  }
}
