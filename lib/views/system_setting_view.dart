import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/controller.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/application_setting.dart';
import 'package:fl_clash/views/config/config.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' show dirname, join;

import 'config/advanced.dart';
import 'developer.dart';
import 'theme.dart';

class SystemSettingView extends ConsumerWidget {
  const SystemSettingView({super.key});

  Future<void> _checkUpdate(BuildContext context) async {
    final data = await appController.safeRun<Map<String, dynamic>?>(
      request.checkForUpdate,
      title: appLocalizations.checkUpdate,
    );
    appController.checkUpdateResultHandle(data: data, isUser: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonScaffold(
      title: '系统设置',
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (false) const _LocaleItem(),
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
          ListItem(
            leading: const Icon(Icons.system_update),
            title: const Text('检查更新'),
            onTap: () => _checkUpdate(context),
          ),
          ListItem.open(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            delegate: const OpenDelegate(widget: AboutView()),
          ),
        ],
      ),
    );
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
