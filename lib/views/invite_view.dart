import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/v2board_provider.dart';

class InviteView extends ConsumerStatefulWidget {
  const InviteView({super.key});

  @override
  ConsumerState<InviteView> createState() => _InviteViewState();
}

class _InviteViewState extends ConsumerState<InviteView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CommonScaffold(
      title: '推广中心',
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '邀请码'),
              Tab(text: '佣金记录'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [InviteCodesTab(), InviteDetailsTab()],
            ),
          ),
        ],
      ),
    );
  }
}

class InviteCodesTab extends ConsumerWidget {
  const InviteCodesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inviteAsync = ref.watch(inviteCodesProvider);

    return inviteAsync.when(
      data: (data) {
        final codes = data?['codes'] as List? ?? [];
        final stat = data?['stat'] as List? ?? [];

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inviteCodesProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '推广统计',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            label: '已邀请',
                            value: '${stat.isNotEmpty ? stat[0] : 0} 人',
                          ),
                          _StatItem(
                            label: '累计佣金',
                            value:
                                '¥${((stat.length > 1 ? stat[1] : 0) / 100).toStringAsFixed(2)}',
                          ),
                          _StatItem(
                            label: '待确认',
                            value:
                                '¥${((stat.length > 2 ? stat[2] : 0) / 100).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (codes.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无邀请码'),
                  ),
                )
              else
                ...codes.map((code) => _InviteCodeCard(code: code)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('获取邀请码失败: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(inviteCodesProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InviteCodeCard extends StatelessWidget {
  final Map<String, dynamic> code;

  const _InviteCodeCard({required this.code});

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final codeStr = code['code'] as String? ?? '';
    final status = code['status'] as bool? ?? false;
    final createdAt = code['created_at'] as int? ?? 0;
    final pv = code['pv'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    codeStr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: codeStr));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('邀请码 $codeStr 已复制'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: status
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status ? '已激活' : '未激活',
                    style: TextStyle(
                      color: status ? Colors.green : Colors.orange,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('使用次数: $pv', style: Theme.of(context).textTheme.bodySmall),
                const Spacer(),
                Text(
                  '创建: ${_formatTime(createdAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InviteDetailsTab extends ConsumerWidget {
  const InviteDetailsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(inviteDetailsProvider);

    return detailsAsync.when(
      data: (data) {
        final details = data?['data'] as List? ?? [];
        final total = data?['total'] as int? ?? 0;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(inviteDetailsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '佣金总计',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '¥${(total / 100).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 $total 条记录',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (details.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('暂无佣金记录'),
                  ),
                )
              else
                ...details.map((detail) => _DetailCard(detail: detail)),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text('获取佣金记录失败: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(inviteDetailsProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final Map<String, dynamic> detail;

  const _DetailCard({required this.detail});

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final orderAmount = detail['order_amount'] as int? ?? 0;
    final getAmount = detail['get_amount'] as int? ?? 0;
    final tradeNo = detail['trade_no'] as String? ?? '';
    final createdAt = detail['created_at'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '订单金额: ¥${(orderAmount / 100).toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '+¥${(getAmount / 100).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '订单号: $tradeNo',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
