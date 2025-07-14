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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTodayWorkStatus();
  }

  // 오늘의 마지막 출근/퇴근 상태를 supabase에서 조회
  Future<void> _fetchTodayWorkStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 실제로는 user_id를 동적으로 받아야 함. 예시로 '1' 사용
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final user = _supabase.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        setState(() {
          _isWorking = false;
          _isLoading = false;
        });
        // 세션 만료 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('세션 만료'),
              content: const Text('세션이 만료되었습니다.\n다시 로그인 해주세요.'),
              actions: [
                TextButton(
                  child: const Text('확인'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                ),
              ],
            );
          },
        );
        return;
      }
      final response = await _supabase
          .from('kintai_start_end')
          .select('is_start, created_at')
          .eq('uid', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isNotEmpty) {
        final last = response.first;
        setState(() {
          _isWorking = last['is_start'] == true;
        });
      } else {
        // 오늘 기록이 없으면 출근 상태로 시작
        setState(() {
          _isWorking = false;
        });
      }
    } catch (e) {
      // 오류 발생 시 기본값(퇴근 상태)로
      setState(() {
        _isWorking = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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
      final user = _supabase.auth.currentUser;
      final uid = user?.id;
      if (uid == null) {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('오류'),
              content: const Text('유저 정보를 불러올 수 없습니다. 다시 로그인 해주세요.'),
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
        return;
      }

      await _supabase.from('kintai_start_end').insert({
        'is_start': isStart,
        'uid': uid,
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

      // 상태값 반영 (출근 → 퇴근, 퇴근 → 출근)
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
                child: _isLoading
                    ? const CupertinoActivityIndicator()
                    : (_isWorking ? endButton() : startButton()),
              ),
            ),
          );
        },
      ),
    );
  }
}
