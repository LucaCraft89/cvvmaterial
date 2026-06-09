import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../providers/auth_provider.dart';

class WebViewScreen extends ConsumerStatefulWidget {
  final String url;
  final String title;
  /// When true, obtains a ClasseViva web-session ticket before loading [url].
  final bool useWebAuth;
  final Map<String, String> headers;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    this.useWebAuth = false,
    this.headers = const {},
  });

  @override
  ConsumerState<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends ConsumerState<WebViewScreen> {
  WebViewController? _ctrl;
  int _progress = 0;
  bool _initializing = true;
  static const _restBridge =
      'https://web.spaggiari.eu/repx/app/default/restbridge.php';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ctrl = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onProgress: (p) {
          if (mounted) setState(() => _progress = p);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _progress = 100);
        },
      ));

    if (widget.useWebAuth) {
      final client = ref.read(clientProvider);
      final token = await client.getWebTicket();
      if (token != null) {
        final bridgeUrl = '$_restBridge'
            '?t=${Uri.encodeQueryComponent(token)}'
            '&u=${Uri.encodeQueryComponent(widget.url)}'
            '&f=';
        await ctrl.loadRequest(Uri.parse(bridgeUrl));
      } else {
        await ctrl.loadRequest(Uri.parse(widget.url), headers: widget.headers);
      }
    } else {
      await ctrl.loadRequest(Uri.parse(widget.url), headers: widget.headers);
    }

    if (mounted) {
      setState(() {
        _ctrl = ctrl;
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _ctrl?.reload(),
          ),
        ],
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: _initializing || _ctrl == null
          ? const Center(child: CircularProgressIndicator())
          : WebViewWidget(controller: _ctrl!),
    );
  }
}
