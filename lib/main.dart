import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:testingcounterfeit/screens/welcomeScreen.dart';
import 'screens/home_screen.dart';
import 'services/blockchain_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize blockchain service
  try {
    // Initialize blockchain service
    final blockchainService = BlockchainService();
    await blockchainService.initialize();
  } catch (e) {
    // Handle initialization errors here
    print("Error initializing BlockchainService: $e");
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    return MaterialApp(
      title: 'Counterfeit Detection',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
      ),
      home: WelcomeScreen(),
    );
  }
}