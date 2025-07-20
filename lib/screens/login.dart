import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
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
  final formKey = GlobalKey<ShadFormState>();

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
      setState(() {
        formKey.currentState!.fields['email']?.didChange(savedId);
        _saveId = true;
      });
    }
  }

  Future<void> _setSavedId(bool value, [String? email]) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setString(
          'saved_email', email ?? (formKey.currentState?.value['email'] ?? ''));
      await prefs.setBool('save_id_checked', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('save_id_checked', false);
    }
  }

  void _showDialog(String title, String content) {
    showShadDialog(
      context: context,
      builder: (context) {
        return ShadDialog.alert(
          title: Text(title),
          description: Text(content),
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

  Future<void> _login(Map<dynamic, dynamic> values) async {
    setState(() {
      _isLoginLoading = true;
    });
    try {
      final email = values['email']?.toString().trim() ?? '';
      final password = values['password'] ?? '';
      if (_saveId) {
        await _setSavedId(true, email);
      } else {
        await _setSavedId(false);
      }
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
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
      // e.code가 invalid_credentials인지 확인하는 코드
      if (e is AuthException && e.code == 'invalid_credentials') {
        _showDialog('로그인 실패', '이메일 또는 비밀번호가 올바르지 않습니다.');
        return;
      } else {
        _showDialog('오류', '로그인 중 오류가 발생했습니다.\n');
        if (kDebugMode) {
          print(e);
        }
      }
    } finally {
      setState(() {
        _isLoginLoading = false;
      });
    }
  }

  Future<void> _signUp(Map<dynamic, dynamic> values) async {
    setState(() {
      _isSignUpLoading = true;
    });
    try {
      final email = values['email']?.toString().trim() ?? '';
      final password = values['password'] ?? '';
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
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
              child: ShadForm(
                key: formKey,
                initialValue: const {},
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ShadInputFormField(
                        id: 'email',
                        label: const Text('이메일'),
                        placeholder: const Text('이메일을 입력하세요'),
                        keyboardType: TextInputType.emailAddress,
                        padding: const EdgeInsets.all(16),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return '이메일을 입력해주세요.';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return '올바른 이메일 형식이 아닙니다.';
                          }
                          return null;
                        },
                        onChanged: (value) {
                          if (_saveId) {
                            _setSavedId(true, value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      ShadInputFormField(
                        id: 'password',
                        label: const Text('비밀번호'),
                        placeholder: const Text('비밀번호를 입력하세요'),
                        obscureText: true,
                        padding: const EdgeInsets.all(16),
                        validator: (v) {
                          if (v.isEmpty) {
                            return '비밀번호를 입력해주세요.';
                          }
                          if (v.length < 6) {
                            return '비밀번호는 6자 이상이어야 합니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          setState(() {
                            _saveId = !_saveId;
                          });
                          final email =
                              formKey.currentState?.value['email'] ?? '';
                          await _setSavedId(_saveId, email);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ShadSwitch(
                              value: _saveId,
                              onChanged: (value) async {
                                setState(() {
                                  _saveId = value;
                                });
                                final email =
                                    formKey.currentState?.value['email'] ?? '';
                                await _setSavedId(value, email);
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
                        child: ShadButton(
                          onPressed: _isLoginLoading
                              ? null
                              : () {
                                  if (formKey.currentState!.saveAndValidate()) {
                                    _login(formKey.currentState!.value);
                                  }
                                },
                          child: _isLoginLoading
                              ? const CupertinoActivityIndicator()
                              : const Text('로그인'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          backgroundColor: CupertinoColors.activeGreen,
                          onPressed: _isSignUpLoading
                              ? null
                              : () {
                                  if (formKey.currentState!.saveAndValidate()) {
                                    _signUp(formKey.currentState!.value);
                                  }
                                },
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
        ),
      ),
    );
  }
}
