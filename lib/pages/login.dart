import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/providers/v2board_provider.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _isLoginMode = true;
  int _countdown = 0;
  Timer? _timer;
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _obscurePassword = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailCodeController = TextEditingController();
  final _inviteCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _emailCodeController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool('remember_me') ?? false;
      if (remember) {
        final email = prefs.getString('saved_email') ?? '';
        final password = prefs.getString('saved_password') ?? '';
        setState(() {
          _rememberMe = true;
          _emailController.text = email;
          _passwordController.text = password;
        });
      }
    } catch (e) {
      // 忽略加载错误
    }
  }

  Future<void> _saveCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setString('saved_password', _passwordController.text);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('saved_email');
        await prefs.remove('saved_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      // 忽略保存错误
    }
  }

  void _startCountdown() {
    setState(() {
      _countdown = 60;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;

    final url = 'https://cloud.lanpanyun.top';
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailCode = _emailCodeController.text.trim();

    if (email.isEmpty) {
      globalState.showMessage(
        title: '提示',
        message: const TextSpan(text: '请输入邮箱'),
      );
      return;
    }

    if (password.isEmpty) {
      globalState.showMessage(
        title: '提示',
        message: const TextSpan(text: '请输入密码'),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authNotifier = ref.read(v2boardAuthProvider.notifier);
      final tempClient = request.v2board;
      tempClient.setBaseUrl(url);

      String token = '';
      if (_isLoginMode) {
        final res = await tempClient.login(email, password);
        token = res['data']?['auth_data']?.toString() ?? '';
      } else {
        if (emailCode.isEmpty) {
          globalState.showMessage(
            title: '提示',
            message: const TextSpan(text: '请输入验证码'),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
        final res = await tempClient.register(
          email,
          password,
          emailCode,
          inviteCode: _inviteCodeController.text.trim(),
        );
        token = res['data']?['auth_data']?.toString() ?? '';
      }

      if (token.isEmpty) {
        throw Exception('未获取到授权 Token，可能账号密码错误');
      }

      await authNotifier.login(url, token);

      // 保存凭证
      await _saveCredentials();

      // 获取订阅信息
      final subInfo = await tempClient.getSubscribe();
      final subscribeUrl = subInfo['data']?['subscribe_url']?.toString();

      if (subscribeUrl != null && subscribeUrl.isNotEmpty) {
        await authNotifier.autoImportSubscription(subscribeUrl);
      } else {
        globalState.showMessage(
          title: '提示',
          message: const TextSpan(text: '未获取到订阅链接，可能需要先购买套餐'),
        );
      }
    } catch (e) {
      globalState.showMessage(
        title: _isLoginMode ? '登录失败' : '注册失败',
        message: TextSpan(text: e.toString()),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 48),
                Icon(
                  Icons.shield_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  '蓝盘云',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '登录后获取专属订阅',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                if (!_isLoginMode) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _emailCodeController,
                          decoration: const InputDecoration(
                            labelText: '验证码',
                            prefixIcon: Icon(Icons.verified_user_outlined),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _countdown > 0
                            ? null
                            : () async {
                                final email = _emailController.text.trim();
                                if (email.isEmpty) {
                                  globalState.showMessage(
                                    title: '提示',
                                    message: const TextSpan(text: '请先输入邮箱'),
                                  );
                                  return;
                                }
                                try {
                                  final tempClient = request.v2board;
                                  tempClient.setBaseUrl(
                                    'https://cloud.lanpanyun.top',
                                  );
                                  await tempClient.sendEmailVerify(email);
                                  globalState.showMessage(
                                    title: '提示',
                                    message: const TextSpan(text: '验证码发送成功'),
                                  );
                                  _startCountdown();
                                } catch (e) {
                                  globalState.showMessage(
                                    title: '发送失败',
                                    message: TextSpan(text: e.toString()),
                                  );
                                }
                              },
                        child: Text(_countdown > 0 ? '$_countdown s' : '获取验证码'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: '密码',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                ),
                if (!_isLoginMode) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: _inviteCodeController,
                    decoration: const InputDecoration(
                      labelText: '邀请码（选填）',
                      prefixIcon: Icon(Icons.card_giftcard_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (_isLoginMode)
                  CheckboxListTile(
                    value: _rememberMe,
                    onChanged: (value) {
                      setState(() {
                        _rememberMe = value ?? false;
                      });
                    },
                    title: const Text('记住我'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  )
                else
                  const SizedBox(height: 8),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmit,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLoginMode ? '登录' : '注册'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                    });
                  },
                  child: Text(_isLoginMode ? '没有账号？去注册' : '已有账号？去登录'),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
