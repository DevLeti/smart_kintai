import 'package:flutter/cupertino.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 출근 상태를 저장하는 변수 (true: 출근, false: 퇴근)
  bool _isWorking = false;

  // 로그아웃 처리 함수
  Future<void> _logout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  // 출근/퇴근 API 호출 함수
  Future<void> _sendWork(bool isStart) async {
    try {
      await _supabase.from('kintai_start_end').insert({
        'is_start': isStart,
        'user_id': '1',
        'created_at': DateTime.now().toIso8601String(),
      }).select();

      // 성공 처리
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text(isStart ? '근무 시작' : '근무 종료'),
            content: Text(
                isStart ? '성공적으로 근무 시작 처리 되었습니다.' : '성공적으로 근무 종료 처리 되었습니다.'),
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

      // 상태값 반전 (출근 → 퇴근, 퇴근 → 출근)
      setState(() {
        _isWorking = isStart;
      });
    } catch (e) {
      // 오류 처리
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('오류'),
            content:
                Text('${isStart ? '근무 시작' : '근무 종료'} 처리 중 오류가 발생했습니다.\n$e'),
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

  // 출근 버튼
  Widget startButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.activeBlue,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
        onPressed: () => _sendWork(true),
        child: const Text(
          '근무 시작',
          style: TextStyle(color: CupertinoColors.black),
        ),
      ),
    );
  }

  // 퇴근 버튼
  Widget endButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.destructiveRed,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(8),
        onPressed: () => _sendWork(false),
        child: const Text(
          '근무 종료',
          style: TextStyle(color: CupertinoColors.black),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: const Text('근무관리'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _logout,
          child: const Icon(
            CupertinoIcons.square_arrow_right, // 로그아웃에 적합한 아이콘
            color: CupertinoColors.destructiveRed,
            size: 28,
          ),
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: _isWorking ? endButton() : startButton(),
        ),
      ),
    );
  }
}
