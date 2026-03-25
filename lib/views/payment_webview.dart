import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class PaymentWebView extends StatefulWidget {
  final String url;
  final VoidCallback? onPaymentComplete;
  final VoidCallback? onPaymentCancel;

  const PaymentWebView({
    super.key,
    required this.url,
    this.onPaymentComplete,
    this.onPaymentCancel,
  });

  @override
  State<PaymentWebView> createState() => _PaymentWebViewState();
}

class _PaymentWebViewState extends State<PaymentWebView> {
  late InAppWebViewController _controller;
  bool _isLoading = true;
  double _loadProgress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('支付'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            _showExitDialog();
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: LinearProgressIndicator(
            value: _loadProgress,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(widget.url)),
            initialSettings: InAppWebViewSettings(
              javaScriptEnabled: true,
              supportZoom: true,
              useShouldOverrideUrlLoading: true,
            ),
            onWebViewCreated: (controller) {
              _controller = controller;
            },
            onLoadStart: (controller, url) {
              setState(() {
                _isLoading = true;
                _loadProgress = 0;
              });
            },
            onLoadStop: (controller, url) {
              setState(() {
                _isLoading = false;
                _loadProgress = 1;
              });
              if (url != null) {
                _checkPaymentCallback(url.toString());
              }
            },
            onProgressChanged: (controller, progress) {
              setState(() {
                _loadProgress = progress / 100;
              });
            },
            shouldOverrideUrlLoading: (controller, navigationAction) async {
              final url = navigationAction.request.url?.toString() ?? '';
              if (url.contains('cloud.lanpanyun.top/order') ||
                  url.contains('return_url')) {
                return NavigationActionPolicy.ALLOW;
              }
              return NavigationActionPolicy.ALLOW;
            },
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _checkPaymentCallback(String url) {
    if (url.contains('cloud.lanpanyun.top/order') && url.contains('return')) {
      widget.onPaymentComplete?.call();
      Navigator.pop(context);
    }
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认离开'),
        content: const Text('支付尚未完成，确定要离开吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('继续支付'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              widget.onPaymentCancel?.call();
              Navigator.pop(context);
            },
            child: const Text('确认离开'),
          ),
        ],
      ),
    );
  }
}
