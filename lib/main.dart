import 'package:flutter/cupertino.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadcnApp(
      title: '근무관리 앱',
      home: const MyHomePage(),
      theme: ThemeData(
        colorScheme: ColorSchemes.lightSlate(),
        radius: 0.5,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final SupabaseClient _supabase = SupabaseClient(
    dotenv.env['SUPABASE_URL']!,
    dotenv.env['SUPABASE_ANON_KEY']!,
  );

  void _startWork() async {
    try {
      await _supabase.from('kintai_start_end').insert({
        'is_start': true,
        'user_id': '1',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      // 성공 처리
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('근무 시작'),
            content: const Text('성공적으로 근무 시작 처리 되었습니다.'),
            actions: [
              PrimaryButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      // 오류 처리
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('오류'),
            content: Text('근무 시작 처리 중 오류가 발생했습니다.\n$e'),
            actions: [
              PrimaryButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.activeBlue,
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(8),
            onPressed: _startWork,
            child: const Text(
              '근무 시작',
              style: TextStyle(color: CupertinoColors.black),
            ),
          ),
        ),
      ),
    );
  }
}
