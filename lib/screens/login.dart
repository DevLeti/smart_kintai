import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'mainPage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoginLoading = false;
  bool _isSignUpLoading = false;
  bool _saveId = false;

  @override
  void initState() {
    super.initState();
    _loadSavedId();
  }

  Future<void> _loadSavedId() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('saved_email');
    final saveIdChecked = prefs.getBool('save_id_checked') ?? false;
    if (savedId != null && saveIdChecked) {
      _emailController.text = savedId;
      setState(() {
        _saveId = true;
      });
    }
  }

  Future<void> _setSavedId(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setString('saved_email', _emailController.text.trim());
      await prefs.setBool('save_id_checked', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('save_id_checked', false);
    }
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
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

  Future<void> _login() async {
    setState(() {
      _isLoginLoading = true;
    });
    try {
      if (_saveId) {
        await _setSavedId(true);
      } else {
        await _setSavedId(false);
      }
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const MainPage()),
          );
        }
      } else {
        _showDialog('로그인 실패', '이메일 또는 비밀번호를 확인해주세요.');
      }
    } catch (e) {
      _showDialog('오류', '로그인 중 오류가 발생했습니다.\n$e');
    } finally {
      setState(() {
        _isLoginLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isSignUpLoading = true;
    });
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null) {
        if (mounted) {
          _showDialog('회원가입 성공', '이메일 인증 후 로그인해주세요.');
        }
      } else {
        _showDialog('회원가입 실패', '이미 가입된 이메일이거나, 입력 정보를 확인해주세요.');
      }
    } catch (e) {
      _showDialog('오류', '회원가입 중 오류가 발생했습니다.\n$e');
    } finally {
      setState(() {
        _isSignUpLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // TODO: 프레임드랍 해결
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('로그인 / 회원가입'),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CupertinoTextField(
                    controller: _emailController,
                    placeholder: '이메일',
                    keyboardType: TextInputType.emailAddress,
                    padding: const EdgeInsets.all(16),
                    clearButtonMode: OverlayVisibilityMode.editing,
                    onChanged: (value) {
                      if (_saveId) {
                        _setSavedId(true);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: '비밀번호',
                    obscureText: true,
                    padding: const EdgeInsets.all(16),
                    clearButtonMode: OverlayVisibilityMode.editing,
                  ),
                  const SizedBox(height: 12),
                  // 가운데 정렬된 ID 저장 Row, Row 전체가 setState 하도록 GestureDetector로 감쌈
                  GestureDetector(
                    onTap: () async {
                      // 진동 피드백 추가
                      HapticFeedback.lightImpact();
                      setState(() {
                        _saveId = !_saveId;
                      });
                      await _setSavedId(_saveId);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoSwitch(
                          value: _saveId,
                          onChanged: (value) async {
                            setState(() {
                              _saveId = value;
                            });
                            await _setSavedId(value);
                          },
                        ),
                        const SizedBox(width: 8),
                        const Text('ID 저장'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20.0),
                    child: Container(
                      width: double.infinity,
                      height: 1,
                      color: CupertinoColors.systemGrey4,
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton.filled(
                      onPressed: _isLoginLoading ? null : _login,
                      child: _isLoginLoading
                          ? const CupertinoActivityIndicator()
                          : const Text('로그인'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: CupertinoColors.activeGreen,
                      onPressed: _isSignUpLoading ? null : _signUp,
                      child: _isSignUpLoading
                          ? const CupertinoActivityIndicator()
                          : const Text('회원가입'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
