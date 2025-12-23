import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../services/social_service.dart';
import 'chat_screen.dart';

class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          height: 56,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: const [
              BoxShadow(
                blurRadius: 4,
                offset: Offset(0, 2),
                color: Colors.black12,
              ),
            ],
          ),
          child: const Text(
            "Friends & Live Sharing",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),

        Expanded(
          child: StreamBuilder<List<UserProfile>>(
            stream: SocialService.instance.watchFriends(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data!;
              if (users.isEmpty) {
                return const Center(
                  child: Text("No friends yet. Share your app with someone!"),
                );
              }

              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (_, i) {
                  final u = users[i];

                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(u.displayName.isNotEmpty
                          ? u.displayName[0].toUpperCase()
                          : "?"),
                    ),
                    title: Text(u.displayName),
                    subtitle: Text(
                      u.isSharingLocation
                          ? "Live location: ON"
                          : "Live location: OFF",
                    ),
                    trailing: Icon(
                      u.isSharingLocation
                          ? Icons.location_pin
                          : Icons.location_off,
                      color: u.isSharingLocation ? Colors.green : Colors.grey,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(friend: u),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
