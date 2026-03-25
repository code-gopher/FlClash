import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/v2board_provider.dart';
import 'package:fl_clash/views/payment_webview.dart';

class OrderListView extends ConsumerWidget {
  const OrderListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(v2boardOrdersProvider);

    return CommonScaffold(
      title: '我的订单',
      body: ordersAsync.when(
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('暂无订单'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(v2boardOrdersProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _OrderCard(order: order);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text('获取订单失败: $err'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(v2boardOrdersProvider),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;

  const _OrderCard({required this.order});

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '待支付';
      case 1:
        return '开通中';
      case 2:
        return '已取消';
      case 3:
        return '已完成';
      case 4:
        return '已折抵';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
      case 3:
        return Colors.green;
      case 2:
      case 4:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getPeriodText(String period) {
    switch (period) {
      case 'month_price':
        return '月付';
      case 'quarter_price':
        return '季付';
      case 'half_year_price':
        return '半年';
      case 'year_price':
        return '年付';
      case 'onetime_price':
        return '一次性';
      default:
        return period;
    }
  }

  String _formatAmount(dynamic amount) {
    if (amount == null) return '0.00';
    final value = (amount is num)
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0;
    return (value / 100).toStringAsFixed(2);
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = order['status'] as int? ?? 0;
    final plan = order['plan'] as Map<String, dynamic>?;
    final planName = plan?['name'] ?? '未知套餐';
    final period = order['period'] ?? '';
    final totalAmount = order['total_amount'];
    final tradeNo = order['trade_no'] ?? '';
    final createdAt = order['created_at'] as int? ?? 0;

    final isPending = status == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    planName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  _getPeriodText(period),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  '¥${_formatAmount(totalAmount)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '订单号: $tradeNo',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showCancelDialog(context, ref, tradeNo),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handlePay(context, ref, tradeNo),
                      child: const Text('去支付'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _showMessageDialog(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCancelDialog(
    BuildContext context,
    WidgetRef ref,
    String tradeNo,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认取消'),
        content: const Text('确定要取消这个订单吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.invalidate(v2boardOrdersProvider);
      await Future.delayed(const Duration(milliseconds: 500));

      final orders = await ref.read(v2boardOrdersProvider.future);
      final currentOrder = orders
          .where((o) => o['trade_no'] == tradeNo)
          .firstOrNull;
      if (currentOrder == null) {
        await _showMessageDialog(context, title: '提示', message: '订单不存在或已失效');
        return;
      }

      final status = currentOrder['status'] as int? ?? 0;
      if (status != 0) {
        await _showMessageDialog(
          context,
          title: '提示',
          message: '订单状态已变化，请刷新后重试',
        );
        return;
      }

      try {
        final result = await request.v2board.cancelOrder(tradeNo);
        if (result['status'] == 'success') {
          await _showMessageDialog(context, title: '成功', message: '订单已取消');
          ref.invalidate(v2boardOrdersProvider);
        } else {
          await _showMessageDialog(
            context,
            title: '提示',
            message: result['message'] ?? '取消失败',
          );
          ref.invalidate(v2boardOrdersProvider);
        }
      } catch (e) {
        String errorMsg = '取消失败';
        if (e is DioException && e.response?.data != null) {
          final data = e.response?.data;
          if (data is Map && data['message'] != null) {
            errorMsg = data['message'];
          }
        }
        await _showMessageDialog(context, title: '错误', message: errorMsg);
        ref.invalidate(v2boardOrdersProvider);
      }
    }
  }

  Future<void> _handlePay(
    BuildContext context,
    WidgetRef ref,
    String tradeNo,
  ) async {
    ref.invalidate(v2boardOrdersProvider);
    await Future.delayed(const Duration(milliseconds: 500));

    final orders = await ref.read(v2boardOrdersProvider.future);
    final currentOrder = orders
        .where((o) => o['trade_no'] == tradeNo)
        .firstOrNull;
    if (currentOrder == null) {
      await _showMessageDialog(context, title: '提示', message: '订单不存在或已失效');
      return;
    }

    final status = currentOrder['status'] as int? ?? 0;
    if (status != 0) {
      await _showMessageDialog(context, title: '提示', message: '订单状态已变化，请刷新后重试');
      return;
    }

    try {
      final paymentMethods = await request.v2board.getPaymentMethod();
      final methods = paymentMethods['data'] as List<dynamic>? ?? [];
      if (methods.isEmpty) {
        await _showMessageDialog(context, title: '提示', message: '暂无可用的支付方式');
        return;
      }

      final paymentMethodId = methods.first['id'] ?? 7;

      final payUrl = await request.v2board.checkoutOrder(
        tradeNo: tradeNo,
        method: paymentMethodId,
      );

      if (payUrl == null) {
        await _showMessageDialog(context, title: '提示', message: '获取支付链接失败');
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(
            url: payUrl,
            onPaymentComplete: () {
              ref.invalidate(v2boardOrdersProvider);
            },
          ),
        ),
      );
    } catch (e) {
      String errorMsg = '支付失败';
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        }
      }
      await _showMessageDialog(context, title: '错误', message: errorMsg);
      ref.invalidate(v2boardOrdersProvider);
    }
  }
}
