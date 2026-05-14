import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LinkScreen extends StatefulWidget {
  final String url;

  LinkScreen({required this.url});

  @override
  _LinkScreenState createState() => _LinkScreenState();
}

class _LinkScreenState extends State<LinkScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            // Check if Junction redirects to a success or cancel schema
            if (request.url.contains('success') || request.url.contains('vital-link://success')) {
              Navigator.pop(context, true);
              return NavigationDecision.prevent;
            }
            if (request.url.contains('cancel') || request.url.contains('vital-link://close')) {
              Navigator.pop(context, false);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect Wearable')),
      body: WebViewWidget(controller: _controller),
    );
  }
}
