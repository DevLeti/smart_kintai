import 'package:flutter/cupertino.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  bool _isLoading = false;

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
      _isLoading = true;
    });
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null) {
        // 로그인 성공 시 supabase_provider에 정보 저장 (ProviderScope 필요)
        // 그리고 메인 페이지로 이동 (stack을 쌓지 않고)
        if (mounted) {
          // ProviderScope를 사용하려면 context를 ConsumerWidget에서 받아야 하지만,
          // 여기서는 간단히 Navigator로 이동만 처리
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
        _isLoading = false;
      });
    }
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (response.user != null) {
        // 회원가입 성공 시 supabase_provider에 정보 저장 (ProviderScope 필요)
        // 그리고 메인 페이지로 이동 (stack을 쌓지 않고)
        if (mounted) {
          _showDialog('회원가입 성공', '이메일 인증 후 로그인해주세요.');
          // 회원가입 후에는 인증 메일을 확인해야 하므로 바로 이동하지 않음
        }
      } else {
        _showDialog('회원가입 실패', '이미 가입된 이메일이거나, 입력 정보를 확인해주세요.');
      }
    } catch (e) {
      _showDialog('오류', '회원가입 중 오류가 발생했습니다.\n$e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ProviderScope가 위에 있어야 supabase_provider 사용 가능
    return CupertinoPageScaffold(
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
                ),
                const SizedBox(height: 16),
                CupertinoTextField(
                  controller: _passwordController,
                  placeholder: '비밀번호',
                  obscureText: true,
                  padding: const EdgeInsets.all(16),
                  clearButtonMode: OverlayVisibilityMode.editing,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton.filled(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('로그인'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: CupertinoButton(
                    color: CupertinoColors.activeGreen,
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? const CupertinoActivityIndicator()
                        : const Text('회원가입'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
