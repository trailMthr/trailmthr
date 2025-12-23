class UserProfile {
  final String id;
  final String displayName;
  final bool isSharingLocation;

  UserProfile({
    required this.id,
    required this.displayName,
    required this.isSharingLocation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'isSharingLocation': isSharingLocation,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String? ?? 'TrailMthr user',
        isSharingLocation: json['isSharingLocation'] as bool? ?? false,
      );
}
