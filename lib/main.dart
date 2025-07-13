import 'package:flutter/cupertino.dart';
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
    return const CupertinoApp(
      title: '근무관리 앱',
      home: MyHomePage(),
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
    final response = await _supabase.from('kintai_start_end').insert({
      'is_start': true,
      'user_id': '1',
      'created_at': DateTime.now().toIso8601String(),
    });

    // TODO: 오류 처리 필요
    if (response.error != null) {
      showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
                title: const Text('오류 발생'),
                content: Text('오류:${response.error!.message}'),
                actions: <Widget>[
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop('dialog');
                    },
                    child: const Text('확인'),
                  ),
                ],
              ));
    } else {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('근무 시작'),
          content: const Text('근무 시작 성공'),
          actions: <Widget>[
            CupertinoDialogAction(
              child: const Text('확인'),
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop('dialog');
              },
            ),
          ],
        ),
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
              style: TextStyle(color: CupertinoColors.white),
            ),
          ),
        ),
      ),
    );
  }
}
