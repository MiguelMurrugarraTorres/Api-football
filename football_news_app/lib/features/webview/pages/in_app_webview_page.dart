// lib/features/webview/pages/in_app_webview_page.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:football_news_app/features/home/widgets/bottom_navigation_widget.dart';

class InAppWebViewPage extends StatefulWidget {
  final Uri uri;
  final String? title;

  const InAppWebViewPage({
    Key? key,
    required this.uri,
    this.title,
  }) : super(key: key);

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  late final WebViewController _controller;
  bool _canGoBack = false;
  bool _isLoading = true;

  // ✅ Requeridos por tu BottomNavigationWidget
  int _selectedIndexBottom = 0;
  void _onBottomItemTapped(int i) {
    setState(() => _selectedIndexBottom = i);
  }

  @override
  void initState() {
    super.initState();

    final params = const PlatformWebViewControllerCreationParams();

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
          },
          onPageFinished: (_) async {
            final canBack = await _controller.canGoBack();
            if (!mounted) return;
            setState(() {
              _canGoBack = canBack;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(widget.uri);
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false; // navegar atrás dentro del WebView
    }
    return true; // cerrar la página
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? widget.uri.host;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: Icon(_canGoBack ? Icons.arrow_back : Icons.close),
            onPressed: () async {
              if (await _controller.canGoBack()) {
                await _controller.goBack();
              } else {
                if (mounted) Navigator.of(context).maybePop();
              }
            },
          ),
        ),
        body: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading) const LinearProgressIndicator(minHeight: 2),
          ],
        ),
        // ⬇️ Sin const y pasando los argumentos requeridos
        bottomNavigationBar: BottomNavigationWidget(
          selectedIndex: _selectedIndexBottom,
          onItemTapped: _onBottomItemTapped,
        ),
      ),
    );
  }
}
