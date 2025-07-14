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

  // 로그아웃 확인 다이얼로그 함수
  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            PrimaryButton(
              child: const Text('로그아웃'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _logout();
    }
  }

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
          final now = DateTime.now();
          final formattedTime =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          return AlertDialog(
            title: Text(isStart ? '근무 시작' : '근무 종료'),
            content: Text(
              '${isStart ? '성공적으로 근무 시작 처리 되었습니다.' : '성공적으로 근무 종료 처리 되었습니다.'}\n\n현재 시간: $formattedTime',
            ),
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

  // 출근 버튼 (정사각형)
  Widget startButton() {
    double size = MediaQuery.of(context).size.width - 40; // 좌우 패딩 10*2 + 여유 20
    if (size > 300) size = 300; // 최대 300px로 제한
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          color: CupertinoColors.activeBlue,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          onPressed: () => _sendWork(true),
          child: const Text(
            '근무 시작',
            style: TextStyle(
              color: CupertinoColors.white, // 폰트 색상을 하얀색으로 변경
              fontSize: 34, // 폰트 크기를 34로 변경
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // 퇴근 버튼 (정사각형)
  Widget endButton() {
    double size = MediaQuery.of(context).size.width - 40;
    if (size > 300) size = 300;
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CupertinoButton(
          color: CupertinoColors.destructiveRed,
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(16),
          onPressed: () => _sendWork(false),
          child: const Text(
            '근무 종료',
            style: TextStyle(
              color: CupertinoColors.white, // 폰트 색상을 하얀색으로 변경
              fontSize: 34, // 폰트 크기를 34로 변경
              fontWeight: FontWeight.bold,
            ),
          ),
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
          onPressed: _showLogoutDialog,
          child: const Icon(
            CupertinoIcons.square_arrow_right,
            color: CupertinoColors.systemGrey, // 연한 회색으로 변경
            size: 28,
          ),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Center(
                child: _isWorking ? endButton() : startButton(),
              ),
            ),
          );
        },
      ),
    );
  }
}
