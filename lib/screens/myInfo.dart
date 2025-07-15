import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyInfo extends StatefulWidget {
  const MyInfo({super.key});

  @override
  State<MyInfo> createState() => _MyInfoState();
}

class _MyInfoState extends State<MyInfo> {
  final SupabaseClient _supabase = Supabase.instance.client;

  String? _familyName;
  String? _givenName;
  String? _workType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoading = true;
    });

    final user = _supabase.auth.currentUser;
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      // 세션 만료 등 처리 필요시 여기에 추가
      return;
    }

    final response = await _supabase
        .from('kintai_profile')
        .select('family_name, given_name, work_type')
        .eq('uid', user.id)
        .maybeSingle();

    if (response != null) {
      setState(() {
        _familyName = response['family_name'] ?? '';
        _givenName = response['given_name'] ?? '';
        _workType = response['work_type'] ?? '';
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  WorkType? _parseWorkType(String? workType) {
    switch (workType) {
      case 'fixed':
        return WorkType.fixed;
      case 'flex':
        return WorkType.flex;
      case 'full-flex':
        return WorkType.fullFlex;
      default:
        return null;
    }
  }

  String _getWorkTypeKorean(WorkType? workType) {
    switch (workType) {
      case WorkType.fixed:
        return '고정근무';
      case WorkType.flex:
        return '유연근무 (코어타임 O)';
      case WorkType.fullFlex:
        return '유연근무 (코어타임 X)';
      default:
        return '알 수 없음';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_familyName == null || _givenName == null || _workType == null) {
      return const Center(
        child: Text(
          '프로필 정보를 불러올 수 없습니다.',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final fullName = '${_familyName!} ${_givenName!}';
    final workTypeKor = _getWorkTypeKorean(_workType);

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Text(
          '안녕하세요, $fullName님!',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '$fullName님의 근무 형태는 \'$workTypeKor\'입니다!',
          style: const TextStyle(
            fontSize: 18,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}
