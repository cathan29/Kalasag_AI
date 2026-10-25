import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'login_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..initialize(),
      child: const KalasagApp(),
    ),
  );
}

class KalasagApp extends StatelessWidget {
  const KalasagApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kalasag',
    debugShowCheckedModeBanner: false,
    theme: KalasagTheme.light(),
    darkTheme: KalasagTheme.dark(),
    themeMode: ThemeMode.system,
    home: const SplashGate(),
  );
}

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});
  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool done = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1700), () {
      if (mounted) setState(() => done = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (done) return const LoginScreen();
    return Scaffold(
      backgroundColor: const Color(0xFF08111F),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/mascot/kalasagicon-transparent.png',
              width: 180,
              height: 180,
            ),
            const Text(
              'KALASAG',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Weather • Alerts • Readiness',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
