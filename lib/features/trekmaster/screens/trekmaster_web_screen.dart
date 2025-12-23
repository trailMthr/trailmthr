import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TrekMasterWebScreen extends StatefulWidget {
  const TrekMasterWebScreen({super.key});

  @override
  State<TrekMasterWebScreen> createState() => _TrekMasterWebScreenState();
}

class _TrekMasterWebScreenState extends State<TrekMasterWebScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      //..loadRequest(
        //Uri.parse("https://trekmaster.trailmthr.com"), // ✅ change later if needed
        ..loadRequest(Uri.parse("https://openai.com")

      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TrekMaster"),
      ),
      body: WebViewWidget(
        controller: _controller,
      ),
    );
  }
}
