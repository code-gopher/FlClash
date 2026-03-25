import 'package:dio/dio.dart';
import 'package:fl_clash/providers/v2board_provider.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/views/payment_webview.dart';

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
  final RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
  String parsed = htmlString.replaceAll(exp, '');
  parsed = parsed.replaceAll(
    RegExp(r'\.no-wrap\s*\{\s*white-space:pre-wrap;\s*\}'),
    '',
  );
  parsed = parsed.replaceAll('&nbsp;', ' ');
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
        body: Center(child: Text('请先在「我的」页面登录')),
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
              final contentHtml = plan['content'] ?? '';
              final parsedContent = _parseHtmlString(contentHtml);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['name'] ?? 'Unknown Plan',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '流量: ${plan['transfer_enable'] ?? 0} GB',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (parsedContent.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          parsedContent,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _showPurchaseDialog(context, plan);
                          },
                          child: const Text('购买'),
                        ),
                      ),
                    ],
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

  void _showPurchaseDialog(BuildContext context, Map<String, dynamic> plan) {
    showDialog(
      context: context,
      builder: (context) => PurchaseDialog(plan: plan),
    );
  }
}

class PurchaseDialog extends StatefulWidget {
  final Map<String, dynamic> plan;

  const PurchaseDialog({super.key, required this.plan});

  @override
  State<PurchaseDialog> createState() => _PurchaseDialogState();
}

class _PurchaseDialogState extends State<PurchaseDialog> {
  String _selectedPeriod = 'year_price';
  bool _isLoading = false;
  int _paymentMethodId = 0;

  bool get _isOneTimePlan {
    final monthPrice = widget.plan['month_price'];
    final quarterPrice = widget.plan['quarter_price'];
    final halfYearPrice = widget.plan['half_year_price'];
    final yearPrice = widget.plan['year_price'];
    final oneTimePrice = widget.plan['onetime_price'];

    final hasRecurring =
        (monthPrice != null && monthPrice != 0) ||
        (quarterPrice != null && quarterPrice != 0) ||
        (halfYearPrice != null && halfYearPrice != 0) ||
        (yearPrice != null && yearPrice != 0);

    return !hasRecurring && oneTimePrice != null && oneTimePrice != 0;
  }

  double get _currentPrice {
    if (_isOneTimePlan) {
      final price = widget.plan['onetime_price'];
      if (price == null) return 0;
      return (price is num)
          ? price.toDouble() / 100
          : (double.tryParse(price.toString()) ?? 0) / 100;
    }
    final price = widget.plan[_selectedPeriod];
    if (price == null) return 0;
    final rawPrice = (price is num)
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;
    return rawPrice / 100;
  }

  double _getPeriodPrice(String period) {
    final price = widget.plan[period];
    if (price == null) return 0;
    final rawPrice = (price is num)
        ? price.toDouble()
        : double.tryParse(price.toString()) ?? 0;
    return rawPrice / 100;
  }

  Future<void> _handlePay() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      if (_paymentMethodId == 0) {
        final paymentMethods = await request.v2board.getPaymentMethod();
        final methods = paymentMethods['data'] as List<dynamic>? ?? [];
        if (methods.isEmpty) {
          throw Exception('暂无可用的支付方式');
        }
        _paymentMethodId = methods.first['id'] ?? 7;
      }

      final period = _isOneTimePlan ? 'onetime_price' : _selectedPeriod;

      final createResult = await request.v2board.createOrder(
        planId: widget.plan['id'],
        period: period,
      );

      if (createResult['status'] != 'success') {
        throw Exception(createResult['message'] ?? '创建订单失败');
      }

      final tradeNo = createResult['data'];

      print(
        '[Purchase] createOrder success, tradeNo: $tradeNo, paymentMethodId: $_paymentMethodId',
      );

      final payUrl = await request.v2board.checkoutOrder(
        tradeNo: tradeNo,
        method: _paymentMethodId,
      );

      print('[Purchase] checkoutOrder result: $payUrl');

      if (payUrl == null) {
        throw Exception('获取支付链接失败，服务器返回的数据格式不正确');
      }

      Navigator.pop(context);
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentWebView(url: payUrl, onPaymentComplete: () {}),
        ),
      );
    } catch (e) {
      print('[Purchase] error: $e');
      String errorMsg = e.toString();
      if (e is DioException && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          errorMsg = data['message'];
        }
      }
      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('支付失败'),
            content: Text(errorMsg),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('确认购买 ${widget.plan["name"]}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('套餐: ${widget.plan["name"]}'),
            const SizedBox(height: 4),
            Text('流量: ${widget.plan["transfer_enable"]} GB'),
            const SizedBox(height: 16),
            if (_isOneTimePlan) ...[
              Text('一次性购买', style: Theme.of(context).textTheme.bodyMedium),
            ] else ...[
              const Text('选择周期:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPeriodChip(
                    '月付',
                    'month_price',
                    _getPeriodPrice('month_price'),
                  ),
                  _buildPeriodChip(
                    '季付',
                    'quarter_price',
                    _getPeriodPrice('quarter_price'),
                  ),
                  _buildPeriodChip(
                    '半年',
                    'half_year_price',
                    _getPeriodPrice('half_year_price'),
                  ),
                  _buildPeriodChip(
                    '年付',
                    'year_price',
                    _getPeriodPrice('year_price'),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text(
              '应付: ¥${_currentPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handlePay,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('立即支付'),
        ),
      ],
    );
  }

  Widget _buildPeriodChip(String label, String period, double price) {
    final isSelected = _selectedPeriod == period;
    final isAvailable = price > 0;

    return ChoiceChip(
      label: Text('$label ¥${price.toStringAsFixed(2)}'),
      selected: isSelected,
      onSelected: isAvailable
          ? (selected) {
              if (selected) {
                setState(() => _selectedPeriod = period);
              }
            }
          : null,
    );
  }
}
