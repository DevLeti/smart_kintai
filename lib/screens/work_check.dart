import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WorkCheck extends StatefulWidget {
  final int year;
  final int month;

  WorkCheck({
    super.key,
    int? initYear,
    int? initMonth,
  })  : year = initYear ?? DateTime.now().year,
        month = initMonth ?? DateTime.now().month;
  @override
  State<WorkCheck> createState() => _WorkCheckState();
}

class _WorkCheckState extends State<WorkCheck> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTimeTable();
  }

  Future<void> _fetchTimeTable() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // 해당 월의 시작과 끝 날짜 구하기
    final startDate = DateTime(widget.year, widget.month, 1);
    final endDate = DateTime(widget.year, widget.month + 1, 1);

    // kintai_start_end에서 해당 월의 데이터 불러오기
    final response = await _supabase
        .from('kintai_start_end')
        .select('is_start, created_at')
        .eq('uid', user.id)
        .gte('created_at', startDate.toIso8601String())
        .lt('created_at', endDate.toIso8601String())
        .order('created_at', ascending: true);

    setState(() {
      _records = List<Map<String, dynamic>>.from(response);
      _isLoading = false;
    });
  }

  // is_start 필드를 기반으로 출근/퇴근 타입을 판별하여 페어링
  List<Map<String, DateTime?>> _pairStartEnd(
      List<Map<String, dynamic>> records) {
    List<Map<String, DateTime?>> result = [];
    DateTime? lastStart;
    for (int i = 0; i < records.length; i++) {
      final isStart = records[i]['is_start'] == true;
      final createdAt = DateTime.parse(records[i]['created_at']);
      if (isStart) {
        if (lastStart != null) {
          // 이전 출근이 짝이 없으면 단독 출근으로 출력
          result.add({'start': lastStart, 'end': null});
        }
        lastStart = createdAt;
      } else {
        if (lastStart == null) {
          // 퇴근이 먼저 나오면 단독 퇴근으로 출력
          result.add({'start': null, 'end': createdAt});
        } else {
          // 출근과 퇴근을 짝지어서 출력
          result.add({'start': lastStart, 'end': createdAt});
          lastStart = null;
        }
      }
    }
    // 마지막에 출근만 남아있으면 단독 출근으로 출력
    if (lastStart != null) {
      result.add({'start': lastStart, 'end': null});
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('${widget.year}년 ${widget.month}월 근무 타임테이블'),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(child: CupertinoActivityIndicator())
            : _records.isEmpty
                ? const Center(child: Text('데이터가 없습니다.'))
                : ListView.builder(
                    itemCount: _pairStartEnd(_records).length,
                    itemBuilder: (context, idx) {
                      final pair = _pairStartEnd(_records)[idx];
                      final start = pair['start'];
                      final end = pair['end'];
                      String text;
                      if (start == null && end != null) {
                        text = '단독 퇴근: ${_formatDateTime(end)}';
                      } else if (start != null && end == null) {
                        text = '단독 출근: ${_formatDateTime(start)}';
                      } else if (start != null && end != null) {
                        text =
                            '출근: ${_formatDateTime(start)}  /  퇴근: ${_formatDateTime(end)}';
                      } else {
                        text = '알 수 없음';
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        child: Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.year}-${_two(dt.month)}-${_two(dt.day)} ${_two(dt.hour)}:${_two(dt.minute)}';
  }

  String _two(int n) => n.toString().padLeft(2, '0');
}
