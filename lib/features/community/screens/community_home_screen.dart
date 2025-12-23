import 'package:flutter/material.dart';

class CommunityHomeScreen extends StatelessWidget {
  const CommunityHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Community")),
      body: const Center(
        child: Text(
          "Community Screen Loaded",
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
