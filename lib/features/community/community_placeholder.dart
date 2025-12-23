import 'package:flutter/material.dart';

class CommunityPlaceholderScreen extends StatelessWidget {
  const CommunityPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Community coming soon...',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
