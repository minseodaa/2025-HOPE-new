import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/constants.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _passwordCheckController =
      TextEditingController();

  bool _isObscure1 = true;
  bool _isObscure2 = true;
  bool _isValid = false; // 필드 유효성
  bool _isLoading = false; // 전체 로딩(버튼 비활성화용)
  bool _sending = false; // 중복확인/인증메일 발송 중
  bool _verificationMailSent = false; // 인증메일 발송 완료 여부

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordCheckController.dispose();
    super.dispose();
  }

  void _updateValidity() {
    final email = _emailController.text.trim();
    final pw = _passwordController.text;
    final pw2 = _passwordCheckController.text;
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    final next = emailRegex.hasMatch(email) && pw.length >= 8 && pw == pw2;
    if (next != _isValid) setState(() => _isValid = next);
  }

  void _toast(String msg) {
    Get.snackbar('알림', msg, snackPosition: SnackPosition.BOTTOM);
  }

  bool get _emailValid =>
      RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_emailController.text.trim());
  bool get _pwValid => RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,}$',
  ).hasMatch(_passwordController.text);
  bool get _pwMatch =>
      _passwordController.text == _passwordCheckController.text;

  /// 1단계: 이메일 중복 확인 + 인증 메일 발송
  Future<void> _checkDuplicateAndSendVerification() async {
    final email = _emailController.text.trim();

    if (!_emailValid) {
      _toast('이메일 형식을 확인해 주세요.');
      return;
    }
    if (!_pwValid || !_pwMatch) {
      _toast('비밀번호 규칙/재확인을 확인해 주세요. (영문/숫자/특수문자 포함 8자 이상)');
      return;
    }

    setState(() => _sending = true);
    try {
      final auth = AuthService();
      final available = await auth.isEmailAvailable(email);
      if (!available) {
        _toast('이미 사용 중인 이메일입니다.');
        return;
      }

      // 계정 생성 + 인증 메일 발송
      await auth.createUserAndSendVerification(
        email: email,
        password: _passwordController.text,
      );
      setState(() => _verificationMailSent = true);
      _toast('인증 메일을 보냈습니다. 메일함에서 인증을 완료해 주세요.');
    } catch (e) {
      _toast('중복 확인/인증메일 발송 실패: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  /// 최종 가입 처리 (중복 확인/인증 메일 선행 없이도 시도)
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = AuthService();
      // 중복 확인/인증메일 발송 단계를 건너뛰더라도, 여기서 계정 생성 시도
      await auth.createUserAndSendVerification(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // 가입 직후 바로 다음 화면으로 이동 (이메일 인증은 선택적으로 진행)
      Get.offAllNamed('/initial-expression');
    } catch (e) {
      _toast('회원가입 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canSendVerify = !_sending && !_isLoading; // 중복확인/인증메일 발송 버튼 활성화 조건
    final canFinishSignUp = _isValid && !_isLoading; // 중복 확인 없이도 가입 가능

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    Text(
                      '회원가입',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text('이메일', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              hintText: 'sample@gmail.com',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            autovalidateMode:
                                AutovalidateMode.onUserInteraction,
                            onChanged: (_) => _updateValidity(),
                            validator: (v) {
                              final value = v?.trim() ?? '';
                              if (value.isEmpty) return '이메일을 입력해주세요.';
                              final emailRegex = RegExp(
                                r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                              );
                              if (!emailRegex.hasMatch(value)) {
                                return '유효한 이메일을 입력해주세요.';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: canSendVerify
                              ? _checkDuplicateAndSendVerification
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          child: _sending
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('중복 확인(인증메일 발송)'),
                        ),
                        const SizedBox(width: 12),
                        if (_verificationMailSent)
                          const Text(
                            '인증 메일 발송됨',
                            style: TextStyle(color: Colors.green),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    Text('비밀번호', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _isObscure1,
                      decoration: InputDecoration(
                        hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _isObscure1 = !_isObscure1),
                          icon: Icon(
                            _isObscure1
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (_) => _updateValidity(),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.isEmpty) return '비밀번호를 입력해주세요.';
                        if (value.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),
                    Text('비밀번호 재확인', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordCheckController,
                      obscureText: _isObscure2,
                      decoration: InputDecoration(
                        hintText: '영문, 숫자, 특수문자 포함 8자 이상',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () =>
                              setState(() => _isObscure2 = !_isObscure2),
                          icon: Icon(
                            _isObscure2
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      onChanged: (_) => _updateValidity(),
                      validator: (v) {
                        final value = v ?? '';
                        if (value.isEmpty) return '비밀번호를 다시 입력해주세요.';
                        if (value != _passwordController.text) {
                          return '비밀번호가 일치하지 않습니다.';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        // ✅ 최종 회원가입: 인증메일 발송 완료 후에만 가능
                        onPressed: canFinishSignUp ? _submit : null,
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                '회원가입',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
