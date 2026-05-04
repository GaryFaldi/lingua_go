// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_page.dart';
import 'features/auth/lock_screen.dart';
import 'features/home/main_navigation.dart';
import 'features/home/main_quest/quest_provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));

  await Future.wait([
    dotenv.load(fileName: '.env'),
    NotificationService.init(),
  ]);
  NotificationService.scheduleDailySevenAM().catchError((e) {
    debugPrint("Gagal menjadwalkan notifikasi: $e");
  });

  final authProvider = AuthProvider();

  await authProvider.tryRestoreSession();

  runApp(MyApp(authProvider: authProvider));
}

class MyApp extends StatelessWidget {
  final AuthProvider authProvider;
  const MyApp({super.key, required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),

        // QuestProvider otomatis dibuat ulang saat user login/ganti akun
        ChangeNotifierProxyProvider<AuthProvider, QuestProvider?>(
          create: (_) => null,
          update: (_, auth, previous) {
            if (auth.currentUser == null) return null;
            if (previous != null && previous.userId == auth.currentUser!.id!) {
              return previous;
            }
            return QuestProvider(userId: auth.currentUser!.id!);
          },
        ),
      ],
      child: MaterialApp(
        title: 'LinguaQuest',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF6C63FF)),
          useMaterial3: true,
        ),
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) auth.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isLoggedIn) return const MainNavigation();
        if (auth.lockedUsername != null) return const LockScreen();
        return const LoginPage();
      },
    );
  }
}
