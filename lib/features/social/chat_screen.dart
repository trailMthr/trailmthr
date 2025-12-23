import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/chat_message.dart';
import '../../services/social_service.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile friend;

  const ChatScreen({super.key, required this.friend});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.friend.displayName),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: SocialService.instance.watchChatWith(widget.friend.id),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(child: Text("Say hi 👋"));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (_, i) {
                    final m = messages[i];
                    final isMe = false; // optional: compare to current user id

                    return Align(
                      alignment:
                          isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isMe ? Colors.blueAccent : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          m.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      hintText: "Message...",
                    ),
                  ),
                ),
                IconButton(
                  icon: _sending
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                  onPressed: _sending
                      ? null
                      : () async {
                          final text = _controller.text.trim();
                          if (text.isEmpty) return;

                          setState(() => _sending = true);
                          await SocialService.instance
                              .sendMessage(widget.friend.id, text);
                          _controller.clear();
                          setState(() => _sending = false);
                        },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
