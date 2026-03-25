import 'package:fl_clash/providers/v2board_provider.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/common/common.dart';

final v2boardPlansProvider = FutureProvider<List<dynamic>>((ref) async {
  final authState = ref.watch(v2boardAuthProvider);
  if (!authState.isLogin) return [];
  try {
    final data = await request.v2board.getPlanFetch();
    return data['data'] as List<dynamic>? ?? [];
  } catch (e) {
    return [];
  }
});

String _parseHtmlString(String htmlString) {
  // 简单粗暴的正则去除HTML标签
  final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  String parsed = htmlString.replaceAll(exp, '');
  
  // 处理一些特殊字符或css残留
  parsed = parsed.replaceAll(RegExp(r'\.no-wrap\s*\{\s*white-space:pre-wrap;\s*\}'), '');
  parsed = parsed.replaceAll('&nbsp;', ' ');
  // 处理多余的空白行和空格
  parsed = parsed.replaceAll(RegExp(r'\n\s*\n+'), '\n');
  return parsed.trim();
}

class PackagesView extends ConsumerWidget {
  const PackagesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(v2boardAuthProvider);
    if (!authState.isLogin) {
      return const CommonScaffold(
        title: '套餐',
        body: Center(
          child: Text('请先在「我的」页面登录'),
        ),
      );
    }

    final plansAsync = ref.watch(v2boardPlansProvider);

    return CommonScaffold(
      title: '套餐',
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('暂无套餐数据'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              final planId = plan['id'];
              final contentHtml = plan['content'] ?? '';
              final parsedContent = _parseHtmlString(contentHtml);
              
              return Card(
                child: ListTile(
                  title: Text(plan['name'] ?? 'Unknown Plan'),
                  subtitle: Text(
                      '流量: ${plan['transfer_enable'] ?? 0} GB \n描述: $parsedContent'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      final baseUrl = authState.baseUrl ?? '';
                      if (baseUrl.isNotEmpty && planId != null) {
                        // 跳转到 V2board 网站对应的前台页面购买
                        globalState.openUrl('$baseUrl/#/stage/buysubs/order?id=$planId');
                      }
                    },
                    child: const Text('购买'),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('获取套餐失败: $err')),
      ),
    );
  }
}
