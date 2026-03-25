import 'dart:async';
import 'package:fl_clash/views/tools.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/v2board_provider.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';

class MineView extends ConsumerStatefulWidget {
  const MineView({super.key});

  @override
  ConsumerState<MineView> createState() => _MineViewState();
}

class _MineViewState extends ConsumerState<MineView> {
  bool _isLoginMode = true; // 控制登录/注册模式切换
  int _countdown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCountdown(StateSetter setState) {
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

  void _showLoginDialog() {
    String url = 'https://cloud.lanpanyun.top'; // 固定网址
    String email = '';
    String password = '';
    String emailCode = '';
    _isLoginMode = true;
    _countdown = 0;
    _timer?.cancel();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(_isLoginMode ? '登录蓝盘云' : '注册蓝盘云'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(labelText: '邮箱'),
                      onChanged: (v) => email = v,
                    ),
                    if (!_isLoginMode) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: const InputDecoration(labelText: '验证码'),
                              onChanged: (v) => emailCode = v,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _countdown > 0
                                ? null
                                : () async {
                                    if (email.isEmpty) {
                                      globalState.showMessage(
                                          title: '提示',
                                          message: const TextSpan(text: '请先输入邮箱'));
                                      return;
                                    }
                                    try {
                                      final tempClient = request.v2board;
                                      tempClient.setBaseUrl(url);
                                      await tempClient.sendEmailVerify(email);
                                      globalState.showMessage(
                                          title: '提示',
                                          message: const TextSpan(text: '验证码发送成功'));
                                      _startCountdown(setState);
                                    } catch (e) {
                                      globalState.showMessage(
                                          title: '发送失败',
                                          message: TextSpan(text: e.toString()));
                                    }
                                  },
                            child: Text(_countdown > 0 ? '$_countdown s' : '获取验证码'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      decoration: const InputDecoration(labelText: '密码'),
                      obscureText: true,
                      onChanged: (v) => password = v,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () async {
                    try {
                      final authNotifier = ref.read(v2boardAuthProvider.notifier);
                      final tempClient = request.v2board;
                      tempClient.setBaseUrl(url);

                      String token = '';
                      if (_isLoginMode) {
                        final res = await tempClient.login(email, password);
                        token = res['data']?['auth_data']?.toString() ?? '';
                      } else {
                        final res = await tempClient.register(email, password, emailCode);
                        token = res['data']?['auth_data']?.toString() ?? '';
                      }

                      if (token.isEmpty) {
                        throw Exception('未获取到授权 Token，可能账号密码错误');
                      }

                      await authNotifier.login(url, token);
                      // 通过 getUserInfo 仅用于展示信息缓存，但要拿到真实订阅地址调用 getSubscribe
                      final userInfo = await tempClient.getUserInfo();
                      final subInfo = await tempClient.getSubscribe();
                      
                      final subscribeUrl = subInfo['data']?['subscribe_url']?.toString();
                      
                      // 登录成功后关闭弹窗
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }

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
                    }
                  },
                  child: Text(_isLoginMode ? '登录' : '注册'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(v2boardAuthProvider);
    final userInfoAsync = ref.watch(v2boardUserInfoProvider);

    return CommonScaffold(
      title: '我的',
      body: Column(
        children: [
          if (!authState.isLogin)
            ListTile(
              title: const Text('未登录'),
              subtitle: const Text('点击登录/注册获取专属订阅'),
              leading: const Icon(Icons.person_outline),
              onTap: _showLoginDialog,
            )
          else
            userInfoAsync.when(
              data: (userInfo) {
                if (userInfo == null) return const SizedBox();
                final email = userInfo['email'] ?? 'Unknown';
                final planName = userInfo['plan']?['name'] ?? '无套餐';
                final expiredAt = userInfo['expired_at'];
                
                String expiredStr = '永久有效';
                if (expiredAt != null) {
                  // 有些接口返回的是秒级时间戳
                  int ts = expiredAt is int ? expiredAt : int.tryParse(expiredAt.toString()) ?? 0;
                  if (ts > 0) {
                    final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                    expiredStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} 到期';
                  }
                }

                // 流量计算
                final transferEnable = userInfo['transfer_enable'] ?? 0;
                final u = userInfo['u'] ?? 0;
                final d = userInfo['d'] ?? 0;
                
                // v2board API 中返回的 transfer_enable、u、d 一般都是以 Bytes (字节) 为单位
                final usedBytes = (u is num ? u.toInt() : int.tryParse(u.toString()) ?? 0) + 
                                  (d is num ? d.toInt() : int.tryParse(d.toString()) ?? 0);
                final totalBytes = transferEnable is num ? transferEnable.toInt() : int.tryParse(transferEnable.toString()) ?? 0;
                
                String trafficStr = '';
                if (totalBytes > 0) {
                  final usedGb = (usedBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
                  final totalGb = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(2);
                  trafficStr = '已用: $usedGb GB / 总计: $totalGb GB';
                }

                return Column(
                  children: [
                    ListTile(
                      title: Text(email.toString()),
                      subtitle: const Text('已登录'),
                      leading: const Icon(Icons.person),
                      trailing: IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () {
                          ref.read(v2boardAuthProvider.notifier).logout();
                        },
                      ),
                    ),
                    ListTile(
                      title: Text('当前套餐: ${planName.toString()}'),
                      subtitle: Text('$expiredStr\n$trafficStr'),
                      leading: const Icon(Icons.card_membership),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => ListTile(
                title: const Text('获取用户信息失败'),
                subtitle: Text(err.toString()),
                trailing: IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    ref.read(v2boardAuthProvider.notifier).logout();
                  },
                ),
              ),
            ),
          const Divider(),
          // 这里的 ToolsView 内部是 Scaffold + ListView.builder
          // 我们把它放在 Expanded 里，整个外层去掉 ListView，改为 Column
          const Expanded(
            child: ToolsView(),
          ),
        ],
      ),
    );
  }
}
