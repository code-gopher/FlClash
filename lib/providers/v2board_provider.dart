import 'package:fl_clash/common/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/controller.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/enum/enum.dart';

import 'package:flutter/material.dart';

class V2boardAuthState {
  final String? baseUrl;
  final String? token;
  final bool isLoading;

  V2boardAuthState({this.baseUrl, this.token, this.isLoading = true});

  V2boardAuthState copyWith({String? baseUrl, String? token, bool? isLoading}) {
    return V2boardAuthState(
      baseUrl: baseUrl ?? this.baseUrl,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isLogin => token != null && token!.isNotEmpty;
}

class V2boardAuthNotifier extends Notifier<V2boardAuthState> {
  @override
  V2boardAuthState build() {
    _init();
    return V2boardAuthState();
  }

  Future<void> _init() async {
    final url = await preferences.getV2boardBaseUrl();
    final token = await preferences.getV2boardToken();
    if (url != null) {
      request.v2board.setBaseUrl(url);
    }
    if (token != null) {
      request.v2board.setToken(token);
    }
    state = V2boardAuthState(baseUrl: url, token: token, isLoading: false);
  }

  Future<void> login(String url, String token) async {
    await preferences.saveV2boardAuth(url, token);
    request.v2board.setBaseUrl(url);
    request.v2board.setToken(token);
    state = state.copyWith(baseUrl: url, token: token);
  }

  Future<void> autoImportSubscription(String subscribeUrl) async {
    if (subscribeUrl.isEmpty) {
      // await globalState.showMessage(
      //   title: '导入提示',
      //   message: const TextSpan(text: '订阅链接为空，放弃导入。'),
      // );
      return;
    }
    try {
      // await globalState.showMessage(
      //   title: '导入提示',
      //   message: TextSpan(text: '开始检查订阅链接: $subscribeUrl'),
      // );

      // 检查是否已经有 profile，如果有直接更新，没有就新建
      final profiles = appController.ref.read(profilesStateProvider).profiles;
      final existingProfile = profiles
          .where((p) => p.url == subscribeUrl)
          .firstOrNull;

      if (existingProfile != null) {
        // await globalState.showMessage(
        //   title: '导入提示',
        //   message: TextSpan(text: '发现已存在的 Profile (ID: ${existingProfile.id})，准备更新...'),
        // );
        await appController.updateProfile(existingProfile, showLoading: true);
        appController.ref.read(currentProfileIdProvider.notifier).value =
            existingProfile.id;
      } else {
        // await globalState.showMessage(
        //   title: '导入提示',
        //   message: const TextSpan(text: '这是一个新的订阅链接，准备下载创建 Profile...'),
        // );

        // 由于 appController.addProfileFormURL 内部会调用 pop() 和 toPage，可能会引发问题
        // 这里我们直接复用底层创建逻辑
        final profile = await appController.loadingRun(tag: null, () async {
          return await Profile.normal(
            url: subscribeUrl,
            label: '我的订阅',
          ).update();
        }, title: '导入配置...');

        if (profile != null) {
          // await globalState.showMessage(
          //   title: '导入提示',
          //   message: TextSpan(text: '配置下载成功，保存至数据库 (ID: ${profile.id})'),
          // );
          appController.putProfile(profile);
          appController.ref.read(currentProfileIdProvider.notifier).value =
              profile.id;
        } else {
          // await globalState.showMessage(
          //   title: '导入提示',
          //   message: const TextSpan(text: '配置下载失败，profile 为 null。'),
          // );
        }
      }

      // await globalState.showMessage(
      //   title: '导入提示',
      //   message: const TextSpan(text: '准备调用 autoApplyProfile() 刷新核心节点'),
      // );
      appController.autoApplyProfile();

      // 导入成功后自动跳转到代理页面
      appController.toPage(PageLabel.proxies);
    } catch (e) {
      commonPrint.log('V2board auto import subscription failed: $e');
      // await globalState.showMessage(
      //   title: '导入崩溃异常',
      //   message: TextSpan(text: '错误信息: $e'),
      // );
    }
  }

  Future<void> logout() async {
    final currentBaseUrl = state.baseUrl;

    // 删除由 V2Board 导入的 profiles
    if (currentBaseUrl != null && currentBaseUrl.isNotEmpty) {
      final profiles = appController.ref.read(profilesStateProvider).profiles;
      final currentProfileId = appController.ref.read(currentProfileIdProvider);

      for (final profile in profiles) {
        // 检查 profile 的 URL 是否包含 V2Board 的 baseUrl
        if (profile.url.isNotEmpty && profile.url.contains(currentBaseUrl)) {
          // 如果当前选中的 profile 是这个，则清空选择
          if (currentProfileId == profile.id) {
            appController.ref.read(currentProfileIdProvider.notifier).value =
                null;
          }
          // 删除该 profile
          await appController.deleteProfile(profile.id);
        }
      }

      // 停止核心
      await globalState.handleStop();
    }

    // 清理认证信息
    await preferences.saveV2boardAuth(null, null);
    request.v2board.setBaseUrl('');
    request.v2board.setToken(null);
    state = V2boardAuthState(isLoading: false);
  }
}

final v2boardAuthProvider =
    NotifierProvider<V2boardAuthNotifier, V2boardAuthState>(
      V2boardAuthNotifier.new,
    );

// 用于缓存用户信息
final v2boardUserInfoProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final authState = ref.watch(v2boardAuthProvider);
  if (!authState.isLogin) return null;
  try {
    final data = await request.v2board.getUserInfo();
    return data['data'];
  } catch (e) {
    return null;
  }
});

// 用于缓存订阅信息
final v2boardSubscribeProvider = FutureProvider<Map<String, dynamic>?>((
  ref,
) async {
  final authState = ref.watch(v2boardAuthProvider);
  if (!authState.isLogin) return null;
  try {
    final data = await request.v2board.getSubscribe();
    return data['data'];
  } catch (e) {
    return null;
  }
});

// 用于缓存支付方式列表
final v2boardPaymentMethodsProvider = FutureProvider<List<dynamic>>((
  ref,
) async {
  final authState = ref.watch(v2boardAuthProvider);
  if (!authState.isLogin) return [];
  try {
    final data = await request.v2board.getPaymentMethod();
    return data['data'] ?? [];
  } catch (e) {
    return [];
  }
});

// 用于缓存订单列表
final v2boardOrdersProvider = FutureProvider<List<dynamic>>((ref) async {
  final authState = ref.watch(v2boardAuthProvider);
  if (!authState.isLogin) return [];
  try {
    final data = await request.v2board.getOrderList();
    return data['data'] as List<dynamic>? ?? [];
  } catch (e) {
    return [];
  }
});
