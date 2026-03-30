import 'package:dio/dio.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/providers/v2board_provider.dart';

String _parseErrorMessage(dynamic error) {
  if (error is DioException) {
    final response = error.response;
    if (response?.data is Map) {
      return response!.data['message'] ?? response.data['error'] ?? '请求失败';
    }
    return error.message ?? '网络错误';
  }
  if (error is Function) {
    return '操作失败';
  }
  return error.toString();
}

class TicketListView extends ConsumerWidget {
  const TicketListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommonScaffold(
      title: '工单列表',
      body: TicketListBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => CreateTicketDialog(ref: ref),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TicketListBody extends ConsumerWidget {
  const TicketListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(ticketListProvider);

    return ticketsAsync.when(
      data: (tickets) {
        if (tickets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  '暂无工单',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '点击右下角 + 创建新工单',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(ticketListProvider);
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tickets.length,
            itemBuilder: (context, index) {
              final ticket = tickets[index];
              return _TicketCard(ticket: ticket);
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
            Text('获取工单失败: $err'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(ticketListProvider),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TicketCard extends ConsumerWidget {
  final Map<String, dynamic> ticket;

  const _TicketCard({required this.ticket});

  String _getLevelText(int level) {
    switch (level) {
      case 0:
        return '低';
      case 1:
        return '中';
      case 2:
        return '高';
      default:
        return '未知';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '待回复';
      case 1:
        return '已关闭';
      default:
        return '未知';
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getReplyStatusText(int replyStatus) {
    switch (replyStatus) {
      case 0:
        return '待回复';
      case 1:
        return '已回复';
      default:
        return '未知';
    }
  }

  Color _getReplyStatusColor(int replyStatus) {
    switch (replyStatus) {
      case 0:
        return Colors.orange;
      case 1:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = ticket['id'] as int? ?? 0;
    final level = ticket['level'] as int? ?? 0;
    final status = ticket['status'] as int? ?? 0;
    final replyStatus = ticket['reply_status'] as int? ?? 0;
    final subject = ticket['subject'] as String? ?? '';
    final createdAt = ticket['created_at'] as int? ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TicketDetailView(ticket: ticket),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      subject,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getLevelColor(level).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getLevelText(level),
                      style: TextStyle(
                        color: _getLevelColor(level),
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
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getReplyStatusColor(replyStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getReplyStatusText(replyStatus),
                      style: TextStyle(
                        color: _getReplyStatusColor(replyStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CreateTicketDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const CreateTicketDialog({super.key, required this.ref});

  @override
  ConsumerState<CreateTicketDialog> createState() => _CreateTicketDialogState();
}

class _CreateTicketDialogState extends ConsumerState<CreateTicketDialog> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  int _level = 0;
  bool _isLoading = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty) {
      _showMessage('请输入工单标题');
      return;
    }

    if (message.isEmpty) {
      _showMessage('请输入工单内容');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await request.v2board.createTicket(
        subject: subject,
        level: _level,
        message: message,
      );

      if (result is Map) {
        final status = result['status'];

        if (status == 'success') {
          if (mounted) {
            widget.ref.invalidate(ticketListProvider);
            Navigator.pop(context);
            _showMessage('工单创建成功');
          }
        } else {
          final msg = result['message'] ?? '创建失败';
          _showMessage(msg);
        }
      } else {
        _showMessage('响应格式错误');
      }
    } on DioException catch (e) {
      final errorMsg = _parseErrorMessage(e);
      _showMessage('创建失败: $errorMsg');
    } catch (e) {
      _showMessage('创建失败: $_parseErrorMessage(e)');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建工单'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '请输入工单标题',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _level,
              decoration: const InputDecoration(
                labelText: '优先级',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('低')),
                DropdownMenuItem(value: 1, child: Text('中')),
                DropdownMenuItem(value: 2, child: Text('高')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _level = value);
                }
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 120,
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: '内容',
                  hintText: '请输入工单内容',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                textAlignVertical: TextAlignVertical.top,
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
          onPressed: _isLoading
              ? null
              : () {
                  _submit();
                },
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('提交'),
        ),
      ],
    );
  }
}

class TicketDetailView extends ConsumerStatefulWidget {
  final Map<String, dynamic> ticket;

  const TicketDetailView({super.key, required this.ticket});

  @override
  ConsumerState<TicketDetailView> createState() => _TicketDetailViewState();
}

class _TicketDetailViewState extends ConsumerState<TicketDetailView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;
  bool _isFetching = true;
  String? _error;
  Map<String, dynamic>? _ticketDetail;
  List<dynamic> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchTicketDetail();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTicketDetail() async {
    final ticketId = widget.ticket['id'] as int? ?? 0;
    if (ticketId == 0) {
      setState(() {
        _isFetching = false;
        _error = '工单ID无效';
      });
      return;
    }

    try {
      final result = await request.v2board.getTicketDetail(ticketId);
      if (result['status'] == 'success') {
        final data = result['data'] as Map<String, dynamic>?;
        final messages = data?['message'] as List<dynamic>? ?? [];
        setState(() {
          _ticketDetail = data;
          _messages = messages;
          _isFetching = false;
          _error = null;
        });
      } else {
        setState(() {
          _isFetching = false;
          _error = result['message'] ?? '获取详情失败';
        });
      }
    } catch (e) {
      setState(() {
        _isFetching = false;
        _error = '获取详情失败: $e';
      });
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _isFetching = true;
      _error = null;
    });
    await _fetchTicketDetail();
  }

  Future<void> _reply() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      _showMessage('请输入回复内容');
      return;
    }

    final ticketId = widget.ticket['id'] as int? ?? 0;
    if (ticketId == 0) {
      _showMessage('工单ID无效');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await request.v2board.replyTicket(
        id: ticketId,
        message: message,
      );

      if (result['status'] == 'success') {
        if (mounted) {
          _messageController.clear();
          ref.invalidate(ticketListProvider);
          _showMessage('回复成功');
          _refresh();
        }
      } else {
        _showMessage(result['message'] ?? '回复失败');
      }
    } on DioException catch (e) {
      _showMessage('回复失败: $_parseErrorMessage(e)');
    } catch (e) {
      _showMessage('回复失败: $_parseErrorMessage(e)');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _closeTicket() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认关闭'),
        content: const Text('确定要关闭这个工单吗？'),
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

    if (confirmed != true) return;

    final ticketId = widget.ticket['id'] as int? ?? 0;
    if (ticketId == 0) {
      _showMessage('工单ID无效');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await request.v2board.closeTicket(id: ticketId);

      if (result['status'] == 'success') {
        if (mounted) {
          Navigator.pop(context);
          ref.invalidate(ticketListProvider);
          _showMessage('工单已关闭');
        }
      } else {
        _showMessage(result['message'] ?? '关闭失败');
      }
    } on DioException catch (e) {
      _showMessage('关闭失败: $_parseErrorMessage(e)');
    } catch (e) {
      _showMessage('关闭失败: $_parseErrorMessage(e)');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showReplyDialog() {
    _messageController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('回复工单'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.4,
          ),
          child: TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              labelText: '回复内容',
              hintText: '请输入回复内容',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () {
                    Navigator.pop(context);
                    _reply();
                  },
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('发送'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0:
        return '待回复';
      case 1:
        return '已关闭';
      default:
        return '未知';
    }
  }

  String _getLevelText(int level) {
    switch (level) {
      case 0:
        return '低';
      case 1:
        return '中';
      case 2:
        return '高';
      default:
        return '未知';
    }
  }

  Color _getLevelColor(int level) {
    switch (level) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ticketId = widget.ticket['id'] as int? ?? 0;
    final level =
        _ticketDetail?['level'] as int? ?? widget.ticket['level'] as int? ?? 0;
    final status =
        _ticketDetail?['status'] as int? ??
        widget.ticket['status'] as int? ??
        0;
    final subject =
        _ticketDetail?['subject'] as String? ??
        widget.ticket['subject'] as String? ??
        '';
    final createdAt =
        _ticketDetail?['created_at'] as int? ??
        widget.ticket['created_at'] as int? ??
        0;

    return BaseScaffold(
      title: '工单详情',
      body: Column(
        children: [
          Expanded(
            child: _isFetching
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(_error!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          subject,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _getLevelColor(
                                            level,
                                          ).withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _getLevelText(level),
                                          style: TextStyle(
                                            color: _getLevelColor(level),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 0
                                              ? Colors.orange.withAlpha(25)
                                              : Colors.grey.withAlpha(25),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          _getStatusText(status),
                                          style: TextStyle(
                                            color: status == 0
                                                ? Colors.orange
                                                : Colors.grey,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '工单ID: $ticketId | 创建: ${_formatTime(createdAt)}',
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
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '对话记录',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          if (_messages.isEmpty)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(32),
                                child: Text(
                                  '暂无对话记录',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            )
                          else
                            ..._messages.map((msg) {
                              final isMe = msg['is_me'] == true;
                              final content = msg['message'] as String? ?? '';
                              final time = msg['created_at'] as int? ?? 0;
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width *
                                        0.75,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer
                                        : Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(
                                        isMe ? 16 : 4,
                                      ),
                                      bottomRight: Radius.circular(
                                        isMe ? 4 : 16,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isMe ? '我' : '客服',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(content),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(time),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
          ),
          if (status == 0)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _closeTicket,
                        child: const Text('关闭工单'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _showReplyDialog,
                        child: const Text('回复'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
