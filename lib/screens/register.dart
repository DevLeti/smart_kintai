import 'package:flutter/cupertino.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final formKey = GlobalKey<ShadFormState>();
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isSignUpLoading = false;

  final List<Map<String, String>> workTypes = [
    {'value': 'fixed', 'label': '고정근무'},
    {'value': 'flex', 'label': '유연근무 (코어타임 O)'},
    {'value': 'full-flex', 'label': '유연근무 (코어타임 X)'},
  ];

  Future<void> _signUp(Map<dynamic, dynamic> values) async {
    setState(() {
      _isSignUpLoading = true;
    });
    try {
      final email = values['email']?.toString().trim() ?? '';
      final password = values['password'] ?? '';
      final familyName = values['familyName']?.toString().trim() ?? '';
      final givenName = values['givenName']?.toString().trim() ?? '';
      final workType = values['workType'] ?? '';

      print('email: $email');
      print('password: $password');
      print('familyName: $familyName');
      print('givenName: $givenName');
      print('workType: $workType');

      if (email.isEmpty || password.isEmpty) {
        showShadDialog(
          context: context,
          builder: (context) {
            return ShadDialog.alert(
              title: const Text('오류'),
              description: const Text('이메일과 비밀번호를 입력해주세요.'),
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
        setState(() {
          _isSignUpLoading = false;
        });
        return;
      }

      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        try {
          final userId = response.user!.id;
          await _supabase.from('kintai_profile').insert({
            'uid': userId,
            'family_name': familyName,
            'given_name': givenName,
            'work_type': workType,
          });
        } catch (e) {
          // 프로필 저장 실패 시 사용자에게 알림 (회원가입은 성공)
          showShadDialog(
            context: context,
            builder: (context) {
              return ShadDialog.alert(
                title: const Text('경고'),
                description:
                    const Text('프로필 정보 저장에 실패했습니다. 마이페이지에서 다시 입력해주세요.'),
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
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/',
            (Route<dynamic> route) => false,
          );
        }
      }
    } catch (e) {
      if (e is AuthException && e.code == 'user_already_exists') {
        showShadDialog(
          context: context,
          builder: (context) {
            return ShadDialog.alert(
              title: const Text('회원가입 실패'),
              description: const Text('이미 가입된 이메일이거나, 입력 정보를 확인해주세요.'),
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
      showShadDialog(
        context: context,
        builder: (context) {
          return ShadDialog.alert(
            title: const Text('오류'),
            description: const Text('회원가입 중 오류가 발생했습니다.'),
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
          middle: Text('회원가입'),
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
                          if (v.trim().isEmpty) {
                            return '이메일을 입력해주세요.';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                              .hasMatch(v.trim())) {
                            return '올바른 이메일 형식이 아닙니다.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // 비밀번호 입력 필드 추가
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
                      const SizedBox(height: 16),
                      ShadInputFormField(
                        id: 'familyName',
                        label: const Text('성'),
                        placeholder: const Text('성을 입력하세요'),
                        padding: const EdgeInsets.all(16),
                        validator: (v) {
                          if (v.trim().isEmpty) {
                            return '성을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ShadInputFormField(
                        id: 'givenName',
                        label: const Text('이름'),
                        placeholder: const Text('이름을 입력하세요'),
                        padding: const EdgeInsets.all(16),
                        validator: (v) {
                          if (v.trim().isEmpty) {
                            return '이름을 입력해주세요.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      ShadSelectFormField<String>(
                        minWidth: double.infinity,
                        id: 'workType',
                        initialValue: null,
                        label: const Text('근무형태'),
                        placeholder: const Text('근무형태를 선택하세요'),
                        selectedOptionBuilder: (context, value) {
                          if (value == 'none') {
                            return const Text('근무형태를 선택하세요');
                          }
                          // value에 해당하는 label을 찾아서 보여줌
                          final selected = workTypes.firstWhere(
                            (type) => type['value'] == value,
                            orElse: () => {'label': value},
                          );
                          return Text(selected['label'] ?? value);
                        },
                        options: workTypes
                            .map((type) => ShadOption(
                                  value: type['value']!,
                                  child: Text(type['label']!),
                                ))
                            .toList(),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return '근무형태를 선택해주세요.';
                          }
                          return null;
                        },
                        padding: const EdgeInsets.all(16),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ShadButton(
                          onPressed: _isSignUpLoading
                              ? null
                              : () {
                                  if (formKey.currentState!.saveAndValidate()) {
                                    _signUp(formKey.currentState!.value);
                                  }
                                },
                          child: _isSignUpLoading
                              ? const CupertinoActivityIndicator()
                              : const Text('저장'),
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
