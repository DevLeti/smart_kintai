import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:smart_kintai/screens/work.dart';
import 'package:smart_kintai/screens/my_info.dart';
import 'package:smart_kintai/screens/work_check.dart'; // WorkCheck import 추가

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  String _selectedTitle = '근무';

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
    // 각 탭에 맞는 타이틀과 위젯을 미리 결정
    String newTitle;
    Widget body;
    switch (_selectedIndex) {
      case 0:
        newTitle = '근무';
        body = const Work();
        break;
      case 1:
        newTitle = '근무확인';
        body = WorkCheck();
        break;
      case 2:
        newTitle = '내 정보';
        body = const MyInfo();
        break;
      default:
        newTitle = '근무';
        body = const Work();
    }

    // 타이틀이 바뀌었을 때만 setState 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedTitle != newTitle) {
        setState(() {
          _selectedTitle = newTitle;
        });
      }
    });

    return body;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(_selectedTitle),
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
                  icon: Icon(CupertinoIcons.calendar),
                  label: '근무확인',
                ),
                BottomNavigationBarItem(
                  icon: Icon(CupertinoIcons.person),
                  label: '내 정보',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
