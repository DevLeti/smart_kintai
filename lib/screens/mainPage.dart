import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_kintai/screens/work.dart';
import 'package:smart_kintai/screens/myInfo.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  // 로그아웃 확인 다이얼로그 함수
  Future<void> _showLogoutDialog() async {
    final result = await showShadDialog<bool>(
      context: context,
      builder: (context) {
        return ShadDialog.alert(
          title: const Text('로그아웃'),
          description: const Text('정말 로그아웃 하시겠습니까?'),
          actions: [
            ShadButton(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ShadButton.outline(
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
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  // 바텀 네비게이션 바에서 보여줄 위젯들
  Widget _buildBody() {
    // 0번(근무) 탭에 Work 위젯, 1번(내 정보) 탭에 MyInfoPage 위젯 사용
    switch (_selectedIndex) {
      case 0:
        return const Work();
      case 1:
        return const MyInfo();
      default:
        return const Work();
    }
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
      child: SafeArea(
        child: Column(
          children: [
            // 메인 컨텐츠
            Expanded(
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
            ),
            // 바텀 네비게이션 바
            CupertinoTabBar(
              currentIndex: _selectedIndex,
              backgroundColor: Colors.white,
              onTap: (int index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.clock),
                  label: '근무',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: '내 정보',
                ),
                // 필요시 추가
              ],
            ),
          ],
        ),
      ),
    );
  }
}
