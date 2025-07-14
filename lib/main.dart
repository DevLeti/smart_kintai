import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/mainPage.dart';
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: '근무관리 앱',
      home: const AuthRedirectPage(),
      theme: ThemeData(
        colorScheme: ColorSchemes.lightSlate(),
        radius: 0.5,
      ),
    );
  }
}

class AuthRedirectPage extends StatelessWidget {
  const AuthRedirectPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;
    // 로그인 세션이 있으면 MainPage, 없으면 LoginPage로 이동
    if (session != null) {
      return const MainPage();
    } else {
      return const LoginPage();
    }
  }
}
