import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/application_setting.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/views/order_list.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show dirname, join;

import 'config/advanced.dart';
import 'developer.dart';
import 'theme.dart';
import 'package:fl_clash/providers/v2board_provider.dart';

class MineView extends ConsumerWidget {
  const MineView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscribeAsync = ref.watch(v2boardSubscribeProvider);
    final userInfoAsync = ref.watch(v2boardUserInfoProvider);
    final vm2 = ref.watch(
      appSettingProvider.select(
        (state) => VM2(state.locale, state.developerMode),
      ),
    );

    return CommonScaffold(
      title: '我的',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          userInfoAsync.when(
            data: (userInfo) {
              if (userInfo == null) return const SizedBox();
              final email = userInfo['email'] ?? 'Unknown';
              final expiredAt = userInfo['expired_at'];

              String expiredStr = '永久有效';
              if (expiredAt != null) {
                int ts = expiredAt is int
                    ? expiredAt
                    : int.tryParse(expiredAt.toString()) ?? 0;
                if (ts > 0) {
                  final date = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
                  expiredStr =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                }
              }

              return Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 32,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                subscribeAsync.when(
                                  data: (subscribeInfo) {
                                    final planName =
                                        subscribeInfo?['plan']?['name'] ??
                                        '无套餐';
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        planName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                            ),
                                      ),
                                    );
                                  },
                                  loading: () => const SizedBox(),
                                  error: (_, __) => const SizedBox(),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.logout),
                            onPressed: () {
                              ref.read(v2boardAuthProvider.notifier).logout();
                            },
                            tooltip: '退出登录',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      subscribeAsync.when(
                        data: (subscribeInfo) {
                          if (subscribeInfo == null) return const SizedBox();

                          final transferEnable =
                              subscribeInfo['transfer_enable'] ?? 0;
                          final u = subscribeInfo['u'] ?? 0;
                          final d = subscribeInfo['d'] ?? 0;
                          final nextResetAt = subscribeInfo['next_reset_at'];

                          final usedBytes =
                              (u is num
                                  ? u.toInt()
                                  : int.tryParse(u.toString()) ?? 0) +
                              (d is num
                                  ? d.toInt()
                                  : int.tryParse(d.toString()) ?? 0);
                          final totalBytes = transferEnable is num
                              ? transferEnable.toInt()
                              : int.tryParse(transferEnable.toString()) ?? 0;

                          String nextResetStr = '无';
                          if (nextResetAt != null) {
                            int ts = nextResetAt is int
                                ? nextResetAt
                                : int.tryParse(nextResetAt.toString()) ?? 0;
                            if (ts > 0) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                ts * 1000,
                              );
                              nextResetStr =
                                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                            }
                          }

                          double trafficPercent = 0;
                          String usedStr = '0 B';
                          String totalStr = '0 B';
                          if (totalBytes > 0) {
                            trafficPercent = (usedBytes / totalBytes).clamp(
                              0.0,
                              1.0,
                            );
                            usedStr = _formatBytes(usedBytes);
                            totalStr = _formatBytes(totalBytes);
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (totalBytes > 0) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '流量使用',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                    Text(
                                      '$usedStr / $totalStr',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: trafficPercent,
                                    minHeight: 8,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '到期: $expiredStr',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.refresh,
                                    size: 16,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '下次重置: $nextResetStr',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(),
                        error: (_, __) => Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '到期: $expiredStr',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Card(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (err, stack) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '获取用户信息失败',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      err.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(v2boardAuthProvider.notifier).logout();
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('退出登录'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          ..._buildSettingsList(context, ref, vm2.b),
        ],
      ),
    );
  }

  List<Widget> _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    bool enableDeveloperMode,
  ) {
    return [
      ListItem.open(
        leading: const Icon(Icons.receipt_long),
        title: const Text('我的订单'),
        delegate: const OpenDelegate(widget: OrderListView()),
      ),
      if (false) const _LocaleItem(), // 语言
      ListItem.open(
        leading: const Icon(Icons.style),
        title: const Text('系统主题'),
        delegate: const OpenDelegate(widget: ThemeView()),
      ),
      if (false && system.isDesktop)
        ListItem.open(
          leading: const Icon(Icons.keyboard),
          title: const Text('快捷键'),
          delegate: const OpenDelegate(widget: HotKeyView()),
        ),
      if (false && system.isWindows)
        ListItem(
          leading: const Icon(Icons.lock),
          title: const Text('回环访问'),
          onTap: () {
            windows?.runas(
              '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
              '',
            );
          },
        ),
      if (system.isAndroid)
        ListItem.open(
          leading: const Icon(Icons.view_list),
          title: const Text('访问控制'),
          delegate: const OpenDelegate(widget: AccessView()),
        ),
      if (false)
        ListItem.open(
          leading: const Icon(Icons.edit),
          title: const Text('基础配置'),
          delegate: const OpenDelegate(widget: ConfigView()),
        ),
      if (false)
        ListItem.open(
          leading: const Icon(Icons.build),
          title: const Text('高级配置'),
          delegate: const OpenDelegate(widget: AdvancedConfigView()),
        ),
      if (false)
        ListItem.open(
          leading: const Icon(Icons.settings),
          title: const Text('应用设置'),
          delegate: const OpenDelegate(widget: ApplicationSettingView()),
        ),
      if (false && enableDeveloperMode)
        ListItem.open(
          leading: const Icon(Icons.developer_board),
          title: const Text('开发者模式'),
          delegate: const OpenDelegate(widget: DeveloperView()),
        ),
      ListItem.open(
        leading: const Icon(Icons.info),
        title: const Text('关于'),
        delegate: const OpenDelegate(widget: AboutView()),
      ),
    ];
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

class _LocaleItem extends ConsumerWidget {
  const _LocaleItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem(
      leading: const Icon(Icons.language),
      title: const Text('语言'),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () => _showLanguageDialog(context, ref),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    final currentLocale = utils.getLocaleForString(
      ref.read(appSettingProvider.select((state) => state.locale)),
    );
    final locales = [null, ...AppLocalizations.delegate.supportedLocales];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: SizedBox(
          width: 300,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: locales.length,
            itemBuilder: (_, index) {
              final locale = locales[index];
              final isSelected = locale == currentLocale;
              final label = locale?.toString() ?? '默认';
              return ListTile(
                title: Text(label),
                trailing: isSelected ? const Icon(Icons.check) : null,
                onTap: () {
                  ref
                      .read(appSettingProvider.notifier)
                      .update(
                        (state) => state.copyWith(locale: locale?.toString()),
                      );
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
