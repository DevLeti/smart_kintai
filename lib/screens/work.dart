import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Work extends StatefulWidget {
  const Work({super.key});

  @override
  State<Work> createState() => _WorkState();
}

class _WorkState extends State<Work> {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 출근 상태를 저장하는 변수 (true: 출근, false: 퇴근)
  bool _isWorking = false;
  bool _isLoading = true;

  // 출근/퇴근 시간 저장 변수
  DateTime? _startTime;
  DateTime? _endTime;

  @override
  void initState() {
    super.initState();
    _fetchTodayWorkStatus();
  }

  // 오늘의 출근/퇴근 상태 및 시간들을 supabase에서 조회
  Future<void> _fetchTodayWorkStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      final user = _supabase.auth.currentUser;
      final userId = user?.id;
      if (userId == null) {
        setState(() {
          _isWorking = false;
          _isLoading = false;
          _startTime = null;
          _endTime = null;
        });
        // 세션 만료 다이얼로그 표시
        showShadDialog(
          context: context,
          builder: (context) {
            return ShadDialog.alert(
              title: const Text('세션 만료'),
              description: const Text('세션이 만료되었습니다.\n다시 로그인 해주세요.'),
              actions: [
                ShadButton(
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

      // 오늘의 모든 출근/퇴근 기록을 시간순으로 조회
      final response = await _supabase
          .from('kintai_start_end')
          .select('is_start, created_at')
          .eq('uid', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lte('created_at', endOfDay.toIso8601String())
          .order('created_at', ascending: true);

      DateTime? firstStartTime;
      DateTime? lastEndTime;
      bool isWorking = false;

      for (final record in response) {
        if (record['is_start'] == true && firstStartTime == null) {
          // 첫 출근 기록만 저장
          firstStartTime = DateTime.tryParse(record['created_at']);
        } else if (record['is_start'] == false) {
          // 마지막 퇴근 기록으로 갱신
          lastEndTime = DateTime.tryParse(record['created_at']);
        }
      }

      // 현재 출근 상태는 마지막 기록의 is_start 값에 따라 판단
      if (response.isNotEmpty) {
        final lastRecord = response.last;
        isWorking = lastRecord['is_start'] == true;
      } else {
        isWorking = false;
      }

      setState(() {
        _isWorking = isWorking;
        _startTime = firstStartTime;
        _endTime = lastEndTime;
      });
    } catch (e) {
      setState(() {
        _isWorking = false;
        _startTime = null;
        _endTime = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 출근/퇴근 API 호출 함수
  Future<void> _sendWork(bool isStart) async {
    try {
      final user = _supabase.auth.currentUser;
      final uid = user?.id;
      if (uid == null) {
        showShadDialog(
          context: context,
          builder: (context) {
            return ShadDialog.alert(
              title: const Text('오류'),
              description: const Text('유저 정보를 불러올 수 없습니다. 다시 로그인 해주세요.'),
              actions: [
                ShadButton(
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

      final now = DateTime.now();

      await _supabase.from('kintai_start_end').insert({
        'is_start': isStart,
        'uid': uid,
        'created_at': now.toIso8601String(),
      }).select();

      // 성공 처리
      showShadDialog(
        context: context,
        builder: (context) {
          final formattedTime =
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
          return ShadDialog.alert(
            title: Text(isStart ? '근무 시작' : '근무 종료'),
            description: Text(
              '${isStart ? '성공적으로 근무 시작 처리 되었습니다.' : '성공적으로 근무 종료 처리 되었습니다.'}\n현재 시간: $formattedTime',
            ),
            actions: [
              ShadButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );

      // 상태값 반영 및 출근/퇴근 시간 갱신을 위해 다시 조회
      await _fetchTodayWorkStatus();
    } catch (e) {
      // Log the error internally
      print('Error during ${isStart ? '근무 시작' : '근무 종료'}: $e');

      // Show a user-friendly error message
      showShadDialog(
        context: context,
        builder: (context) {
          return ShadDialog.alert(
            title: const Text('오류'),
            description: Text(
                '${isStart ? '근무 시작' : '근무 종료'} 처리 중 문제가 발생했습니다. 잠시 후 다시 시도해주세요.'),
            actions: [
              ShadButton(
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

  // 시간 포맷 함수
  String _formatTime(DateTime? dt) {
    if (dt == null) return '미입력';
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  // 출근/퇴근 정보 위젯
  Widget workInfoWidget() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          Text(
            '출근: ${_formatTime(_startTime)}\n퇴근: ${_formatTime(_endTime)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              color: CupertinoColors.systemGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  // 메인 컨텐츠만 보여줌
  Widget _buildBody() {
    return Center(
      child: _isLoading
          ? const CupertinoActivityIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                workInfoWidget(),
                _isWorking ? endButton() : startButton(),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: _buildBody(),
            ),
          );
        },
      ),
    );
  }
}
