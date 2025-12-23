import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

import '../models/chat_message.dart';
import '../models/live_location.dart';
import '../models/user_profile.dart';
import 'auth_service.dart';

class SocialService {
  SocialService._();
  static final SocialService instance = SocialService._();

  final _db = FirebaseFirestore.instance;

  // ----- Users -----

  Future<UserProfile> ensureUserProfile() async {
    final user = await AuthService.instance.ensureSignedIn();
    final doc = _db.collection('users').doc(user.uid);

    final snap = await doc.get();
    if (snap.exists) {
      return UserProfile.fromJson(snap.data()!);
    }

    final profile = UserProfile(
      id: user.uid,
      displayName: 'TrailMthr ${user.uid.substring(0, 5)}',
      isSharingLocation: false,
    );

    await doc.set(profile.toJson());
    return profile;
  }

  Stream<List<UserProfile>> watchFriends() {
    return _db
        .collection('users')
        .snapshots()
        .map((snap) => snap.docs.map((d) => UserProfile.fromJson(d.data())).toList());
  }

  Future<void> setSharing(bool isSharing) async {
    final user = await AuthService.instance.ensureSignedIn();
    await _db.collection('users').doc(user.uid).update({
      'isSharingLocation': isSharing,
    });
  }

  // ----- Live locations -----

  Future<void> updateLiveLocation(LatLng position) async {
    final user = await AuthService.instance.ensureSignedIn();
    await _db.collection('live_locations').doc(user.uid).set(
          LiveLocation(
            userId: user.uid,
            position: position,
            updatedAt: DateTime.now(),
          ).toJson(),
        );
  }

  Stream<List<LiveLocation>> watchLiveLocations() {
    return _db
        .collection('live_locations')
        .snapshots()
        .map((snap) => snap.docs.map((d) => LiveLocation.fromJson(d.data())).toList());
  }

  // ----- Messaging -----

  Stream<List<ChatMessage>> watchChatWith(String friendId) {
    final currentId = AuthService.instance.currentUserId;
    if (currentId == null) {
      return const Stream.empty();
    }

    return _db
        .collection('messages')
        .where('participants', arrayContains: currentId)
        .orderBy('sentAt', descending: true)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => ChatMessage.fromJson(d.data()))
          .where((m) =>
              (m.fromUserId == currentId && m.toUserId == friendId) ||
              (m.fromUserId == friendId && m.toUserId == currentId))
          .toList();
    });
  }

  Future<void> sendMessage(String toUserId, String text) async {
    final user = await AuthService.instance.ensureSignedIn();
    final msg = ChatMessage(
      id: _db.collection('messages').doc().id,
      fromUserId: user.uid,
      toUserId: toUserId,
      text: text,
      sentAt: DateTime.now(),
    );

    await _db.collection('messages').doc(msg.id).set({
      ...msg.toJson(),
      'participants': [msg.fromUserId, msg.toUserId],
    });
  }
}
